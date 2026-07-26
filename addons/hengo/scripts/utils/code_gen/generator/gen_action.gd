class_name HenGeneratorAction extends RefCounted

# emits a state's linear action list into its lifecycle methods (enter/update/exit).
# an action is an instance of a macro-script definition (HenScriptMacroBase),
# run playmaker-style; decoupled from cnode/virtualcnode codegen.


# tokens for the actions assigned to one lifecycle phase of a state
static func get_state_action_tokens(_save_data: HenSaveData, _state: HenSaveState, _phase: StringName) -> Array:
	return _emit_actions(_save_data, _state, _save_data.get_state_actions(_state.id), _phase, 0, true)


# lines for a list of actions run at one phase. the top level is the state's list,
# filtered by phase; a loop passes its body_actions with _filter off (they run
# when the loop runs) and depth+1 so break/continue know they are inside a loop
static func _emit_actions(_save_data: HenSaveData, _state: HenSaveState, _actions: Array, _phase: StringName, _loop_depth: int, _filter_phase: bool) -> Array:
	var tokens: Array = []
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var debug: bool = global.SETTINGS.debug_compilation

	for action: HenSaveAction in _actions:
		if _filter_phase and str(action.phase) != str(_phase):
			continue

		var macro: HenSaveMacro = _resolve_macro(action.macro_id)

		if not macro or not FileAccess.file_exists(macro.script_path):
			tokens.append(_unresolved_token(action, 'macro not found'))
			continue

		var instance: HenScriptMacroBase = _load_instance(macro)

		if not instance:
			tokens.append(_unresolved_token(action, 'could not instance macro'))
			continue

		_prime_instance(_save_data, instance, action)

		var reason: String = skip_reason(_save_data, _state, action, instance, _phase, _loop_depth)

		if not reason.is_empty():
			tokens.append(_unresolved_token(action, reason))
			continue

		# a nested action emits at the LOOP's phase, never its own stored phase
		var body: String = _get_phase_body(instance, _phase)
		var branches: Array = instance.get_flow_outputs()

		# outputs before inputs: the output rhs still holds {{input}} placeholders the
		# next sweep resolves. then branch transitions, then {{VCNODE_ID}} / _ref
		body = _substitute_outputs(_save_data, body, action, instance)
		body = _substitute_inputs(_save_data, body, action, instance)
		body = _substitute_branches(_save_data, body, action, branches, _state)
		body = HenVirtualCNodeCode.process_script_macro_body(body, false, action.id)

		# the nested body goes in LAST, after this action's own {{VCNODE_ID}} pass:
		# its lines are already resolved and must not be run through it again
		if instance.get_has_body():
			body = _substitute_loop_body(_save_data, _state, body, action, _phase, _loop_depth)

		# lights the action's row green when execution reaches it, like the cnode
		# trace_flow; only for the focused instance, gone in release builds
		if debug:
			tokens.append("if _ref.get_instance_id() == HengoDebugger.target_instance_id: HengoDebugger.trace_action(&'%s')" % str(action.id))

		for line: String in body.strip_edges(false, true).split('\n'):
			tokens.append(line)

	return tokens


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

	return HenVirtualCNodeCode._inject_placeholder(_body, 'loop_body', '\n'.join(nested))


