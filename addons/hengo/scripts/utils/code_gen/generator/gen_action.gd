class_name HenGeneratorAction extends RefCounted

# emits a state's linear action list into its lifecycle methods (enter/update/exit).
# an action is an instance of a macro-script definition (HenScriptMacroBase),
# run playmaker-style; decoupled from cnode/virtualcnode codegen.


# the uses of a macro being generated, innermost last. a macro is written once per
# use, so this is what tells the steps inside it which one they belong to
static var macro_uses: Array[HenSaveState] = []


static func push_macro_use(_use: HenSaveState) -> void:
	macro_uses.append(_use)


static func pop_macro_use() -> void:
	macro_uses.resize(maxi(0, macro_uses.size() - 1))


static func current_macro_use() -> HenSaveState:
	return macro_uses.back() if not macro_uses.is_empty() else null


# true when this use runs a macro already being written, which would unfold the
# same machine forever
static func macro_use_loops(_use: HenSaveState) -> bool:
	for entry: HenSaveState in macro_uses:
		if entry != _use and str(entry.macro_id) == str(_use.macro_id):
			return true

	return false


# the scopes whose hooks are being gathered, so a function that reaches itself is
# asked once and not once per level
static var _hook_scopes: Dictionary = {}


static func clear_hook_scopes() -> void:
	_hook_scopes.clear()


# a function body is written at script scope, where the node is `self`: `_ref` is
# the field a state class holds and does not exist there
static var in_function: bool = false


# for a line written by hand instead of by a macro body, which never reaches the
# `_ref` -> `self` pass of _process_body
static func owner_ref() -> String:
	return 'self' if in_function else '_ref'


# names an action emits are keyed by its id, which two uses of one macro share:
# the use is what makes them different
static func _process_body(_body: String, _action_id: StringName) -> String:
	var use: HenSaveState = current_macro_use()
	var suffix: String = ''

	for entry: HenSaveState in macro_uses:
		suffix += '_' + str(entry.id)

	var body: String = HenActionCode.process_script_macro_body(_body, in_function, str(_action_id) + suffix)

	return body.replace('{{MACRO_ID}}', str(use.id) if use else '')


# a function is a flat list run where it is called, so nothing is filtered by
# phase: every step of its body runs, in the order it is written
static func get_function_tokens(_save_data: HenSaveData, _scope: HenSaveState) -> Array:
	in_function = true

	var tokens: Array = _emit_actions(_save_data, _scope, _save_data.get_state_actions(_scope.id), &'', 0, false)

	in_function = false

	return tokens


# tokens for the actions assigned to one lifecycle phase of a state
static func get_state_action_tokens(_save_data: HenSaveData, _state: HenSaveState, _phase: StringName) -> Array:
	return _emit_actions(_save_data, _state, _save_data.get_state_actions(_state.id), _phase, 0, true)


# lines for a list of actions run at one phase. the top level is the state's list,
# filtered by phase; a loop passes its body_actions with _filter off (they run
# when the loop runs) and depth+1 so break/continue know they are inside a loop.
# an empty phase runs every step at the one it was stored with, which is what a
# function body does: it has no lifecycle of its own
static func _emit_actions(_save_data: HenSaveData, _state: HenSaveState, _actions: Array, _phase: StringName, _loop_depth: int, _filter_phase: bool) -> Array:
	var tokens: Array = []
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var debug: bool = global.SETTINGS.debug_compilation

	for action: HenSaveAction in _actions:
		if _filter_phase and str(action.phase) != str(_phase):
			continue

		# a muted step keeps its values and emits nothing, the way a breakpoint does
		if action.disabled:
			continue

		var macro: HenSaveMacro = _resolve_macro(action.macro_id, _save_data)

		if _macro_is_missing(macro):
			tokens.append(_unresolved_token(action, 'macro not found'))
			continue

		var instance: HenScriptMacroBase = _load_instance(macro, _save_data)

		if not instance:
			tokens.append(_unresolved_token(action, 'could not instance macro'))
			continue

		var phase: StringName = _phase if not _phase.is_empty() else StringName(str(action.phase))

		_prime_instance(_save_data, instance, action, phase, _loop_depth)

		var reason: String = skip_reason(_save_data, _state, action, instance, phase, _loop_depth)

		if not reason.is_empty():
			tokens.append(_unresolved_token(action, reason))
			continue

		# a nested action emits at the LOOP's phase, never its own stored phase
		var body: String = _get_phase_body(instance, phase)
		var branches: Array = instance.get_flow_outputs()

		# outputs before inputs: the output rhs still holds {{input}} placeholders the
		# next sweep resolves. then branch transitions, then {{VCNODE_ID}} / _ref
		body = _substitute_outputs(_save_data, body, action, instance)

		# an action that still does something when nobody stores its value says so,
		# instead of vanishing the way a pure producer does
		if body.strip_edges().is_empty():
			body = instance.get_unstored_body()

		body = _substitute_inputs(_save_data, body, action, instance)
		body = _substitute_branches(_save_data, body, action, branches, _state, phase, _loop_depth)
		body = _process_body(body, action.id)

		# the nested body goes in LAST, after this action's own {{VCNODE_ID}} pass:
		# its lines are already resolved and must not be run through it again
		if instance.get_has_body():
			body = _substitute_loop_body(_save_data, _state, body, action, phase, _loop_depth)

		if instance is HenMacroHookMacro:
			body = _substitute_macro_hook(_save_data, body, instance as HenMacroHookMacro, phase, _loop_depth)

		var emitted: String = body.strip_edges(false, true)

		# a producer read only through a wire emits its value at the reader, so its own
		# body is empty and must not leave a blank line behind
		if emitted.is_empty():
			continue

		# lights the action's row when execution reaches it, gone in release builds
		if debug:
			tokens.append(_action_trace(_save_data, action))

		for line: String in emitted.split('\n'):
			tokens.append(line)

	return tokens


# gated per script: action ids only count up inside one script
static func _action_trace(_save_data: HenSaveData, _action: HenSaveAction) -> String:
	var script_id: String = str(_save_data.identity.id)

	return 'if ' + owner_ref() + '.get_instance_id() == HengoDebugger.state_targets.get("' + script_id \
		+ '", -1): HengoDebugger.trace_action(&"' + str(_action.id) + '", "' + script_id + '")'


# injects the loop's nested action lines at {{loop_body}}, one indent level deeper.
# an empty body (or one that is all markers/comments) becomes `pass` so the `for`
# is never left without a statement
static func _substitute_loop_body(_save_data: HenSaveData, _state: HenSaveState, _body: String, _action: HenSaveAction, _phase: StringName, _loop_depth: int) -> String:
	var nested: Array = _emit_actions(_save_data, _state, _action.body_actions, _phase, _loop_depth + 1, false)
	var has_statement: bool = false

	for line: Variant in nested:
		var text: String = str(line).strip_edges()
		if not text.is_empty() and not text.begins_with('#'):
			has_statement = true
			break

	if not has_statement:
		nested.append('pass')

	return HenActionCode._inject_placeholder(_body, 'loop_body', '\n'.join(nested))