# why an action cannot be emitted, empty when it is fine. every emission path
# asks this, so a skipped action never leaves half of itself behind — the phase
# body is dropped but its script base, its connect and its disconnect are not.
# _phase/_loop_depth default so the hook callers (script base, reset, teardown)
# need no change; only the emit path passes them
static func skip_reason(_save_data: HenSaveData, _state: HenSaveState, _action: HenSaveAction, _instance: HenScriptMacroBase, _phase: StringName = &'', _loop_depth: int = 0) -> String:
	var invalid: String = _instance.get_validation_error()

	if not invalid.is_empty():
		return invalid

	# break/continue are only valid inside a loop body
	if _instance.get_needs_loop() and _loop_depth == 0:
		return str(_instance.get_display_name()).to_lower() + ' can only be used inside a loop'

	# an action that keeps state (a wait counter, a signal connection, an _input
	# override) can't run inside a loop: its declarations live at the state/script
	# level and would not be collected, and a per-iteration hook makes no sense
	if _loop_depth > 0 and _declares_hook(_instance):
		return str(_instance.get_display_name()).to_lower() + ' can only be used at the top level, not inside a loop'

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

	var branches: Array = _instance.get_flow_outputs()

	# a pure producer whose only content is its outputs contributes nothing when
	# none is stored: the phase method would be left empty and fail to parse
	if branches.is_empty():
		if _produces_nothing(_save_data, _action, _instance, phase):
			return 'no output stored'

		return ''

	# change_state calls exit() before swapping current_state, so a transition
	# emitted from exit re-enters it forever
	if str(phase) == 'exit':
		return 'a branching action cannot run on exit'

	# a branching action with nowhere to go would emit `if x: pass else: pass`
	if not _has_branch_target(_save_data, _action, branches):
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


# class-level declarations the actions of a state need, from each macro's
# get_script_base(). emitted inside the state class, so an action can keep a
# counter across frames; {{VCNODE_ID}} makes the names unique per action
static func get_state_base_lines(_save_data: HenSaveData, _state: HenSaveState) -> Array:
	var lines: Array = []

	for action: HenSaveAction in _save_data.get_state_actions(_state.id):
		var instance: HenScriptMacroBase = _instance_for(_save_data, action)

		# the phase path already reported it; emitting only its base would leave a
		# listener armed for an action that does not run
		if not instance or not skip_reason(_save_data, _state, action, instance).is_empty():
			continue

		var base: String = instance.get_script_base()

		if base.is_empty():
			continue

		base = HenVirtualCNodeCode.process_script_macro_body(base, false, action.id)

		# a blank line between blocks, or two actions run together on screen
		if not lines.is_empty():
			lines.append('')

		for line: String in base.strip_edges().split('\n'):
			lines.append(line)

	return lines


# declarations an action needs at SCRIPT scope, from get_script_scope(). the state
# class cannot hold them when a virtual override has to read them — _input runs on
# the node, not on the state
static func get_script_scope_lines(_save_data: HenSaveData) -> Array:
	var lines: Array = []

	for state: HenSaveState in _all_states(_save_data):
		for action: HenSaveAction in _save_data.get_state_actions(state.id):
			var instance: HenScriptMacroBase = _live_instance(_save_data, state, action)

			if not instance:
				continue

			var scope: String = instance.get_script_scope()

			if scope.is_empty():
				continue

			scope = HenVirtualCNodeCode.process_script_macro_body(scope, false, action.id)

			for line: String in scope.strip_edges().split('\n'):
				lines.append(line)

	return lines


# merges the virtual overrides the actions declare into the map gen_base emits.
# bodies are split line by line: a single multi-line token would only get the
# first line indented
static func merge_script_overrides(_save_data: HenSaveData, _override_data: Dictionary) -> void:
	for state: HenSaveState in _all_states(_save_data):
		for action: HenSaveAction in _save_data.get_state_actions(state.id):
			var instance: HenScriptMacroBase = _live_instance(_save_data, state, action)

			if not instance:
				continue

			for override: Dictionary in instance.get_function_overrides():
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

				var code: String = HenVirtualCNodeCode.process_script_macro_body(body as String, false, action.id)

				for line: String in code.strip_edges(false, true).split('\n'):
					(_override_data[func_name].tokens as Array).append(line)


# instance of an action that actually gets emitted; null when it is skipped, so a
# skipped action never leaves an override or a declaration behind
static func _live_instance(_save_data: HenSaveData, _state: HenSaveState, _action: HenSaveAction) -> HenScriptMacroBase:
	var instance: HenScriptMacroBase = _instance_for(_save_data, _action)

	if not instance or not skip_reason(_save_data, _state, _action, instance).is_empty():
		return null

	return instance