# what the use of a macro put on this place. the use is the state being written,
# so its list is read the way any other state's is
static func _substitute_macro_hook(_save_data: HenSaveData, _body: String, _instance: HenMacroHookMacro, _phase: StringName, _loop_depth: int) -> String:
	var use: HenSaveState = current_macro_use()
	var steps: Array = []

	if use:
		steps = _emit_actions(
			_save_data,
			use,
			hook_steps(_save_data, use, StringName(str(_instance.hook.id))),
			_phase,
			_loop_depth,
			false
		)

	if steps.is_empty():
		steps = ['pass']

	return HenActionCode._inject_placeholder(_body, 'macro_hook', '
'.join(steps))


# true when the step rides a named place of a macro instead of a lifecycle phase
static func _is_hook_step(_save_data: HenSaveData, _state: HenSaveState, _action: HenSaveAction) -> bool:
	if not _state.is_macro_use():
		return false

	return not HenSaveAction.PHASE_ORDER.has(StringName(str(_action.phase)))


# the phase a place of a macro runs at, which is the phase of the step that runs
# it. what a use puts there is collected at that phase, not at the name of the
# place, or the collectors would call it a step with no body
static func hook_phase(_save_data: HenSaveData, _use: HenSaveState, _hook: StringName) -> StringName:
	var macro: HenSaveStateMacro = _use.get_macro(_save_data)

	if not macro:
		return &'update'

	var wanted: StringName = HenMacroHookMacro.hook_id(macro, macro.find_flow_input(_hook)) if macro.find_flow_input(_hook) else &''

	for state: HenSaveState in _macro_states(_save_data, macro):
		var found: StringName = _phase_of_macro_in(_save_data.get_state_actions(state.id), wanted)

		if not found.is_empty():
			return found

	return &'update'


static func _macro_states(_save_data: HenSaveData, _macro: HenSaveStateMacro) -> Array:
	var out: Array = []

	for state: HenSaveState in _macro.get_states(_save_data):
		out.append(state)
		out.append_array(_descendants(_save_data, state))

	return out


static func _descendants(_save_data: HenSaveData, _state: HenSaveState) -> Array:
	var out: Array = []

	if _state.is_macro_use():
		return out

	for sub: HenSaveState in _state.get_sub_states(_save_data):
		out.append(sub)
		out.append_array(_descendants(_save_data, sub))

	return out


static func _phase_of_macro_in(_actions: Array, _macro_id: StringName) -> StringName:
	for action: HenSaveAction in _actions:
		if StringName(str(action.macro_id)) == _macro_id:
			return StringName(str(action.phase))

		for list: Array in nested_lists(action):
			var found: StringName = _phase_of_macro_in(list, _macro_id)

			if not found.is_empty():
				return found

	return &''


# the phase a step of this state is collected at: a step a use put on a place of
# its macro runs where that place runs
static func collect_phase(_save_data: HenSaveData, _state: HenSaveState, _action: HenSaveAction) -> StringName:
	var phase: StringName = StringName(str(_action.phase))

	if not _state.is_macro_use() or HenSaveAction.PHASE_ORDER.has(phase):
		return phase

	return hook_phase(_save_data, _state, phase)


# the steps a use put on one named place of its macro. they ride the action list
# of the use, keyed by the place instead of by a lifecycle phase
static func hook_steps(_save_data: HenSaveData, _use: HenSaveState, _hook: StringName) -> Array:
	var steps: Array = []

	for action: HenSaveAction in _save_data.get_state_actions(_use.id):
		if StringName(str(action.phase)) == _hook:
			steps.append(action)

	return steps


# why an action cannot be emitted, empty when it is fine. every emission path
# asks this, so a skipped action never leaves half of itself behind — the phase
# body is dropped but its script base, its connect and its disconnect are not.
# _phase/_loop_depth default so the hook callers (script base, reset, teardown)
# need no change; only the emit path passes them
static func skip_reason(_save_data: HenSaveData, _state: HenSaveState, _action: HenSaveAction, _instance: HenScriptMacroBase, _phase: StringName = &'', _loop_depth: int = 0) -> String:
	var invalid: String = _instance.get_validation_error()

	if not invalid.is_empty():
		return invalid

	var wrong_scope: String = _scope_error(_save_data, _state, _action, _instance)

	if not wrong_scope.is_empty():
		return wrong_scope

	# break/continue are only valid inside a loop body
	if _instance.get_needs_loop() and _loop_depth == 0:
		return str(_instance.get_display_name()).to_lower() + ' can only be used inside a loop'

	# a nested action runs at the loop's phase, not its own stored one
	var phase: StringName = _phase if not _phase.is_empty() else _action.phase

	if _get_phase_body(_instance, phase).is_empty():
		return 'has no ' + str(phase) + ' body'

	# an assignment target must be an identifier; a literal there emits `0 = 5`.
	# checked first so a required slot says what it needs instead of what broke
	var unbound_target: String = _first_unbound_required(_save_data, _action, _instance)

	if not unbound_target.is_empty():
		return 'input "' + unbound_target + '" must be bound to a variable or property'

	# a binding substitutes mid-expression, so a deleted variable takes the whole
	# action down instead of leaving a broken line behind
	var broken: String = _first_broken_binding(_save_data, _action)

	if not broken.is_empty():
		return broken + ' binds a variable that no longer exists'

	var broken_inline: String = _first_broken_inline(_save_data, _action)

	if not broken_inline.is_empty():
		return broken_inline

	var broken_wire: String = _first_broken_wire(_save_data, _action)

	if not broken_wire.is_empty():
		return broken_wire

	var out_of_scope: String = _first_out_of_scope_wire(_save_data, _state, _action)

	if not out_of_scope.is_empty():
		return out_of_scope

	var branches: Array = _instance.get_flow_outputs()

	# a pure producer whose only content is its outputs contributes nothing when
	# none is stored: the phase method would be left empty and fail to parse
	if not _branch_is_wired(_save_data, _action, branches):
		if _produces_nothing(_save_data, _action, _instance, phase) and not is_wire_source(_save_data, _action):
			return 'no output stored'

		if branches.is_empty() or _branches_are_optional(branches):
			return ''

	# change_state calls exit() before swapping current_state, so a transition
	# emitted from exit re-enters it forever. steps are not a transition, so a
	# branch that only runs them is still welcome there
	if str(phase) == 'exit' and _has_transition(_save_data, _action, branches):
		return 'a branching action cannot run on exit'

	# a branching action with nowhere to go would emit `if x: pass else: pass`.
	# an action whose branches are all optional still does its work without them
	if not _branch_is_wired(_save_data, _action, branches) and not _branches_are_optional(branches):
		return 'no branch target set'

	# a cross-script branch drives another node's machine — without the instance
	# there is nothing to call change_state on
	var unbound: String = _first_unbound_cross_branch(_save_data, _action, branches)

	if not unbound.is_empty():
		return 'branch "' + unbound + '": missing target instance connection'

	# a sub-state is only reachable from its own parent's branch: a sibling, a
	# child or the parent itself. anywhere else the state simply is not running
	var unreachable: String = _first_unreachable_branch(_save_data, _state, _action, branches)

	if not unreachable.is_empty():
		return 'branch "' + unreachable + '" points at a sub-state of another state'

	return ''


# a function body and a state body take different actions: a finish belongs to the
# function that declares it, and nothing inside a function changes state
static func _scope_error(_save_data: HenSaveData, _state: HenSaveState, _action: HenSaveAction, _instance: HenScriptMacroBase) -> String:
	var inside_function: bool = _state != null and _state.is_function_scope

	if _instance.get_needs_function() and not inside_function:
		return str(_instance.get_display_name()).to_lower() + ' can only be used inside a function'

	if _instance is HenFunctionMacro:
		var function_macro: HenFunctionMacro = _instance as HenFunctionMacro

		if function_macro.is_return and (not _state or str(_state.id) != str(function_macro.func_res.id)):
			return 'this finish belongs to another function'

	# a function has no machine of its own to change; driving ANOTHER node's machine
	# is a call like any other and stays allowed
	if inside_function:
		for out: Dictionary in _instance.get_flow_outputs():
			var key: String = str(out.get('id', ''))

			if branch_target(_save_data, _action, key) and branch_script_id(_save_data, _action, key).is_empty():
				return 'a function cannot change the state of its own script'

	return ''


static func _first_unreachable_branch(_save_data: HenSaveData, _state: HenSaveState, _action: HenSaveAction, _branches: Array) -> String:
	for out: Dictionary in _branches:
		var key: String = str(out.get('id', ''))
		var target: HenSaveState = branch_target(_save_data, _action, key)

		# cross-script branches always go through change_state on the other machine
		if not target or not branch_script_id(_save_data, _action, key).is_empty():
			continue

		var parent: HenSaveState = _parent_of(_save_data, target)

		if parent and ancestor_chain(_save_data, _state).find(parent) < 0:
			return str(out.get('name', key))

	return ''


# why the codegen would drop this action, empty when it is fine. the phase and the
# depth are the ones the emit path uses, never the action's stored phase
static func action_error(
	_save_data: HenSaveData,
	_state: HenSaveState,
	_action: HenSaveAction,
	_phase: StringName = &'',
	_loop_depth: int = 0
) -> String:
	if not _save_data or not _state or not _action or _action.disabled:
		return ''

	var macro: HenSaveMacro = _resolve_macro(_action.macro_id, _save_data)

	if _macro_is_missing(macro):
		return 'macro not found'

	var instance: HenScriptMacroBase = _load_instance(macro, _save_data)

	if not instance:
		return 'could not instance macro'

	var phase: StringName = _phase if not _phase.is_empty() else StringName(str(_action.phase))

	_prime_instance(_save_data, instance, _action, phase, _loop_depth)

	return skip_reason(_save_data, _state, _action, instance, phase, _loop_depth)


# every action of a script the codegen cannot emit. the graph and the error list
# read this, so a red card never disagrees with the generated file
static func collect_errors(_save_data: HenSaveData) -> Array[Dictionary]:
	var errors: Array[Dictionary] = []

	if not _save_data:
		return errors

	for state: HenSaveState in _all_states(_save_data):
		_collect_errors(_save_data, state, _save_data.get_state_actions(state.id), &'', 0, errors)

	for func_res: HenSaveFunc in _save_data.functions:
		var scope: HenSaveState = func_res.scope_state()

		_collect_errors(_save_data, scope, _save_data.get_state_actions(scope.id), &'', 0, errors)

	return errors


# a skipped action takes its body with it, the way the emit path does: a step that
# never runs cannot be broken
static func _collect_errors(
	_save_data: HenSaveData,
	_state: HenSaveState,
	_actions: Array,
	_phase: StringName,
	_depth: int,
	_out: Array[Dictionary]
) -> void:
	for action: HenSaveAction in _actions:
		if action.disabled:
			continue

		var phase: StringName = _phase if not _phase.is_empty() else collect_phase(_save_data, _state, action)
		var reason: String = action_error(_save_data, _state, action, phase, _depth)

		if not reason.is_empty():
			_out.append(_error_entry(_save_data, _state, action, reason))
			continue

		# a branch runs at the same depth the action does, only a body nests
		_collect_errors(_save_data, _state, action.body_actions, phase, _depth + 1, _out)

		for key: Variant in action.branch_actions:
			_collect_errors(_save_data, _state, branch_steps(action, str(key)), phase, _depth, _out)


static func _error_entry(
	_save_data: HenSaveData,
	_state: HenSaveState,
	_action: HenSaveAction,
	_reason: String
) -> Dictionary:
	var macro: HenSaveMacro = _resolve_macro(_action.macro_id, _save_data)
	var label: String = str(_action.label).strip_edges()
	var title: String = label if not label.is_empty() else (macro.name if macro else str(_action.name))

	return {
		script_id = StringName(str(_save_data.identity.id)) if _save_data.identity else &'',
		state_id = StringName(str(_state.id)),
		action_id = StringName(str(_action.id)),
		reason = _reason,
		description = _state.name + ' / ' + title + ': ' + _reason
	}


# every action of a state that actually gets emitted, in run order, the ones
# nested in a loop body included: a nested action declares at the same levels as
# a top level one, and {{VCNODE_ID}} keys the names by action id so nesting never
# makes two of them collide.
# a nested action is filtered at the phase its loop runs on, never its own stored
# one, the way the emit path treats it. a skipped action takes its whole body with
# it: declaring for a step that never runs would arm a listener nobody drives
static func emitted_actions(_save_data: HenSaveData, _state: HenSaveState) -> Array:
	var out: Array = []

	_collect_emitted(_save_data, _state, _save_data.get_state_actions(_state.id), &'', 0, out)

	return out


static func _collect_emitted(
	_save_data: HenSaveData,
	_state: HenSaveState,
	_actions: Array,
	_phase: StringName,
	_depth: int,
	_out: Array
) -> void:
	for action: HenSaveAction in _actions:
		# what a use puts on a place of its macro is collected where that place runs,
		# which is a state of the macro and not the use itself
		if _phase.is_empty() and _is_hook_step(_save_data, _state, action):
			continue

		var phase: StringName = _phase if not _phase.is_empty() else collect_phase(_save_data, _state, action)
		var instance: HenScriptMacroBase = _instance_for(_save_data, action, phase, _depth)

		if not instance or not skip_reason(_save_data, _state, action, instance, phase, _depth).is_empty():
			continue

		_out.append({action = action, instance = instance})

		# the step that runs a place declares for whatever the use put there
		if instance is HenMacroHookMacro and current_macro_use():
			_collect_emitted(
				_save_data,
				current_macro_use(),
				hook_steps(_save_data, current_macro_use(), StringName(str((instance as HenMacroHookMacro).hook.id))),
				phase,
				_depth,
				_out
			)

		_collect_emitted(_save_data, _state, action.body_actions, phase, _depth + 1, _out)

		for key: Variant in action.branch_actions:
			_collect_emitted(_save_data, _state, branch_steps(action, str(key)), phase, _depth, _out)


# class-level declarations the actions of a state need, from each macro's
# get_script_base(). emitted inside the state class, so an action can keep a
# counter across frames; {{VCNODE_ID}} makes the names unique per action
static func get_state_base_lines(_save_data: HenSaveData, _state: HenSaveState) -> Array:
	var lines: Array = []
	var was_in_function: bool = in_function

	in_function = _state.is_function_scope

	for entry: Dictionary in emitted_actions(_save_data, _state):
		var action: HenSaveAction = entry.action
		var instance: HenScriptMacroBase = entry.instance
		var base: String = instance.get_script_base()

		if base.is_empty():
			continue

		base = _process_body(base, action.id)

		# a blank line between blocks, or two actions run together on screen
		if not lines.is_empty():
			lines.append('')

		for line: String in base.strip_edges().split('\n'):
			lines.append(line)

	in_function = was_in_function

	return lines


# declarations an action needs at SCRIPT scope, from get_script_scope(). the state
# class cannot hold them when a virtual override has to read them — _input runs on
# the node, not on the state
static func get_script_scope_lines(_save_data: HenSaveData) -> Array:
	var lines: Array = []
	var was_in_function: bool = in_function

	for_each_scope(_save_data, func(state: HenSaveState) -> void:
		in_function = state.is_function_scope

		for entry: Dictionary in emitted_actions(_save_data, state):
			var action: HenSaveAction = entry.action
			var scope: String = (entry.instance as HenScriptMacroBase).get_script_scope()

			if scope.is_empty():
				continue

			scope = _process_body(scope, action.id)

			for line: String in scope.strip_edges().split('\n'):
				lines.append(line)
	)

	in_function = was_in_function

	return lines


# merges the virtual overrides the actions declare into the map gen_base emits.
# bodies are split line by line: a single multi-line token would only get the
# first line indented
static func merge_script_overrides(_save_data: HenSaveData, _override_data: Dictionary) -> void:
	for_each_scope(_save_data, func(state: HenSaveState) -> void:
		for entry: Dictionary in emitted_actions(_save_data, state):
			var action: HenSaveAction = entry.action

			for override: Dictionary in (entry.instance as HenScriptMacroBase).get_function_overrides():
				var func_name: String = str(override.get('name', ''))

				if func_name.is_empty():
					continue

				var body: Variant = override.get('body', '')

				if not body is String or (body as String).is_empty():
					continue

				if not _override_data.has(func_name):
					_override_data[func_name] = {
						params = override.get('params', []),
						tokens = []
					}

				var code: String = _process_body(body as String, action.id)

				for line: String in code.strip_edges(false, true).split('\n'):
					(_override_data[func_name].tokens as Array).append(line)
	)


# every state of the script, sub-states included
static func _all_states(_save_data: HenSaveData) -> Array:
	var states: Array = []
	states.append_array(_save_data.states)

	for sub_list: Variant in _save_data.sub_states.values():
		states.append_array(sub_list)

	return states


# every action list the script actually emits, walked the way the codegen writes
# it: entering a macro use, so a step inside one declares under the use it belongs
# to instead of once for the definition
static func for_each_scope(_save_data: HenSaveData, _visit: Callable) -> void:
	for state: HenSaveState in _save_data.states:
		_visit_scope(_save_data, state, _visit)

	for func_res: HenSaveFunc in _save_data.functions:
		_visit.call(func_res.scope_state())


static func _visit_scope(_save_data: HenSaveData, _state: HenSaveState, _visit: Callable) -> void:
	if _state.is_macro_use():
		# a macro that uses itself is written once: the inner use is a dead end
		if macro_use_loops(_state):
			return

		push_macro_use(_state)

		for inner: HenSaveState in _state.get_sub_states(_save_data):
			_visit_scope(_save_data, inner, _visit)

		pop_macro_use()
		return

	_visit.call(_state)

	for sub: HenSaveState in _state.get_sub_states(_save_data):
		_visit_scope(_save_data, sub, _visit)


# the hook lines of one scope, used both for a state and for the body of a
# function, whose own hooks become methods of the script
static func get_scope_hook_tokens(_save_data: HenSaveData, _scope: HenSaveState, _method: StringName) -> Array:
	var key: String = str(_scope.id) + ':' + str(_method)

	if _hook_scopes.has(key):
		return []

	_hook_scopes[key] = true

	var was_in_function: bool = in_function

	in_function = _scope.is_function_scope

	var tokens: Array = _get_hook_tokens(_save_data, _scope, _method)

	in_function = was_in_function
	_hook_scopes.erase(key)

	return tokens


# reset tokens run at the top of enter() whatever phase the action is on: zeroing
# a counter belongs to entering the state, not to the action's own body. state
# objects are built once, so without this a counter would survive re-entry
static func get_state_reset_tokens(_save_data: HenSaveData, _state: HenSaveState) -> Array:
	return _get_hook_tokens(_save_data, _state, &'get_flow_reset')


# the mirror of the reset: it runs in exit() so an action can undo what it armed,
# a signal connection above all
static func get_state_teardown_tokens(_save_data: HenSaveData, _state: HenSaveState) -> Array:
	return _get_hook_tokens(_save_data, _state, &'get_flow_teardown')


# lines of an optional lifecycle hook, gathered across the state's actions. goes
# through _substitute_inputs, so a hook body may hold {{input}} placeholders
static func _get_hook_tokens(_save_data: HenSaveData, _state: HenSaveState, _method: StringName) -> Array:
	var tokens: Array = []
	var asked: Dictionary = {}

	for entry: Dictionary in emitted_actions(_save_data, _state):
		var action: HenSaveAction = entry.action
		var instance: HenScriptMacroBase = entry.instance

		# what a function keeps lives at script scope, out of reach from here, so the
		# caller asks the function to do it instead of naming what it holds
		if instance is HenFunctionMacro and not (instance as HenFunctionMacro).is_return:
			var called: HenSaveFunc = (instance as HenFunctionMacro).func_res

			if asked.has(str(called.id)):
				continue

			asked[str(called.id)] = true

			if not get_scope_hook_tokens(_save_data, called.scope_state(), _method).is_empty():
				tokens.append(owner_ref() + '.' + HenGeneratorFunction.hook_method(_save_data, called, _method) + '()')

			continue

		if not instance.has_method(_method):
			continue

		var body: Variant = instance.call(_method)

		if not body is String or (body as String).is_empty():
			continue

		var code: String = _substitute_inputs(_save_data, body as String, action, instance)
		code = _process_body(code, action.id)

		for line: String in code.strip_edges(false, true).split('\n'):
			tokens.append(line)

	return tokens


# macro instance behind an action, or null when it can't be resolved
static func _instance_for(_save_data: HenSaveData, _action: HenSaveAction, _phase: StringName = &'', _loop_depth: int = 0) -> HenScriptMacroBase:
	var macro: HenSaveMacro = _resolve_macro(_action.macro_id, _save_data)

	if _macro_is_missing(macro):
		return null

	var instance: HenScriptMacroBase = _load_instance(macro, _save_data)

	if instance:
		_prime_instance(_save_data, instance, _action, _phase, _loop_depth)

	return instance


# context the body getters read: the class the script extends, the literals the
# action holds and which slots are bound. a fresh instance per call, never shared
static func _prime_instance(
	_save_data: HenSaveData,
	_instance: HenScriptMacroBase,
	_action: HenSaveAction,
	_phase: StringName = &'',
	_loop_depth: int = 0
) -> void:
	_instance.target_class = _dispatch_class(_save_data, _instance, _action)
	_instance.action_phase = _phase if not _phase.is_empty() else StringName(str(_action.phase))
	_instance.loop_depth = _loop_depth
	_instance.input_values = {}
	_instance.bound_inputs = {}

	for param: HenSaveParam in _action.inputs:
		if param.default_value != null:
			_instance.input_values[str(param.id)] = param.default_value

	for key: Variant in _action.input_bindings:
		if not HenUtils.bind_expression(_save_data, str(_action.input_bindings[key])).is_empty():
			_instance.bound_inputs[str(key)] = true

	for key: Variant in _action.input_expressions:
		_instance.bound_inputs[str(key)] = true

	for key: Variant in _action.input_actions:
		_instance.bound_inputs[str(key)] = true

	for key: Variant in _action.input_wires:
		_instance.bound_inputs[str(key)] = true

	_instance.nested_action_count = 0

	for list: Array in nested_lists(_action):
		_instance.nested_action_count += list.size()
	_instance.connected_flows = {}

	for out: Dictionary in _instance.get_flow_outputs():
		var id: String = str(out.get('id', ''))

		# steps count as somewhere to go: a branch that only runs them still has to
		# be emitted, and an action that reports its end still has to report it
		if not branch_steps(_action, id).is_empty() 			or branch_target(_save_data, _action, id) 			or not branch_script_id(_save_data, _action, id).is_empty():
			_instance.connected_flows[id] = true


# the class the bodies dispatch on: what the ref slot is bound to when it says
# more than Node, else the class the script extends
static func _dispatch_class(_save_data: HenSaveData, _instance: HenScriptMacroBase, _action: HenSaveAction) -> StringName:
	var identity: StringName = _save_data.identity.type if _save_data.identity else &''

	for input: Dictionary in _instance.get_inputs():
		if not HenUtils.is_node_ref_slot(
			StringName(str(input.get('type', ''))),
			bool(input.get('bind_only', false)),
			bool(input.get('optional', false))
		):
			continue

		var bind: String = str(_action.input_bindings.get(str(input.get('id', '')), ''))
		var bound: StringName = StringName(HenUtils.get_bound_source_type(_save_data, bind))

		if bound != &'Node' and ClassDB.class_exists(bound):
			return bound

		return identity

	return identity


# params for a synthesized lifecycle method: enter mirrors the state's enter vc
# (its transition_data), update the delta output, exit takes none
static func get_phase_params(_save_data: HenSaveData, _state: HenSaveState, _phase: StringName) -> Array:
	if str(_phase) == 'exit':
		return []

	# the phase signature is fixed: the tick phases take delta and enter takes the
	# data the transition carries, which the state declares itself
	if str(_phase) in ['update', 'physics']:
		return [ {name = 'delta'} ]

	if str(_phase) != 'enter':
		return []

	return _state.transition_data.map(func(param: HenSaveParam) -> Dictionary:
		return {name = param.name, type = param.type, category = &'', data = {}}
	)


# body for a phase: the macro's get_flow_<phase>(). only update may fall back to
# the _process override — that body uses delta, which enter/exit don't have
static func _get_phase_body(_instance: HenScriptMacroBase, _phase: StringName) -> String:
	var method: String = 'get_flow_' + str(_phase)

	if _instance.has_method(method):
		var body: Variant = _instance.call(method)
		if body is String and not (body as String).is_empty():
			return body as String

	if str(_phase) == 'update':
		return _get_process_body(_instance)

	return ''


# true when the action contributes anything beyond its phase body — a script-scope
# or class-level declaration, a virtual override, or an enter/exit hook. a nested
# action is reached through emitted_actions, but an INLINE producer is not: it
# hangs off input_actions, so its declarations still would not be collected
static func _declares_hook(_instance: HenScriptMacroBase) -> bool:
	if not _instance.get_script_base().is_empty() \
		or not _instance.get_script_scope().is_empty() \
		or not _instance.get_function_overrides().is_empty():
		return true

	for method: String in ['get_flow_reset', 'get_flow_teardown']:
		if _instance.has_method(method) and str(_instance.call(method)) != '':
			return true

	return false


# true when the macro declares outputs and, after dropping the unstored ones, the
# body has no statement left. detected statically on the substituted body, since
# "side-effect-free" can't be read off the source
static func _produces_nothing(_save_data: HenSaveData, _action: HenSaveAction, _instance: HenScriptMacroBase, _phase: StringName) -> bool:
	if _instance.get_outputs().is_empty() or not _instance.get_unstored_body().is_empty():
		return false

	var body: String = _substitute_outputs(_save_data, _get_phase_body(_instance, _phase), _action, _instance)

	return body.strip_edges().is_empty()


# a declared output writes its value into a bound variable/property: {{out:id}}
# becomes `<lvalue> = <expression>` when bound, and its line vanishes when not
static func _substitute_outputs(_save_data: HenSaveData, _body: String, _action: HenSaveAction, _instance: HenScriptMacroBase) -> String:
	var body: String = _body

	for output: Dictionary in _instance.get_outputs():
		var id: String = str(output.get('id', ''))
		var temp: String = wire_temp_name(_save_data, _action, _instance, id)

		# the macro already put the token where the value is reachable, so parking it
		# right here is what puts the local in the scope the readers run in
		if temp.is_empty():
			body = _drop_placeholder_line(body, 'out:' + id)
		else:
			body = HenActionCode._inject_placeholder(
				body, 'out:' + id, 'var ' + temp + ' = ' + _output_rhs(_instance, id)
			)

	return body


# a value already parked in a local is read as many times as needed for free, one
# that is recomputed at every read has to be parked once two steps read it
static func wire_temp_name(_save_data: HenSaveData, _action: HenSaveAction, _instance: HenScriptMacroBase, _output: String) -> String:
	# a value that costs a call with a body behind it is parked from the first
	# reader: recomputing it would run that body twice
	var readers: int = 2 if _instance.get_unstored_body().is_empty() else 1

	if wire_reader_count(_save_data, StringName(str(_action.id)), _output) < readers:
		return ''

	if _is_cheap_rhs(_output_rhs(_instance, _output)):
		return ''

	return 'wire_{{VCNODE_ID}}_' + _output


# a name or a plain property path costs nothing to read again, and a body that
# never injects its outputs (a call that branches parks them itself) has no line
# for the local to be declared on
static func _is_cheap_rhs(_rhs: String) -> bool:
	var text: String = _rhs.replace('{{VCNODE_ID}}', 'x').strip_edges()

	for part: String in text.split('.'):
		if not part.is_valid_identifier():
			return false

	return true


# the right side of an output assignment, from the macro's get_output_<id>()
static func _output_rhs(_instance: HenScriptMacroBase, _id: String) -> String:
	var rhs: String = _instance.get_output_rhs(_id)

	return rhs if not rhs.is_empty() else 'null'


# removes every line holding {{token}}, used for an output nobody stores.
# _inject_placeholder can't do this: it swaps the token but keeps the line
static func _drop_placeholder_line(_body: String, _token: String) -> String:
	var marker: String = '{{' + _token + '}}'
	var kept: PackedStringArray = []

	for line: String in _body.split('\n'):
		if not line.contains(marker):
			kept.append(line)

	return '\n'.join(kept)


# each flow output is a branch: it emits its transition call, or `pass` when unset
static func _substitute_branches(
	_save_data: HenSaveData,
	_body: String,
	_action: HenSaveAction,
	_branches: Array,
	_state: HenSaveState,
	_phase: StringName = &'',
	_loop_depth: int = 0
) -> String:
	var body: String = _body

	for out: Dictionary in _branches:
		var key: String = str(out.get('id', ''))
		var call: String = _branch_call(_save_data, _action, key, _state)

		# 'pass' means no transition is taken, so there is no edge to flash
		if call != 'pass':
			var trace: String = _transition_trace(_save_data, _action, key, _state)
			if not trace.is_empty():
				call = trace + '\n' + call

			if _transition_ends_phase(_save_data, _action, key, out, _phase):
				call += '\nreturn'

		# the steps the branch runs come first: a transition ends the state, so
		# anything after it would only run on the way out
		var steps: Array = _emit_actions(
			_save_data, _state, branch_steps(_action, key), _phase, _loop_depth, false
		)

		if not steps.is_empty():
			var lines: String = '\n'.join(steps).strip_edges(false, true)

			if not lines.is_empty():
				call = lines if call == 'pass' else lines + '\n' + call

		body = HenActionCode._inject_placeholder(body, key, call)

	return body


# a cross-script transition drives another machine, so this state keeps running
static func _transition_ends_phase(
	_save_data: HenSaveData,
	_action: HenSaveAction,
	_key: String,
	_out: Dictionary,
	_phase: StringName
) -> bool:
	var phase: StringName = _phase if not _phase.is_empty() else StringName(str(_action.phase))

	if phase == &'exit' or bool(_out.get('from_signal', false)):
		return false

	return branch_instance_ref(_save_data, _action, _key).is_empty()


# the steps stored on one branch, empty when it only transitions
static func branch_steps(_action: HenSaveAction, _key: String) -> Array:
	var stored: Variant = _action.branch_actions.get(_key)

	return stored if stored is Array else []


# every nested list an action owns: its loop body and each of its branches
static func nested_lists(_action: HenSaveAction) -> Array:
	var lists: Array = [_action.body_actions]

	for key: Variant in _action.branch_actions:
		var stored: Variant = _action.branch_actions[key]

		if stored is Array and not (stored as Array).is_empty():
			lists.append(stored)

	return lists


# debug: flashes the state-viewer edge for this branch when the transition runs.
# per-script gate (state_targets) matches the state highlight and the cnode
# trace_state_flow; source + event key the edge like _add_action_branch_edges
static func _transition_trace(_save_data: HenSaveData, _action: HenSaveAction, _key: String, _state: HenSaveState) -> String:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global.SETTINGS.debug_compilation:
		return ''

	var target: HenSaveState = branch_target(_save_data, _action, _key)
	if not target:
		return ''

	var branch: Variant = _action.branches.get(_key)
	var label: String = str((branch as Dictionary).get('label', '')) if branch is Dictionary else ''
	var event: String = label if not label.is_empty() else 'go_to_' + target.name
	var script_id: String = str(_save_data.identity.id)

	return 'if _ref.get_instance_id() == HengoDebugger.state_targets.get("' + script_id \
		+ '", -1): HengoDebugger.trace_state_transition("' + _state.name + '", "' + event + '", "' + script_id + '")'


# change_sub_state when the target is a child of the owning state, change_state otherwise
static func _branch_call(_save_data: HenSaveData, _action: HenSaveAction, _key: String, _state: HenSaveState) -> String:
	var target: HenSaveState = branch_target(_save_data, _action, _key)

	if not target:
		return 'pass'

	# cross-script: the instance is the prefix, so the OTHER node's machine is driven
	var instance_ref: String = branch_instance_ref(_save_data, _action, _key)

	if not instance_ref.is_empty():
		return _cross_script_call(_save_data, _action, _key, target, instance_ref)

	var parent: HenSaveState = _parent_of(_save_data, target)

	# top level target: the controller owns it
	if not parent:
		return '_ref._STATE_CONTROLLER.change_state("' + target.name.to_snake_case() + '")'

	# a sub-state is changed on ITS parent, which has to be running for that to
	# make sense — the owner itself, or one of its ancestors when the target is a
	# sibling or an uncle
	var chain: Array = ancestor_chain(_save_data, _state)
	var depth: int = chain.find(parent)

	# not on the running chain: skip_reason reports it, this only keeps the block valid
	if depth < 0:
		return 'pass'

	var receiver: String = '_ref._STATE_CONTROLLER.current_state' + '.current_sub_state'.repeat(depth)

	return receiver + '.change_sub_state("' + target.name.to_snake_case() + '")'


# state that holds _state as a sub-state, null when it is top level
static func _parent_of(_save_data: HenSaveData, _state: HenSaveState) -> HenSaveState:
	for parent_id: Variant in _save_data.sub_states:
		if not (_save_data.sub_states[parent_id] as Array).has(_state):
			continue

		var parent: HenSaveState = find_state(_save_data, StringName(str(parent_id)))

		if parent:
			return parent

		# the drawer belongs to a macro, so the parent is the use running it
		for index: int in range(macro_uses.size() - 1, -1, -1):
			if str(macro_uses[index].macro_id) == str(parent_id):
				return macro_uses[index]

	return null


# [top level, ..., _state], the states that are running when _state runs
static func ancestor_chain(_save_data: HenSaveData, _state: HenSaveState) -> Array:
	var chain: Array = [_state]
	var walker: HenSaveState = _state

	while true:
		var parent: HenSaveState = _parent_of(_save_data, walker)

		if not parent:
			break

		chain.push_front(parent)
		walker = parent

	return chain


# with check_instance on, the instance is resolved once into a temp and validated:
# a freed node or a node of another script skips the transition instead of breaking
static func _cross_script_call(_save_data: HenSaveData, _action: HenSaveAction, _key: String, _target: HenSaveState, _instance_ref: String) -> String:
	var state_name: String = _target.name.to_snake_case()

	if not branch_checks_instance(_save_data, _action, _key):
		return _instance_ref + '._STATE_CONTROLLER.change_state("' + state_name + '")'

	var temp: String = '__hg_' + str(_action.id) + '_' + _key.to_snake_case()

	return 'var ' + temp + ' = ' + _instance_ref + '\n' \
		+ 'if is_instance_valid(' + temp + ') and "_STATE_CONTROLLER" in ' + temp + ':\n' \
		+ '\t' + temp + '._STATE_CONTROLLER.change_state("' + state_name + '")'


# resolves a branch's stored target id to its state, in this save data or in the
# script the branch points at
static func branch_target(_save_data: HenSaveData, _action: HenSaveAction, _key: String) -> HenSaveState:
	var branch: Variant = _action.branches.get(_key)

	if not branch is Dictionary:
		return null

	var exit_id: String = str((branch as Dictionary).get('exit_id', ''))

	if not exit_id.is_empty():
		return macro_exit_target(_save_data, exit_id)

	var script_id: StringName = branch_script_id(_save_data, _action, _key)

	if script_id.is_empty():
		return find_state(_save_data, (branch as Dictionary).get('state_id', &''))

	return find_state_in_script(script_id, (branch as Dictionary).get('state_id', &''))


# where a named way out of a macro leads: the use being generated says it, since
# each one wires its exits to a state of its own scope
static func macro_exit_target(_save_data: HenSaveData, _exit_id: String) -> HenSaveState:
	for index: int in range(macro_uses.size() - 1, -1, -1):
		var use: HenSaveState = macro_uses[index]
		var target: Variant = use.flow_targets.get(_exit_id)

		if target is Dictionary:
			return find_state(_save_data, StringName(str((target as Dictionary).get('state_id', ''))))

	return null


# true when the branch leaves the macro through one of its named ways out
static func branch_is_macro_exit(_action: HenSaveAction, _key: String) -> bool:
	var branch: Variant = _action.branches.get(_key)

	return branch is Dictionary and not str((branch as Dictionary).get('exit_id', '')).is_empty()


# the branch's target script, empty when it points at this script
static func branch_script_id(_save_data: HenSaveData, _action: HenSaveAction, _key: String) -> StringName:
	var branch: Variant = _action.branches.get(_key)

	if not branch is Dictionary:
		return &''

	var script_id: StringName = StringName(str((branch as Dictionary).get('script_id', '')))

	if script_id.is_empty() or (_save_data.identity and script_id == _save_data.identity.id):
		return &''

	return script_id


# expression yielding the instance a cross-script branch drives: a bound var/prop
# or a node path; empty when this branch stays in the script or has no source
static func branch_instance_ref(_save_data: HenSaveData, _action: HenSaveAction, _key: String) -> String:
	var source: Dictionary = branch_instance_source(_save_data, _action, _key)

	match str(source.get('kind', '')):
		'bind':
			# a deleted variable leaves the branch unbound, which the caller reports
			var bind: String = HenUtils.resolve_bind_code(_save_data, str(source.value))
			return ('_ref.' + bind) if not bind.is_empty() else ''
		'path':
			# the guard needs a null instead of the error get_node pushes for a missing node
			var getter: String = 'get_node_or_null' if branch_checks_instance(_save_data, _action, _key) else 'get_node'
			return '_ref.' + getter + '("' + str(source.value) + '")'

	return ''


# {kind: 'bind'|'path', value} of a cross-script branch; empty dict when unset.
# a branch holds one source at a time — the bind wins if both ever coexist
static func branch_instance_source(_save_data: HenSaveData, _action: HenSaveAction, _key: String) -> Dictionary:
	if branch_script_id(_save_data, _action, _key).is_empty():
		return {}

	var branch: Dictionary = _action.branches[_key]
	var bind: String = str(branch.get('instance_bind', ''))

	if not bind.is_empty():
		return {kind = 'bind', value = bind}

	var path: String = str(branch.get('instance_path', ''))

	if not path.is_empty():
		return {kind = 'path', value = path}

	return {}


static func branch_checks_instance(_save_data: HenSaveData, _action: HenSaveAction, _key: String) -> bool:
	if branch_script_id(_save_data, _action, _key).is_empty():
		return false

	return bool((_action.branches[_key] as Dictionary).get('check_instance', false))


# a state of another script: the in-memory copy when it is open, the mapped ast
# next, and the saved resource as the last resort (closed scripts aren't mapped)
static func find_state_in_script(_script_id: StringName, _state_id: StringName) -> HenSaveState:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	for save_data: HenSaveData in global.OPEN_SCRIPTS:
		if save_data and save_data.identity and save_data.identity.id == _script_id:
			return find_state(save_data, _state_id)

	var map_dep: HenMapDependencies = Engine.get_singleton(&'MapDependencies')

	if map_dep and map_dep.ast_list.has(_script_id):
		for state: HenSaveState in (map_dep.ast_list[_script_id] as HenMapDependencies.ProjectAST).states:
			if str(state.id) == str(_state_id):
				return state

	return load_state_from_disk(_script_id, _state_id)


# state resources are saved as <script dir>/states/<state id>.res
static func load_state_from_disk(_script_id: StringName, _state_id: StringName) -> HenSaveState:
	if str(_state_id).is_empty():
		return null

	var path: String = str(HenUtils.get_side_bar_item_path(_script_id, HenSideBar.SideBarItem.STATES)) + str(_state_id) + HenEnums.SAVE_EXTENSION

	if not FileAccess.file_exists(path):
		return null

	return load(path) as HenSaveState


static func find_state(_save_data: HenSaveData, _state_id: StringName) -> HenSaveState:
	if str(_state_id).is_empty():
		return null

	for state: HenSaveState in _save_data.states:
		if str(state.id) == str(_state_id):
			return state

	for sub_list: Variant in _save_data.sub_states.values():
		for state: HenSaveState in sub_list:
			if str(state.id) == str(_state_id):
				return state

	return null


# true when every branch the action declares is a shortcut it can go without
static func _branches_are_optional(_branches: Array) -> bool:
	for out: Dictionary in _branches:
		if not bool(out.get('optional', false)):
			return false

	return true


# a branch is wired when it transitions or runs steps, and only the transition
# is refused on exit
static func _branch_is_wired(_save_data: HenSaveData, _action: HenSaveAction, _branches: Array) -> bool:
	for out: Dictionary in _branches:
		if branch_is_macro_exit(_action, str(out.get('id', ''))):
			return true

	return _has_transition(_save_data, _action, _branches) or _runs_branch_steps(_action, _branches)


# a branch that runs steps is in use even with nowhere to transition to
static func _runs_branch_steps(_action: HenSaveAction, _branches: Array) -> bool:
	for out: Dictionary in _branches:
		if not branch_steps(_action, str(out.get('id', ''))).is_empty():
			return true

	return false


static func _has_transition(_save_data: HenSaveData, _action: HenSaveAction, _branches: Array) -> bool:
	for out: Dictionary in _branches:
		if branch_target(_save_data, _action, str(out.get('id', ''))):
			return true

	return false


# slot of the first binding pointing at a variable that is gone, input or
# expression word; empty when every binding still resolves
static func _first_broken_binding(_save_data: HenSaveData, _action: HenSaveAction) -> String:
	for key: Variant in _action.input_bindings:
		var bind: String = str(_action.input_bindings[key])

		if not bind.is_empty() and HenUtils.resolve_bind_code(_save_data, bind).is_empty():
			return 'input "' + str(key) + '"'

	for key: Variant in _action.input_expressions:
		var expr: HenSaveActionExpression = _action.input_expressions[key]

		for word: Variant in expr.word_bindings:
			var wbind: String = str(expr.word_bindings[word])

			if not wbind.is_empty() and HenUtils.resolve_bind_code(_save_data, wbind).is_empty():
				return 'expression word "' + str(word) + '"'

	return ''


# a fault deep in the subtree takes the top action down, instead of emitting half of it
# a wire to a step that no longer exists would emit a silent null
static func _first_broken_wire(_save_data: HenSaveData, _action: HenSaveAction) -> String:
	for key: Variant in _action.input_wires:
		var producer: HenSaveAction = wire_producer(_save_data, _action.input_wires[key])

		if not producer:
			return 'input "' + str(key) + '" reads a step that no longer exists'

		var instance: HenScriptMacroBase = _instance_for(_save_data, producer)
		var output: String = str((_action.input_wires[key] as Dictionary).get('output', ''))

		if not instance or not instance.has_output_rhs(output):
			return 'input "' + str(key) + '" reads an output that step does not have'

	return ''


static func _first_broken_inline(_save_data: HenSaveData, _action: HenSaveAction) -> String:
	for key: Variant in _action.input_actions:
		var child: HenSaveAction = _inline_child(_action.input_actions[key])

		if not child:
			return 'input "' + str(key) + '" inline action is empty'

		var instance: HenScriptMacroBase = _instance_for(_save_data, child)

		if not instance:
			return 'input "' + str(key) + '" inline action could not be resolved'

		if not is_inlinable(instance):
			return 'input "' + str(key) + '" inline action is not a pure value producer'

		var broken: String = _first_broken_binding(_save_data, child)

		if not broken.is_empty():
			return broken + ' binds a variable that no longer exists'

		var deeper: String = _first_broken_inline(_save_data, child)

		if not deeper.is_empty():
			return deeper

	return ''


# first input that requires a binding and does not have a usable one. an
# expression never qualifies, and a binding that resolves to nothing (empty node
# path, deleted variable) counts as unbound. an `lvalue` is stricter still: it
# becomes the left side of an assignment, so a call like randf() or get_node("x")
# is refused too — `f() = 5` does not compile
static func _first_unbound_required(_save_data: HenSaveData, _action: HenSaveAction, _instance: HenScriptMacroBase) -> String:
	for input: Dictionary in _instance.get_inputs():
		var is_lvalue: bool = bool(input.get('lvalue', false))

		if not is_lvalue and not bool(input.get('bind_only', false)):
			continue

		var key: String = str(input.get('id', ''))
		var name: String = str(input.get('name', key))

		# a producer wired into the slot is a real source, it just cannot be the left
		# side of an assignment, and an expression is neither
		if _action.input_actions.has(key) or _action.input_wires.has(key):
			if is_lvalue:
				return name

			continue

		if _action.input_expressions.has(key):
			return name

		var bind: String = HenUtils.bind_expression(_save_data, _action.input_bindings.get(key, ''))

		if bind.is_empty():
			# an optional target is simply left out of the emitted code
			if bool(input.get('optional', false)):
				# a node slot falls back to this node, which has to be able to stand in for it
				if _self_cannot_stand_in(_save_data, _instance, input):
					return name

				continue

			return name

		if is_lvalue and bind.contains('('):
			return name

	return ''


# true when an unbound node slot has nothing to fall back to: the slot asks for a
# class the node running the script could never be, or the action itself was
# written for classes this script is none of
static func _self_cannot_stand_in(_save_data: HenSaveData, _instance: HenScriptMacroBase, _input: Dictionary) -> bool:
	var type: StringName = StringName(str(_input.get('type', '')))

	if not HenUtils.is_node_ref_slot(type, bool(_input.get('bind_only', false)), true):
		return false

	var identity: StringName = _save_data.identity.type if _save_data.identity else &''

	if identity.is_empty():
		return false

	return not HenUtils.can_hold_instance_of(identity, type) 		or not HenUtils.class_serves(identity, _instance.get_target_classes())


# name of the first branch that targets another script without an instance source
static func _first_unbound_cross_branch(_save_data: HenSaveData, _action: HenSaveAction, _branches: Array) -> String:
	for out: Dictionary in _branches:
		var key: String = str(out.get('id', ''))

		if branch_script_id(_save_data, _action, key).is_empty():
			continue

		if branch_instance_ref(_save_data, _action, key).is_empty():
			return str(out.get('name', key))

	return ''


static func _resolve_macro(_macro_id: StringName, _save_data: HenSaveData = null) -> HenSaveMacro:
	if HenFunctionMacro.is_function_macro(_macro_id):
		return HenFunctionMacro.macro_for(_save_data, _macro_id)

	if HenMacroHookMacro.is_hook_macro(_macro_id):
		return HenMacroHookMacro.macro_for(_save_data, _macro_id)

	var global: HenGlobal = Engine.get_singleton(&'Global')

	for macro: HenSaveMacro in global.action_macros:
		if macro.id == _macro_id:
			return macro

	for macro: HenSaveMacro in global.script_macros:
		if macro.id == _macro_id:
			return macro

	return null


# a function has no script on disk: it is emitted from the save data it lives in
static func _macro_is_missing(_macro: HenSaveMacro) -> bool:
	if not _macro:
		return true

	return _macro.function_id.is_empty() and not FileAccess.file_exists(_macro.script_path)


static func _load_instance(_macro: HenSaveMacro, _save_data: HenSaveData = null) -> HenScriptMacroBase:
	if HenMacroHookMacro.is_hook_macro(_macro.id):
		return HenMacroHookMacro.instance_for(_save_data, _macro.id)

	if not _macro.function_id.is_empty():
		return HenFunctionMacro.instance_for(_save_data, _macro.id)

	# CACHE_MODE_REUSE keeps the registered class identity — CACHE_MODE_IGNORE
	# yields a fresh script whose `as HenScriptMacroBase` cast fails under editor hot-reload
	var script: GDScript = ResourceLoader.load(_macro.script_path, "", ResourceLoader.CACHE_MODE_REUSE)

	if not script:
		return null

	var instance: Object = script.new()

	if instance is HenScriptMacroBase:
		return instance as HenScriptMacroBase

	return null


# extracts the _process override body (string or callable), matching gen_base handling
static func _get_process_body(_instance: HenScriptMacroBase) -> String:
	for override: Dictionary in _instance.get_function_overrides():
		if override.get('name', '') != '_process':
			continue

		var body: Variant = override.get('body', '')

		if not (body is Callable):
			return str(body)

		var callable_body: Callable = body as Callable
		var call_result: Variant = callable_body.call()

		if call_result is String:
			return call_result as String

		var object: Object = callable_body.get_object()
		var source: String = object.get_script().source_code if object and object.get_script() else ''
		var parsed: Dictionary = HenActionCode.parse_script_function(source, callable_body.get_method())
		return parsed.get('body', '')

	return ''


# replaces {{input_id}} using the macro definition's inputs (they define the
# placeholders); the action's stored value wins, macro default is the fallback
static func _substitute_inputs(_save_data: HenSaveData, _body: String, _action: HenSaveAction, _instance: HenScriptMacroBase) -> String:
	var body: String = _body

	for input: Dictionary in _instance.get_inputs():
		var input_id: StringName = input.get('id', '')
		var key: String = str(input_id)
		var literal: String

		# priority: wire > inline action > expression > binding > literal
		if _action.input_wires.has(key):
			literal = '(' + _emit_wire(_save_data, _action.input_wires[key]) + ')'
		elif _action.input_actions.has(key):
			literal = '(' + _emit_inline_action(_save_data, _action.input_actions[key]) + ')'
		elif _action.input_expressions.has(key):
			literal = '(' + _resolve_expression(_save_data, _action.input_expressions[key]) + ')'
		else:
			var bind: String = HenUtils.bind_expression(_save_data, _action.input_bindings.get(key, ''))
			if not bind.is_empty():
				# bound input reads a var/prop off the owner, or an engine-global value
				literal = bind
			else:
				var value: Variant = input.get('default_value')
				for param: HenSaveParam in _action.inputs:
					if str(param.id) == key and param.default_value != null:
						value = param.default_value
						break

				if bool(input.get('raw', false)):
					# raw input: a code fragment emitted verbatim, never quoted
					literal = str(value)
				else:
					literal = HenActionCode.get_default_value_code(_save_data, effective_type(_save_data, _action, input), false, '', null, value)

		body = HenActionCode._inject_placeholder(body, key, literal)

	return body


# the producer's id feeds {{VCNODE_ID}}, so the local this reads is the one that step
# declared and not a fresh one
static func _emit_wire(_save_data: HenSaveData, _wire: Variant) -> String:
	var producer: HenSaveAction = wire_producer(_save_data, _wire)

	if not producer:
		return 'null'

	var instance: HenScriptMacroBase = _instance_for(_save_data, producer)

	if not instance:
		return 'null'

	var output: String = str((_wire as Dictionary).get('output', ''))
	var temp: String = wire_temp_name(_save_data, producer, instance, output)
	var rhs: String = temp

	# the parked local has no placeholders of its own beyond the producer's id
	if temp.is_empty():
		rhs = _substitute_inputs(_save_data, _output_rhs(instance, output), producer, instance)

	rhs = _process_body(rhs, producer.id)

	return rhs.strip_edges()


# a wire may only read a value that already ran on the path reaching it: same phase,
# earlier in the order, and inside the scope that value lives in
static func _first_out_of_scope_wire(_save_data: HenSaveData, _state: HenSaveState, _action: HenSaveAction) -> String:
	if _action.input_wires.is_empty():
		return ''

	var index: Dictionary = _index_state_actions(_save_data, _state)
	var reader: Dictionary = index.get(StringName(str(_action.id)), {})

	if reader.is_empty():
		return ''

	for key: Variant in _action.input_wires:
		var wire: Dictionary = _action.input_wires[key] as Dictionary
		var producer: HenSaveAction = wire_producer(_save_data, wire)
		var written: Dictionary = index.get(StringName(str(producer.id)), {}) if producer else {}
		var where: String = 'input "' + str(key) + '" reads '

		if written.is_empty():
			return where + 'a step of another state'

		if StringName(str(written.phase)) != StringName(str(reader.phase)):
			return where + 'a step that runs on ' + str(written.phase) + ', not on ' + str(reader.phase)

		if int(reader.order) < int(written.order):
			return where + 'a step that only runs after it'

		var instance: HenScriptMacroBase = _instance_for(_save_data, producer)
		var branch: String = str(instance.output_branch(StringName(str(wire.get('output', ''))))) if instance else ''
		var chain: Array = written.chain as Array
		var scope: String = str(chain[chain.size() - 1])

		if branch == str(HenFlowGraphTypes.BODY_PIN):
			scope = str(producer.id) + ':body'
		elif not branch.is_empty():
			scope = str(producer.id) + ':branch:' + branch

		if (reader.chain as Array).has(scope):
			continue

		if branch == str(HenFlowGraphTypes.BODY_PIN):
			return where + 'a value that only exists inside the loop it belongs to'

		if not branch.is_empty():
			return where + 'a value that only exists inside the ' + branch + ' branch'

		return where + 'a value that does not exist on this path'

	return ''


# every step of a state keyed by id, with the order it is emitted in, the phase it
# ends up running at and the containers it sits inside
static func _index_state_actions(_save_data: HenSaveData, _state: HenSaveState) -> Dictionary:
	var index: Dictionary = {}

	_index_action_list(_save_data.get_state_actions(_state.id), '', [], &'', index, [0])

	return index


static func _index_action_list(_actions: Array, _container: String, _parents: Array, _phase: StringName, _index: Dictionary, _order: Array) -> void:
	var chain: Array = _parents.duplicate()

	chain.append(_container)

	for action: HenSaveAction in _actions:
		var phase: StringName = _phase if not str(_phase).is_empty() else StringName(str(action.phase))

		_index[StringName(str(action.id))] = {order = _order[0], phase = phase, chain = chain}
		_order[0] += 1

		_index_action_list(action.body_actions, str(action.id) + ':body', chain, phase, _index, _order)

		for key: Variant in action.branch_actions:
			_index_action_list(
				branch_steps(action, str(key)), str(action.id) + ':branch:' + str(key), chain, phase, _index, _order
			)


# a step whose only content is its outputs still earns its place when a wire reads
# it, so the reverse lookup runs before calling it dead
static func is_wire_source(_save_data: HenSaveData, _action: HenSaveAction) -> bool:
	return wire_reader_count(_save_data, StringName(str(_action.id)), '') > 0


# how many steps read one output of a step; an empty output counts them all
static func wire_reader_count(_save_data: HenSaveData, _id: StringName, _output: String) -> int:
	var total: int = 0

	for state_id: Variant in _save_data.state_actions:
		total += _count_wire_readers(_save_data.state_actions[state_id], _id, _output)

	return total


static func _count_wire_readers(_actions: Array, _id: StringName, _output: String) -> int:
	var total: int = 0

	for action: HenSaveAction in _actions:
		for key: Variant in action.input_wires:
			var wire: Variant = action.input_wires[key]

			if not wire is Dictionary:
				continue

			var spec: Dictionary = wire as Dictionary

			if StringName(str(spec.get('action_id', ''))) != _id:
				continue

			if _output.is_empty() or str(spec.get('output', '')) == _output:
				total += 1

		# an inline producer is not a step, so the tree walk never reaches it and a wire
		# inside one would read as a single reader and never get parked
		for nested: Variant in action.input_actions.values():
			var child: HenSaveAction = _inline_child(nested)

			if child:
				total += _count_wire_readers([child], _id, _output)

		for list: Array in nested_lists(action):
			total += _count_wire_readers(list, _id, _output)

	return total


static func wire_producer(_save_data: HenSaveData, _wire: Variant) -> HenSaveAction:
	if not _wire is Dictionary:
		return null

	return find_action(_save_data, StringName(str((_wire as Dictionary).get('action_id', ''))))


# any step of the script by id, loop bodies and branch steps included
static func find_action(_save_data: HenSaveData, _id: StringName) -> HenSaveAction:
	if str(_id).is_empty():
		return null

	for state_id: Variant in _save_data.state_actions:
		var found: HenSaveAction = _find_action_in(_save_data.state_actions[state_id], _id)

		if found:
			return found

	return null


static func _find_action_in(_actions: Array, _id: StringName) -> HenSaveAction:
	for action: HenSaveAction in _actions:
		if StringName(str(action.id)) == _id:
			return action

		for list: Array in nested_lists(action):
			var found: HenSaveAction = _find_action_in(list, _id)

			if found:
				return found

	return null


# the child's own id feeds {{VCNODE_ID}}, so a nested producer never collides
static func _emit_inline_action(_save_data: HenSaveData, _ref: Variant) -> String:
	var child: HenSaveAction = _inline_child(_ref)

	if not child:
		return 'null'

	var instance: HenScriptMacroBase = _instance_for(_save_data, child)

	if not instance:
		return 'null'

	var output_id: String = _inline_output(_ref, instance)

	if output_id.is_empty():
		return 'null'

	var rhs: String = _output_rhs(instance, output_id)
	rhs = _substitute_inputs(_save_data, rhs, child, instance)
	rhs = _process_body(rhs, child.id)

	# _inject_placeholder trails a newline per input, which would break the expression
	return rhs.strip_edges()


# tolerates the {action, output} dict and a bare action (older data)
static func _inline_child(_ref: Variant) -> HenSaveAction:
	if _ref is HenSaveAction:
		return _ref as HenSaveAction

	if _ref is Dictionary:
		return (_ref as Dictionary).get('action') as HenSaveAction

	return null


static func _inline_output(_ref: Variant, _instance: HenScriptMacroBase) -> String:
	var output_id: String = str((_ref as Dictionary).get('output', '')) if _ref is Dictionary else ''

	if not output_id.is_empty():
		return output_id

	var outputs: Array = _instance.get_outputs()

	return str(outputs[0].get('id', '')) if not outputs.is_empty() else ''


# a pure value producer: an output to read, no branch, no body, no state hook
static func is_inlinable(_instance: HenScriptMacroBase) -> bool:
	# an optional branch is a shortcut nobody wired when the action runs inline, so
	# it still is the pure value producer an inline slot needs
	if _instance.get_outputs().is_empty() or not _branches_are_optional(_instance.get_flow_outputs()):
		return false

	if _instance.get_has_body() or _instance.get_needs_loop() or _declares_hook(_instance):
		return false

	var found_body: bool = false

	for phase: StringName in HenSaveAction.PHASE_ORDER:
		var body: String = _get_phase_body(_instance, phase)

		if body.is_empty():
			continue

		found_body = true

		if not _body_is_only_outputs(body, _instance):
			return false

	return found_body


static func _body_is_only_outputs(_body: String, _instance: HenScriptMacroBase) -> bool:
	var stripped: String = _body

	for output: Dictionary in _instance.get_outputs():
		stripped = _drop_placeholder_line(stripped, 'out:' + str(output.get('id', '')))

	return stripped.strip_edges().is_empty()


# an input's effective type: follows type_from to whatever another slot is bound
# to. type_from may name an input OR an output (a producer's inputs follow the
# type of the variable its result is stored in)
static func effective_type(_save_data: HenSaveData, _action: HenSaveAction, _input: Dictionary) -> String:
	var declared: String = _input.get('type', 'Variant')
	var type_from: String = str(_input.get('type_from', ''))

	if type_from.is_empty():
		return declared

	var bind: String = str(_action.input_bindings.get(type_from, ''))
	if bind.is_empty():
		return declared

	var resolved: String = HenUtils.get_bound_source_type(_save_data, bind)
	return resolved if not resolved.is_empty() else declared


# renders an expression: each word -> _ref.<bind> (bound) or its raw code fragment (literal)
static func _resolve_expression(_save_data: HenSaveData, _expr: HenSaveActionExpression) -> String:
	var vals: Dictionary = {}

	for word: HenSaveParam in _expr.words:
		var wbind: String = HenUtils.bind_expression(_save_data, _expr.word_bindings.get(word.name, ''))
		if not wbind.is_empty():
			vals[word.name] = wbind
		else:
			# word literal = raw code fragment (verbatim), not a quoted string; empty -> '0'
			var raw: String = str(word.default_value)
			vals[word.name] = raw if not raw.is_empty() and raw != '<null>' else '0'

	return _sub_words(_expr.code, vals)


# single-pass \b(w1|w2|..)\b replacement, right-to-left so substituted text isn't rescanned
static func _sub_words(_code: String, _vals: Dictionary) -> String:
	if _vals.is_empty():
		return _code

	var reg: RegEx = RegEx.new()
	reg.compile('\\b(' + '|'.join(_vals.keys()) + ')\\b')

	var matches: Array = reg.search_all(_code)
	var quoted: Array = _quoted_ranges(_code)
	var out: String = _code

	for i: int in range(matches.size() - 1, -1, -1):
		var m: RegExMatch = matches[i]
		var w: String = m.get_string()

		if _in_ranges(quoted, m.get_start()):
			continue

		if _vals.has(w):
			out = out.substr(0, m.get_start()) + str(_vals[w]) + out.substr(m.get_end())

	return out


# text spans of the string literals in an expression: a word named `n` also matches
# the n of a \n escape, and one named `hp` matches inside 'hp: '
static func _quoted_ranges(_code: String) -> Array:
	var ranges: Array = []
	var quote: String = ''
	var start: int = 0
	var i: int = 0

	while i < _code.length():
		var c: String = _code[i]

		if quote.is_empty():
			if c == "'" or c == '"':
				quote = c
				start = i
		elif c == '\\':
			i += 1
		elif c == quote:
			ranges.append([start, i])
			quote = ''

		i += 1

	# an unterminated quote runs to the end, so nothing after it is substituted
	if not quote.is_empty():
		ranges.append([start, _code.length()])

	return ranges


static func _in_ranges(_ranges: Array, _pos: int) -> bool:
	for range_pair: Array in _ranges:
		if _pos > range_pair[0] and _pos < range_pair[1]:
			return true

	return false


static func _unresolved_token(_action: HenSaveAction, _reason: String) -> String:
	push_warning('hengo: action ' + str(_action.macro_id) + ' (' + str(_action.id) + ') unresolved: ' + _reason)
	return '# hengo: action ' + str(_action.macro_id) + ' (' + str(_action.id) + ') unresolved: ' + _reason