# every state of the script, sub-states included
static func _all_states(_save_data: HenSaveData) -> Array:
	var states: Array = []
	states.append_array(_save_data.states)

	for sub_list: Variant in _save_data.sub_states.values():
		states.append_array(sub_list)

	return states


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

	for action: HenSaveAction in _save_data.get_state_actions(_state.id):
		var instance: HenScriptMacroBase = _instance_for(_save_data, action)

		if not instance or not instance.has_method(_method):
			continue

		if not skip_reason(_save_data, _state, action, instance).is_empty():
			continue

		var body: Variant = instance.call(_method)

		if not body is String or (body as String).is_empty():
			continue

		var code: String = _substitute_inputs(_save_data, body as String, action, instance)
		code = HenVirtualCNodeCode.process_script_macro_body(code, false, action.id)

		for line: String in code.strip_edges(false, true).split('\n'):
			tokens.append(line)

	return tokens


# macro instance behind an action, or null when it can't be resolved
static func _instance_for(_save_data: HenSaveData, _action: HenSaveAction) -> HenScriptMacroBase:
	var macro: HenSaveMacro = _resolve_macro(_action.macro_id)

	if not macro or not FileAccess.file_exists(macro.script_path):
		return null

	var instance: HenScriptMacroBase = _load_instance(macro)

	if instance:
		_prime_instance(_save_data, instance, _action)

	return instance


# context the body getters read: the class the script extends, the literals the
# action holds and which slots are bound. a fresh instance per call, never shared
static func _prime_instance(_save_data: HenSaveData, _instance: HenScriptMacroBase, _action: HenSaveAction) -> void:
	_instance.target_class = _save_data.identity.type if _save_data.identity else &''
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


# params for a synthesized lifecycle method: enter mirrors the state's enter vc
# (its transition_data), update the delta output, exit takes none
static func get_phase_params(_save_data: HenSaveData, _state: HenSaveState, _phase: StringName) -> Array:
	if str(_phase) == 'exit':
		return []

	var vc_name: String = str(_phase)

	for vc: HenVirtualCNode in _state.get_route(_save_data).virtual_sub_type_vc_list:
		if vc.name == vc_name:
			return HenVirtualCNodeCode.get_output_token_list(_save_data, vc)

	return [ {name = 'delta'} ] if vc_name in ['update', 'physics'] else []


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
# or class-level declaration, a virtual override, or an enter/exit hook. those are
# gathered from the flat state list only, so nesting one would drop its declarations
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
	if _instance.get_outputs().is_empty():
		return false

	var body: String = _substitute_outputs(_save_data, _get_phase_body(_instance, _phase), _action, _instance)

	return body.strip_edges().is_empty()


# a declared output writes its value into a bound variable/property: {{out:id}}
# becomes `<lvalue> = <expression>` when bound, and its line vanishes when not
static func _substitute_outputs(_save_data: HenSaveData, _body: String, _action: HenSaveAction, _instance: HenScriptMacroBase) -> String:
	var body: String = _body

	for output: Dictionary in _instance.get_outputs():
		var id: String = str(output.get('id', ''))
		var lvalue: String = _output_lvalue(_save_data, _action, id)

		# bound: the token line becomes `store = rhs`; unbound: drop the whole line
		if not lvalue.is_empty():
			body = HenVirtualCNodeCode._inject_placeholder(body, 'out:' + id, lvalue + ' = ' + _output_rhs(_instance, id))
		else:
			body = _drop_placeholder_line(body, 'out:' + id)

	return body


# assignable target an output writes to, empty when nothing usable is bound. the
# picker only offers a variable or a property, both of which bind_expression turns
# into an lvalue (_ref.<var> / _ref.<prop>); a call-shaped source (randf()) is
# refused here too, since `randf() = x` does not compile
static func _output_lvalue(_save_data: HenSaveData, _action: HenSaveAction, _id: String) -> String:
	var lvalue: String = HenUtils.bind_expression(_save_data, str(_action.output_bindings.get(_id, '')))

	return '' if lvalue.contains('(') else lvalue


# the right side of an output assignment, from the macro's get_output_<id>()
static func _output_rhs(_instance: HenScriptMacroBase, _id: String) -> String:
	var method: String = 'get_output_' + _id

	if _instance.has_method(method):
		var rhs: Variant = _instance.call(method)
		if rhs is String:
			return rhs as String

	return 'null'


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
static func _substitute_branches(_save_data: HenSaveData, _body: String, _action: HenSaveAction, _branches: Array, _state: HenSaveState) -> String:
	var body: String = _body

	for out: Dictionary in _branches:
		var key: String = str(out.get('id', ''))
		var call: String = _branch_call(_save_data, _action, key, _state)

		# 'pass' means no transition is taken, so there is no edge to flash
		if call != 'pass':
			var trace: String = _transition_trace(_save_data, _action, key, _state)
			if not trace.is_empty():
				call = trace + '\n' + call

		body = HenVirtualCNodeCode._inject_placeholder(body, key, call)

	return body


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
		if (_save_data.sub_states[parent_id] as Array).has(_state):
			return find_state(_save_data, StringName(str(parent_id)))

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

	var script_id: StringName = branch_script_id(_save_data, _action, _key)

	if script_id.is_empty():
		return find_state(_save_data, (branch as Dictionary).get('state_id', &''))

	return find_state_in_script(script_id, (branch as Dictionary).get('state_id', &''))


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


static func _has_branch_target(_save_data: HenSaveData, _action: HenSaveAction, _branches: Array) -> bool:
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

		if _action.input_expressions.has(key):
			return name

		var bind: String = HenUtils.bind_expression(_save_data, _action.input_bindings.get(key, ''))

		if bind.is_empty():
			# an optional target is simply left out of the emitted code
			if bool(input.get('optional', false)):
				continue

			return name

		if is_lvalue and bind.contains('('):
			return name

	return ''


# name of the first branch that targets another script without an instance source
static func _first_unbound_cross_branch(_save_data: HenSaveData, _action: HenSaveAction, _branches: Array) -> String:
	for out: Dictionary in _branches:
		var key: String = str(out.get('id', ''))

		if branch_script_id(_save_data, _action, key).is_empty():
			continue

		if branch_instance_ref(_save_data, _action, key).is_empty():
			return str(out.get('name', key))

	return ''


static func _resolve_macro(_macro_id: StringName) -> HenSaveMacro:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	for macro: HenSaveMacro in global.action_macros:
		if macro.id == _macro_id:
			return macro

	for macro: HenSaveMacro in global.script_macros:
		if macro.id == _macro_id:
			return macro

	return null


static func _load_instance(_macro: HenSaveMacro) -> HenScriptMacroBase:
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
		var parsed: Dictionary = HenVirtualCNodeCode.parse_script_function(source, callable_body.get_method())
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

		# priority: expression > binding > literal
		if _action.input_expressions.has(key):
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
					literal = HenVirtualCNodeCode.get_default_value_code(_save_data, effective_type(_save_data, _action, input), false, '', null, value)

		body = HenVirtualCNodeCode._inject_placeholder(body, key, literal)

	return body


# an input's effective type: follows type_from to whatever another slot is bound
# to. type_from may name an input OR an output (a producer's inputs follow the
# type of the variable its result is stored in)
static func effective_type(_save_data: HenSaveData, _action: HenSaveAction, _input: Dictionary) -> String:
	var declared: String = _input.get('type', 'Variant')
	var type_from: String = str(_input.get('type_from', ''))

	if type_from.is_empty():
		return declared

	var bind: String = str(_action.input_bindings.get(type_from, _action.output_bindings.get(type_from, '')))
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
	var out: String = _code

	for i: int in range(matches.size() - 1, -1, -1):
		var m: RegExMatch = matches[i]
		var w: String = m.get_string()
		if _vals.has(w):
			out = out.substr(0, m.get_start()) + str(_vals[w]) + out.substr(m.get_end())

	return out


static func _unresolved_token(_action: HenSaveAction, _reason: String) -> String:
	push_warning('hengo: action ' + str(_action.macro_id) + ' (' + str(_action.id) + ') unresolved: ' + _reason)
	return '# hengo: action ' + str(_action.macro_id) + ' (' + str(_action.id) + ') unresolved: ' + _reason
