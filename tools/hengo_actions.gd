@tool
class_name HenHengoActions extends RefCounted

# builds a hengo script from a high-level json using actions only: variables,
# states (and sub-states) and one linear action list per state. an action is
# referenced by the id its macro declares (HenScriptMacroBase.get_id), never
# redeclared. every function returns '' on success or an error message.

# declare() runs for all scripts before any build_actions() call, so a branch
# pointing at another script finds its states whatever order the json lists them

# collection and debug ride along when the json holds a single script
const SCRIPT_KEYS: PackedStringArray = ['name', 'extends', 'vars', 'states', 'functions', 'macros', 'collection', 'debug']
const VAR_KEYS: PackedStringArray = ['name', 'type', 'value', 'export']
const STATE_KEYS: PackedStringArray = ['name', 'start', 'can_reenter', 'description', 'actions', 'sub_states', 'uses']
const ACTION_KEYS: PackedStringArray = ['id', 'phase', 'inputs', 'branches', 'body', 'ref']
const FUNCTION_KEYS: PackedStringArray = ['name', 'description', 'inputs', 'outputs', 'ways_out', 'actions']
const MACRO_KEYS: PackedStringArray = ['name', 'description', 'inputs', 'hooks', 'ways_out', 'states']
const USE_KEYS: PackedStringArray = ['macro', 'name', 'start', 'inputs', 'ways_out', 'steps']
const PARAM_KEYS: PackedStringArray = ['name', 'type', 'value', 'doc']

# the definition being built, so a step inside it can name the inputs and the ways
# out of whatever holds it
static var _scope_def: HenSaveResType = null

# ref given in the json -> the action built for it, so a wire can point at a step
# declared earlier. cleared per script, since a wire never crosses one
static var _refs: Dictionary = {}


static func declare(_save_data: HenSaveData, _spec: Dictionary) -> String:
	var unknown: String = _unknown_keys(_spec, SCRIPT_KEYS, 'script')

	if not unknown.is_empty():
		return unknown

	for v: Dictionary in _spec.get('vars', []):
		var err: String = _declare_var(_save_data, v)
		if not err.is_empty():
			return err

	# the definitions come first: a state may use a macro and an action may call a
	# function, whatever order the json lists them in
	for f: Dictionary in _spec.get('functions', []):
		var func_err: String = _declare_function(_save_data, f)
		if not func_err.is_empty():
			return func_err

	for m: Dictionary in _spec.get('macros', []):
		var macro_err: String = _declare_macro(_save_data, m)
		if not macro_err.is_empty():
			return macro_err

	for st: Dictionary in _spec.get('states', []):
		var err: String = _declare_state(_save_data, st)
		if not err.is_empty():
			return err

	return ''


# a definition is named in the json, and its params carry readable ids so a step
# can name them: prefixing with the owner keeps two definitions apart
static func param_id(_owner: String, _name: String) -> StringName:
	return StringName(_owner.to_snake_case() + '_' + _name.to_snake_case())


static func _declare_function(_save_data: HenSaveData, _spec: Dictionary) -> String:
	var name: String = str(_spec.get('name', ''))
	var unknown: String = _unknown_keys(_spec, FUNCTION_KEYS, 'function "' + name + '"')

	if not unknown.is_empty():
		return unknown

	if name.is_empty():
		return 'function without a name'

	if find_function(_save_data, name):
		return 'duplicated function "' + name + '"'

	var func_res: HenSaveFunc = _save_data.add_function()

	func_res.name = name
	func_res.description = str(_spec.get('description', ''))

	for param_spec: Dictionary in _spec.get('inputs', []):
		var param: Variant = _make_param(name, param_spec)

		if param is String:
			return 'function "' + name + '": ' + str(param)

		func_res.inputs.append(param)

	for param_spec: Dictionary in _spec.get('outputs', []):
		var param: Variant = _make_param(name, param_spec)

		if param is String:
			return 'function "' + name + '": ' + str(param)

		func_res.outputs.append(param)

	for way: Dictionary in _spec.get('ways_out', []):
		func_res.flow_outputs.append(_make_way_out(name, way))

	return ''


static func _declare_macro(_save_data: HenSaveData, _spec: Dictionary) -> String:
	var name: String = str(_spec.get('name', ''))
	var unknown: String = _unknown_keys(_spec, MACRO_KEYS, 'macro "' + name + '"')

	if not unknown.is_empty():
		return unknown

	if name.is_empty():
		return 'macro without a name'

	if find_macro_def(_save_data, name):
		return 'duplicated macro "' + name + '"'

	var macro: HenSaveStateMacro = HenSaveStateMacro.create(_save_data)

	macro.name = name
	macro.description = str(_spec.get('description', ''))
	_save_data.macros.append(macro)

	for param_spec: Dictionary in _spec.get('inputs', []):
		var param: Variant = _make_param(name, param_spec)

		if param is String:
			return 'macro "' + name + '": ' + str(param)

		macro.inputs.append(param)

	for hook: Dictionary in _spec.get('hooks', []):
		macro.flow_inputs.append(_make_way_out(name, hook))

	for way: Dictionary in _spec.get('ways_out', []):
		macro.flow_outputs.append(_make_way_out(name, way))

	var states: Array = _spec.get('states', [])

	if states.is_empty():
		return 'macro "' + name + '" has no state'

	for state_spec: Dictionary in states:
		var err: String = _declare_macro_state(_save_data, macro, state_spec)

		if not err.is_empty():
			return err

	if not macro.get_start_state(_save_data):
		(macro.get_states(_save_data)[0] as HenSaveState).start = true

	return ''


static func _declare_macro_state(_save_data: HenSaveData, _macro: HenSaveStateMacro, _spec: Dictionary) -> String:
	var name: String = str(_spec.get('name', ''))
	var unknown: String = _unknown_keys(_spec, STATE_KEYS, 'state "' + name + '"')

	if not unknown.is_empty():
		return unknown

	if name.is_empty():
		return 'state of macro "' + _macro.name + '" without a name'

	if find_state(_save_data, name):
		return 'duplicated state "' + name + '"'

	var state: HenSaveState = _macro.add_state(_save_data)

	state.name = name
	state.description = str(_spec.get('description', ''))
	state.can_reenter = bool(_spec.get('can_reenter', false))

	if bool(_spec.get('start', false)):
		state.start = true

	for sub: Dictionary in _spec.get('sub_states', []):
		var err: String = _declare_sub_state(_save_data, state, sub)

		if not err.is_empty():
			return err

	return _declare_uses(_save_data, state, _spec)


static func _make_param(_owner: String, _spec: Dictionary) -> Variant:
	var name: String = str(_spec.get('name', ''))
	var unknown: String = _unknown_keys(_spec, PARAM_KEYS, 'param "' + name + '"')

	if not unknown.is_empty():
		return unknown

	if name.is_empty():
		return 'param without a name'

	var param: HenSaveParam = HenSaveParam.create({
		id = param_id(_owner, name),
		name = name,
		type = StringName(str(_spec.get('type', 'Variant'))),
		doc = str(_spec.get('doc', ''))
	})

	if _spec.has('value'):
		param.default_value = _coerce(_spec.value, param.type)

	return param


static func _make_way_out(_owner: String, _spec: Dictionary) -> HenSaveFlowParam:
	var name: String = str(_spec.get('name', ''))

	return HenSaveFlowParam.create({
		id = param_id(_owner, name),
		name = name,
		doc = str(_spec.get('doc', ''))
	})


static func find_function(_save_data: HenSaveData, _name: String) -> HenSaveFunc:
	for f: HenSaveFunc in _save_data.functions:
		if f.name == _name:
			return f

	return null


static func find_macro_def(_save_data: HenSaveData, _name: String) -> HenSaveStateMacro:
	for macro: HenSaveStateMacro in _save_data.macros:
		if macro.name == _name:
			return macro

	return null


static func _declare_var(_save_data: HenSaveData, _spec: Dictionary) -> String:
	var name: String = str(_spec.get('name', '')).to_snake_case()
	var unknown: String = _unknown_keys(_spec, VAR_KEYS, 'var "' + name + '"')

	if not unknown.is_empty():
		return unknown

	if name.is_empty():
		return 'var without a name'

	if find_var(_save_data, name):
		return 'duplicated var "' + name + '"'

	var v: HenSaveVar = _save_data.add_var(false)
	v.name = name
	v.type = StringName(str(_spec.get('type', 'Variant')))
	v.is_export = bool(_spec.get('export', false))

	if _spec.has('value'):
		v.default_value = _coerce(_spec.value, v.type)

	return ''


static func _declare_state(_save_data: HenSaveData, _spec: Dictionary) -> String:
	var name: String = str(_spec.get('name', ''))
	var unknown: String = _unknown_keys(_spec, STATE_KEYS, 'state "' + name + '"')

	if not unknown.is_empty():
		return unknown

	if name.is_empty():
		return 'state without a name'

	if find_state(_save_data, name):
		return 'duplicated state "' + name + '"'

	var state: HenSaveState = _save_data.add_state(false)
	state.name = name
	state.description = str(_spec.get('description', ''))
	state.can_reenter = bool(_spec.get('can_reenter', false))

	if bool(_spec.get('start', false)):
		state.start = true

	for sub: Dictionary in _spec.get('sub_states', []):
		var err: String = _declare_sub_state(_save_data, state, sub)
		if not err.is_empty():
			return err

	return _declare_uses(_save_data, state, _spec)


# a use is structure, so it is created here: a branch of any state can name it
# before the build fills in its values
static func _declare_uses(_save_data: HenSaveData, _state: HenSaveState, _spec: Dictionary) -> String:
	var index: int = 0

	for use_spec: Dictionary in _spec.get('uses', []):
		var unknown: String = _unknown_keys(use_spec, USE_KEYS, 'use #' + str(index) + ' of "' + _state.name + '"')

		if not unknown.is_empty():
			return unknown

		var macro: HenSaveStateMacro = find_macro_def(_save_data, str(use_spec.get('macro', '')))

		if not macro:
			return 'unknown macro "' + str(use_spec.get('macro', '')) + '"'

		var name: String = str(use_spec.get('name', macro.name))

		if find_state(_save_data, name):
			return 'duplicated state "' + name + '"'

		var use: HenSaveState = HenSaveState.create_macro_use(macro, _save_data)

		use.name = name

		if not _save_data.sub_states.has(_state.id):
			_save_data.sub_states[_state.id] = []

		var siblings: Array = _save_data.sub_states[_state.id]

		siblings.append(use)

		if bool(use_spec.get('start', false)) or siblings.size() == 1:
			use.start = true

		index += 1

	return ''


static func _declare_sub_state(_save_data: HenSaveData, _parent: HenSaveState, _spec: Dictionary) -> String:
	var name: String = str(_spec.get('name', ''))
	var unknown: String = _unknown_keys(_spec, STATE_KEYS, 'sub state "' + name + '"')

	if not unknown.is_empty():
		return unknown

	if name.is_empty():
		return 'sub state of "' + _parent.name + '" without a name'

	if find_state(_save_data, name):
		return 'duplicated state "' + name + '"'

	_parent.add_sub_state(_save_data)

	var siblings: Array = _parent.get_sub_states(_save_data)
	var state: HenSaveState = siblings[siblings.size() - 1]
	state.name = name
	state.description = str(_spec.get('description', ''))
	state.can_reenter = bool(_spec.get('can_reenter', false))

	if bool(_spec.get('start', false)):
		state.start = true

	for sub: Dictionary in _spec.get('sub_states', []):
		var err: String = _declare_sub_state(_save_data, state, sub)

		if not err.is_empty():
			return err

	return _declare_uses(_save_data, state, _spec)


# fills the action list of every state; declare() must have run for all scripts
static func build_actions(_save_data: HenSaveData, _spec: Dictionary, _all_scripts: Dictionary = {}) -> String:
	_refs.clear()
	_scope_def = null

	for f: Dictionary in _spec.get('functions', []):
		var func_err: String = _build_function(_save_data, f, _all_scripts)

		if not func_err.is_empty():
			return func_err

	for m: Dictionary in _spec.get('macros', []):
		var macro_err: String = _build_macro(_save_data, m, _all_scripts)

		if not macro_err.is_empty():
			return macro_err

	for st: Dictionary in _spec.get('states', []):
		var err: String = _build_state_tree(_save_data, st, _all_scripts)

		if not err.is_empty():
			return err

	return ''


# the body of a function is an action list like a state's, held under its own id
static func _build_function(_save_data: HenSaveData, _spec: Dictionary, _all_scripts: Dictionary) -> String:
	var func_res: HenSaveFunc = find_function(_save_data, str(_spec.get('name', '')))

	if not func_res:
		return 'function "' + str(_spec.get('name', '')) + '" was not declared'

	_scope_def = func_res

	var scope: HenSaveState = func_res.scope_state()
	var index: int = 0

	for action_spec: Dictionary in _spec.get('actions', []):
		var built: Variant = _make_action(_save_data, scope, action_spec, _all_scripts)

		if built is String:
			_scope_def = null
			return 'function "' + func_res.name + '" action #' + str(index) + ': ' + str(built)

		_save_data.add_state_action(scope.id, built)
		index += 1

	_scope_def = null

	return ''


static func _build_macro(_save_data: HenSaveData, _spec: Dictionary, _all_scripts: Dictionary) -> String:
	var macro: HenSaveStateMacro = find_macro_def(_save_data, str(_spec.get('name', '')))

	if not macro:
		return 'macro "' + str(_spec.get('name', '')) + '" was not declared'

	_scope_def = macro

	for state_spec: Dictionary in _spec.get('states', []):
		var err: String = _build_state_tree(_save_data, state_spec, _all_scripts)

		if not err.is_empty():
			_scope_def = null
			return 'macro "' + macro.name + '": ' + err

	_scope_def = null

	return ''


# a use runs the machine of a macro inside the state that holds it, with values
# and ways out of its own
static func _build_use(_save_data: HenSaveData, _parent: HenSaveState, _spec: Dictionary, _index: int, _all_scripts: Dictionary = {}) -> String:
	var macro: HenSaveStateMacro = find_macro_def(_save_data, str(_spec.get('macro', '')))

	if not macro:
		return 'unknown macro "' + str(_spec.get('macro', '')) + '"'

	var use: HenSaveState = find_state(_save_data, str(_spec.get('name', macro.name)))

	if not use or not use.is_macro_use():
		return 'use "' + str(_spec.get('name', macro.name)) + '" was not declared'

	for raw_key: Variant in _spec.get('inputs', {}):
		var input_name: String = str(raw_key)
		var declared: HenSaveParam = _definition_param(macro, input_name)

		if not declared:
			return 'macro "' + macro.name + '" has no input "' + input_name + '"'

		var value: Variant = (_spec.inputs as Dictionary)[raw_key]

		if value is Dictionary:
			var bind: Dictionary = _bind_code(_save_data, value as Dictionary)

			if bind.has('error'):
				return 'use of "' + macro.name + '", input "' + input_name + '": ' + str(bind.error)

			use.macro_bindings[str(declared.id)] = bind.code
			continue

		for param: HenSaveParam in use.macro_inputs:
			if str(param.id) == str(declared.id):
				param.default_value = _coerce(value, param.type)

	for raw_key: Variant in _spec.get('steps', {}):
		var slot: String = str(raw_key)
		var flow: HenSaveFlowParam = _definition_way_out_or_hook(macro, slot)
		var phase: StringName = StringName(str(flow.id)) if flow else StringName(slot)

		if not flow and not HenSaveAction.PHASE_ORDER.has(phase):
			return 'macro "' + macro.name + '" has no place "' + slot + '"'

		var index: int = 0

		for action_spec: Dictionary in (_spec.steps as Dictionary)[raw_key]:
			var built: Variant = _make_action(_save_data, use, action_spec, _all_scripts, false)

			if built is String:
				return 'use "' + use.name + '", ' + slot + ' #' + str(index) + ': ' + str(built)

			(built as HenSaveAction).phase = phase
			_save_data.add_state_action(use.id, built)
			index += 1

	for raw_key: Variant in _spec.get('ways_out', {}):
		var way_name: String = str(raw_key)
		var flow: HenSaveFlowParam = _definition_way_out(macro, way_name)

		if not flow:
			return 'macro "' + macro.name + '" has no way out "' + way_name + '"'

		var target: HenSaveState = find_state(_save_data, str((_spec.ways_out as Dictionary)[raw_key]))

		if not target:
			return 'unknown state "' + str((_spec.ways_out as Dictionary)[raw_key]) + '" for way out "' + way_name + '"'

		use.flow_targets[str(flow.id)] = {state_id = target.id, label = way_name}

	return ''


static func _definition_param(_definition: HenSaveResType, _name: String) -> HenSaveParam:
	var params: Array[HenSaveParam] = []

	if _definition is HenSaveFunc:
		params = (_definition as HenSaveFunc).inputs
	elif _definition is HenSaveStateMacro:
		params = (_definition as HenSaveStateMacro).inputs

	for param: HenSaveParam in params:
		if param.name == _name or str(param.id) == _name:
			return param

	return null


static func _definition_way_out(_definition: HenSaveResType, _name: String) -> HenSaveFlowParam:
	var flows: Array[HenSaveFlowParam] = []

	if _definition is HenSaveFunc:
		flows = (_definition as HenSaveFunc).flow_outputs
	elif _definition is HenSaveStateMacro:
		flows = (_definition as HenSaveStateMacro).flow_outputs

	for flow: HenSaveFlowParam in flows:
		if flow.name == _name or str(flow.id) == _name:
			return flow

	return null


static func _build_state_tree(_save_data: HenSaveData, _spec: Dictionary, _all_scripts: Dictionary) -> String:
	var err: String = _build_state_actions(_save_data, _spec, _all_scripts)

	if not err.is_empty():
		return err

	for sub: Dictionary in _spec.get('sub_states', []):
		var sub_err: String = _build_state_tree(_save_data, sub, _all_scripts)

		if not sub_err.is_empty():
			return sub_err

	return ''


static func _build_state_actions(_save_data: HenSaveData, _spec: Dictionary, _all_scripts: Dictionary) -> String:
	var state: HenSaveState = find_state(_save_data, str(_spec.get('name', '')))

	if not state:
		return 'state "' + str(_spec.get('name', '')) + '" was not declared'

	var index: int = 0

	for action_spec: Dictionary in _spec.get('actions', []):
		var err: String = _build_action(_save_data, state, action_spec, _all_scripts)

		if not err.is_empty():
			return 'state "' + state.name + '" action #' + str(index) + ': ' + err

		index += 1

	var use_index: int = 0

	for use_spec: Dictionary in _spec.get('uses', []):
		var use_err: String = _build_use(_save_data, state, use_spec, use_index, _all_scripts)

		if not use_err.is_empty():
			return 'state "' + state.name + '": ' + use_err

		use_index += 1

	return ''


static func _build_action(_save_data: HenSaveData, _state: HenSaveState, _spec: Dictionary, _all_scripts: Dictionary) -> String:
	var built: Variant = _make_action(_save_data, _state, _spec, _all_scripts)

	if built is String:
		return built

	_save_data.add_state_action(_state.id, built)

	return ''


# builds an action (and its nested body, recursively) without attaching it to a
# state. returns the HenSaveAction, or an error String. a nested action runs at
# the loop's phase, so its own phase is ignored
static func _make_action(_save_data: HenSaveData, _state: HenSaveState, _spec: Dictionary, _all_scripts: Dictionary, _nested: bool = false) -> Variant:
	var unknown: String = _unknown_keys(_spec, ACTION_KEYS, '')

	if not unknown.is_empty():
		return unknown

	var id: StringName = StringName(str(_spec.get('id', '')))
	var macro: HenSaveMacro = _resolve_macro(_save_data, id)

	if not macro:
		return 'unknown action id "' + str(id) + '"' + _id_hint(str(id))

	var script_class: StringName = _save_data.identity.type if _save_data.identity else &''

	if not macro.serves_class(script_class):
		return 'action "' + str(id) + '" does not serve ' + str(script_class) + ' (targets: ' + ', '.join(macro.target_classes) + ')'

	var action: HenSaveAction = HenSaveAction.create(macro)

	# a nested action inherits the loop's phase, so it keeps the macro default
	if not _nested:
		var phase_err: String = _apply_phase(action, macro, _spec)

		if not phase_err.is_empty():
			return phase_err

	var input_err: String = _apply_inputs(_save_data, _state, action, macro, _spec.get('inputs', {}), _all_scripts)

	if not input_err.is_empty():
		return input_err

	if _spec.has('ref'):
		var ref: String = str(_spec.ref)

		if _refs.has(ref):
			return 'duplicated ref "' + ref + '"'

		_refs[ref] = action

	var branch_err: String = _apply_branches(_save_data, _state, action, macro, _spec.get('branches', {}), _all_scripts)

	if not branch_err.is_empty():
		return branch_err

	var body_err: String = _apply_body(_save_data, _state, action, macro, _spec.get('body', []), _all_scripts)

	if not body_err.is_empty():
		return body_err

	return action


# nested actions of a loop; only a macro that declares a body accepts them
static func _apply_body(_save_data: HenSaveData, _state: HenSaveState, _action: HenSaveAction, _macro: HenSaveMacro, _body: Array, _all_scripts: Dictionary) -> String:
	if _body.is_empty():
		return ''

	if not _macro.has_body:
		return 'action "' + str(_macro.id) + '" has no body to hold nested actions'

	var index: int = 0

	for child_spec: Dictionary in _body:
		var built: Variant = _make_action(_save_data, _state, child_spec, _all_scripts, true)

		if built is String:
			return 'body #' + str(index) + ': ' + str(built)

		_action.body_actions.append(built)
		index += 1

	return ''


static func _apply_phase(_action: HenSaveAction, _macro: HenSaveMacro, _spec: Dictionary) -> String:
	var supported: Array = HenSaveAction.supported_phases(_macro)

	if not _spec.has('phase'):
		_action.phase = HenSaveAction.default_phase(_macro)
		return ''

	var phase: StringName = StringName(str(_spec.phase))

	if not supported.has(phase):
		return 'phase "' + str(phase) + '" is not supported (supported: ' + _join(supported) + ')'

	_action.phase = phase

	return ''


# sources are applied first so a literal on a type_from input knows its real type
static func _apply_inputs(_save_data: HenSaveData, _state: HenSaveState, _action: HenSaveAction, _macro: HenSaveMacro, _inputs: Dictionary, _all_scripts: Dictionary) -> String:
	var literals: Dictionary = {}

	for raw_key: Variant in _inputs:
		var declared: HenSaveParam = _macro_input(_macro, str(raw_key))

		if not declared:
			return 'input "' + str(raw_key) + '" is not declared (valid: ' + _input_ids(_macro) + ')'

		# the json may name a slot, and everything downstream stores it by id
		var key: String = str(declared.id)

		var value: Variant = _inputs[raw_key]

		if not value is Dictionary:
			literals[key] = {value = value, declared = declared}
			continue

		var err: String = _apply_input_source(_save_data, _state, _action, key, value as Dictionary, declared, _all_scripts)

		if not err.is_empty():
			return err

	for key: String in literals:
		var literal_err: String = _set_literal(_save_data, _action, key, literals[key].value, literals[key].declared)

		if not literal_err.is_empty():
			return literal_err

	return ''


static func _apply_input_source(_save_data: HenSaveData, _state: HenSaveState, _action: HenSaveAction, _key: String, _source: Dictionary, _declared: HenSaveParam, _all_scripts: Dictionary) -> String:
	if _source.has('wire'):
		return _apply_wire(_action, _key, _source.wire, _declared)

	if _source.has('action'):
		return _apply_inline_action(_save_data, _state, _action, _key, _source, _declared, _all_scripts)

	if _source.has('expr'):
		var expr: Variant = _build_expression(_save_data, _source)

		if expr is String:
			return 'input "' + _key + '": ' + (expr as String)

		_action.input_expressions[_key] = expr
		return ''

	var bind: Dictionary = _bind_code(_save_data, _source)

	if bind.has('error'):
		return 'input "' + _key + '": ' + str(bind.error)

	_action.input_bindings[_key] = bind.code

	return ''


# source shape: { wire: { from: 'ref', output: 'x' } }
static func _apply_wire(_action: HenSaveAction, _key: String, _wire: Variant, _declared: HenSaveParam) -> String:
	if _declared.lvalue:
		return 'input "' + _key + '": a wire cannot be the left side of an assignment'

	if not _wire is Dictionary:
		return 'input "' + _key + '": "wire" must be { from, output }'

	var spec: Dictionary = _wire as Dictionary
	var from: String = str(spec.get('from', ''))

	if not _refs.has(from):
		return 'input "' + _key + '": unknown ref "' + from + '", a wire only reaches a step declared before it'

	var producer: HenSaveAction = _refs[from]
	var macro: HenSaveMacro = find_macro(producer.macro_id)
	var output: String = str(spec.get('output', ''))

	if not _macro_output(macro, output):
		return 'input "' + _key + '": output "' + output + '" is not declared on "' + from + '" (valid: ' + _output_ids(macro) + ')'

	_action.input_wires[_key] = {action_id = StringName(str(producer.id)), output = StringName(output)}

	return ''


# source shape: { action: {id, inputs}, output: 'x' }, output defaults to the sole one
static func _apply_inline_action(_save_data: HenSaveData, _state: HenSaveState, _action: HenSaveAction, _key: String, _source: Dictionary, _declared: HenSaveParam, _all_scripts: Dictionary) -> String:
	if _declared.lvalue or _declared.bind_only:
		return 'input "' + _key + '": an inline action cannot feed a slot that needs a variable'

	if not _source.action is Dictionary:
		return 'input "' + _key + '": "action" must be an action spec {id, inputs}'

	var built: Variant = _make_action(_save_data, _state, _source.action as Dictionary, _all_scripts, true)

	if built is String:
		return 'input "' + _key + '" inline action: ' + str(built)

	var child: HenSaveAction = built as HenSaveAction
	var instance: HenScriptMacroBase = HenGeneratorAction._load_instance(find_macro(child.macro_id))

	if not instance or not HenGeneratorAction.is_inlinable(instance):
		return 'input "' + _key + '": action "' + str(child.macro_id) + '" is not an inlinable value producer'

	var output_id: String = str(_source.get('output', ''))

	if output_id.is_empty():
		var outputs: Array = instance.get_outputs()
		output_id = str(outputs[0].get('id', '')) if not outputs.is_empty() else ''

	if not _instance_has_output(instance, output_id):
		return 'input "' + _key + '": "' + output_id + '" is not an output of "' + str(child.macro_id) + '" (valid: ' + _instance_output_ids(instance) + ')'

	_action.input_actions[_key] = {action = child, output = StringName(output_id)}

	return ''


static func _instance_has_output(_instance: HenScriptMacroBase, _id: String) -> bool:
	for output: Dictionary in _instance.get_outputs():
		if str(output.get('id', '')) == _id:
			return true

	return false


static func _instance_output_ids(_instance: HenScriptMacroBase) -> String:
	var ids: PackedStringArray = []

	for output: Dictionary in _instance.get_outputs():
		ids.append(str(output.get('id', '')))

	return ', '.join(ids) if not ids.is_empty() else '(none)'


# {code} of a source wrapper, or {error} when it can't be resolved
static func _bind_code(_save_data: HenSaveData, _source: Dictionary) -> Dictionary:
	if _source.has('bind'):
		var name: String = str(_source.bind).to_snake_case()
		var variable: HenSaveVar = find_var(_save_data, name)

		if not variable:
			return {error = 'unknown var "' + name + '"'}

		return {code = HenUtils.bind_code_for_var(variable)}

	if _source.has('path'):
		return {code = HenUtils.BIND_PATH_PREFIX + str(_source.path)}

	if _source.has('arg'):
		var param: HenSaveParam = _definition_param(_scope_def, str(_source.arg))

		if not param:
			return {error = 'no input "' + str(_source.arg) + '" in the definition being built'}

		return {code = HenUtils.bind_code_for_arg(param)}

	if _source.has('native'):
		var native: String = _native_code(str(_source.native))

		if native.is_empty():
			return {error = 'unknown native source "' + str(_source.native) + '"'}

		var refused: String = _native_class_error(_save_data, str(_source.native))

		if not refused.is_empty():
			return {error = refused}

		return {code = native}

	if _source.has('prop'):
		return {code = str(_source.prop)}

	return {error = 'expected one of bind, path, native, prop, expr'}


# free-text expression: each word is bound to a source or holds a raw code fragment
static func _build_expression(_save_data: HenSaveData, _source: Dictionary) -> Variant:
	var expr: HenSaveActionExpression = HenSaveActionExpression.new()
	expr.code = str(_source.expr)

	var words: Array[HenSaveParam] = []

	for raw_name: Variant in _source.get('words', {}):
		var name: String = str(raw_name)
		var value: Variant = (_source.words as Dictionary)[raw_name]
		var param: HenSaveParam = HenSaveParam.create({name = name, type = 'Variant'})

		if value is Dictionary:
			var bind: Dictionary = _bind_code(_save_data, value as Dictionary)

			if bind.has('error'):
				return 'word "' + name + '": ' + str(bind.error)

			expr.word_bindings[name] = bind.code
		else:
			param.default_value = str(value)

		words.append(param)

	expr.words = words

	return expr


# "actions" holds the steps a branch runs before its transition
static func _apply_branches(_save_data: HenSaveData, _state: HenSaveState, _action: HenSaveAction, _macro: HenSaveMacro, _branches: Dictionary, _all_scripts: Dictionary) -> String:
	for raw_key: Variant in _branches:
		var declared: HenSaveFlowParam = _macro_flow_output(_macro, str(raw_key))

		if not declared:
			return 'branch "' + str(raw_key) + '" is not a flow output (valid: ' + _flow_output_ids(_macro) + ')'

		var key: String = str(declared.id)

		var spec: Variant = _branches[raw_key]

		if spec is Dictionary and (spec as Dictionary).has('actions'):
			var dict: Dictionary = spec as Dictionary
			var steps: Variant = _build_branch_steps(_save_data, _state, dict.actions, _all_scripts)

			if steps is String:
				return 'branch "' + key + '": ' + str(steps)

			if dict.has('state') or dict.has('script'):
				return 'branch "' + key + '": a branch goes to a state or it runs steps, never both. end the steps with a "transition" action instead'

			_action.branch_actions[key] = steps

			continue

		var branch: Variant = _build_branch(_save_data, spec, _all_scripts)

		if not branch is Dictionary:
			return 'branch "' + key + '": ' + str(branch)

		_action.branches[key] = branch

	return ''


# steps of a branch run at the phase of the action that owns it, so they are built
# nested and their own phase is ignored
static func _build_branch_steps(_save_data: HenSaveData, _state: HenSaveState, _steps: Variant, _all_scripts: Dictionary) -> Variant:
	if not _steps is Array:
		return '"actions" needs an array of steps'

	var list: Array[HenSaveAction] = []
	var index: int = 0

	for step_spec: Variant in _steps as Array:
		if not step_spec is Dictionary:
			return 'step #' + str(index) + ': needs an action object'

		var built: Variant = _make_action(_save_data, _state, step_spec as Dictionary, _all_scripts, true)

		if built is String:
			return 'step #' + str(index) + ': ' + str(built)

		list.append(built)
		index += 1

	return list


# a plain string targets a state of this script; a dict may target another one
static func _build_branch(_save_data: HenSaveData, _target: Variant, _all_scripts: Dictionary) -> Variant:
	if not _target is Dictionary:
		var local: HenSaveState = find_state(_save_data, str(_target))

		if not local:
			return 'unknown state "' + str(_target) + '"'

		return {state_id = local.id, script_id = &'', label = ''}

	var spec: Dictionary = _target as Dictionary

	if spec.has('way_out'):
		var flow: HenSaveFlowParam = _definition_way_out(_scope_def, str(spec.way_out))

		if not flow:
			return 'no way out "' + str(spec.way_out) + '" in the definition being built'

		return {exit_id = str(flow.id), label = str(spec.get('label', spec.way_out))}

	if not spec.has('script'):
		var same: HenSaveState = find_state(_save_data, str(spec.get('state', '')))

		if not same:
			return 'unknown state "' + str(spec.get('state', '')) + '"'

		return {state_id = same.id, script_id = &'', label = str(spec.get('label', ''))}

	return _build_cross_branch(_save_data, spec, _all_scripts)


static func _build_cross_branch(_save_data: HenSaveData, _spec: Dictionary, _all_scripts: Dictionary) -> Variant:
	var script_name: String = str(_spec.script).to_snake_case()

	if not _all_scripts.has(script_name):
		return 'unknown script "' + script_name + '"'

	var other: HenSaveData = _all_scripts[script_name]
	var target: HenSaveState = find_state(other, str(_spec.get('state', '')))

	if not target:
		return 'state "' + str(_spec.get('state', '')) + '" not found in ' + script_name

	var branch: Dictionary = {
		state_id = target.id,
		script_id = other.identity.id,
		label = str(_spec.get('label', '')),
		check_instance = bool(_spec.get('check_instance', false))
	}

	# without an instance there is nothing to call change_state on
	if _spec.has('instance'):
		var variable: HenSaveVar = find_var(_save_data, str(_spec.instance).to_snake_case())

		if not variable:
			return 'unknown var "' + str(_spec.instance) + '" as instance'

		branch.instance_bind = HenUtils.bind_code_for_var(variable)
	elif _spec.has('path'):
		branch.instance_path = str(_spec.path)
	else:
		return 'a cross-script branch needs an instance or a path'

	_save_data.add_dep(other.identity.id)

	return branch


# "fn:<name>" calls a function of this script and "finish:<name>" ends one; every
# other id names an action of the pool
static func _resolve_macro(_save_data: HenSaveData, _id: StringName) -> HenSaveMacro:
	var text: String = str(_id)

	for prefix: String in ['fn:', 'finish:']:
		if not text.begins_with(prefix):
			continue

		var func_res: HenSaveFunc = find_function(_save_data, text.substr(prefix.length()))

		return HenFunctionMacro.macro_of(func_res, prefix == 'finish:') if func_res else null

	if text.begins_with('run:'):
		var macro: HenSaveStateMacro = _scope_def as HenSaveStateMacro
		var flow: HenSaveFlowParam = _definition_way_out_or_hook(macro, text.substr(4)) if macro else null

		return HenMacroHookMacro.macro_of(macro, flow) if flow else null

	return find_macro(_id)


# a hook is named like a way out, and only a macro has them
static func _definition_way_out_or_hook(_macro: HenSaveStateMacro, _name: String) -> HenSaveFlowParam:
	for flow: HenSaveFlowParam in _macro.flow_inputs:
		if flow.name == _name or str(flow.id) == _name:
			return flow

	return null


# the effective type follows type_from, so a value on a Variant slot is cast to
# whatever the companion input ended up bound to
static func _set_literal(_save_data: HenSaveData, _action: HenSaveAction, _key: String, _value: Variant, _declared: HenSaveParam) -> String:
	var type: StringName = StringName(HenGeneratorAction.effective_type(_save_data, _action, _declared.get_data()))

	for param: HenSaveParam in _action.inputs:
		if str(param.id) == _key:
			if _declared.raw:
				# a raw value is pasted into the script as it stands, so one outside the
				# declared set only fails at godot parse time
				if not _declared.options.is_empty() and not _declared.options.has(str(_value)):
					return 'input "' + _key + '": "' + str(_value) + '" is not one of ' + ', '.join(_declared.options)

				param.default_value = _value
				return ''

			var coerced: Variant = _coerce(_value, type)
			var wanted: int = HenUtils.get_variant_type_from_string(type)

			# `_ref` is untyped, so a mistyped literal compiles and only breaks at
			# runtime — the parser check downstream would never see it
			if wanted != TYPE_NIL and typeof(coerced) != wanted:
				return 'input "' + _key + '" expects ' + str(type) + ', got ' + type_string(typeof(_value))

			param.default_value = coerced
			return ''

	return ''


# json has no int/vector/color literals, so the declared type drives the cast
static func _coerce(_value: Variant, _type: StringName) -> Variant:
	# json numbers are always floats; a whole one on an untyped slot reads as int
	if str(_type) == 'Variant' and _value is float and is_equal_approx(_value, floorf(_value)):
		return int(_value)

	match str(_type):
		'int':
			return int(_value) if _value is float or _value is int else _value
		'float':
			return float(_value) if _value is float or _value is int else _value
		'bool':
			return bool(_value)
		'String':
			return str(_value)
		'StringName':
			return StringName(str(_value))
		'NodePath':
			return NodePath(str(_value))
		'Color':
			# a hex string, or the rgba array every other vector type uses
			if _value is String:
				return Color(str(_value))

			if _value is Array and (_value as Array).size() >= 3:
				return Color(_value[0], _value[1], _value[2], _value[3] if (_value as Array).size() > 3 else 1.0)

			return _value
		'Vector2':
			return Vector2(_value[0], _value[1]) if _value is Array and (_value as Array).size() >= 2 else _value
		'Vector2i':
			return Vector2i(_value[0], _value[1]) if _value is Array and (_value as Array).size() >= 2 else _value
		'Vector3':
			return Vector3(_value[0], _value[1], _value[2]) if _value is Array and (_value as Array).size() >= 3 else _value
		'Vector3i':
			return Vector3i(_value[0], _value[1], _value[2]) if _value is Array and (_value as Array).size() >= 3 else _value

	return _value


# --- pool -------------------------------------------------------------------


static func find_macro(_id: StringName) -> HenSaveMacro:
	for macro: HenSaveMacro in pool():
		if macro.id == _id:
			return macro

	return null


static func pool() -> Array[HenSaveMacro]:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var all: Array[HenSaveMacro] = []

	if global:
		all.append_array(global.action_macros)
		all.append_array(global.script_macros)

	return all


static func available_ids() -> PackedStringArray:
	var ids: PackedStringArray = []

	for macro: HenSaveMacro in pool():
		ids.append(str(macro.id))

	ids.sort()

	return ids


# closest known id when there is one, plus the whole list to pick from
static func _id_hint(_id: String) -> String:
	var ids: PackedStringArray = available_ids()
	var best: String = ''
	var best_score: float = 0.45

	for id: String in ids:
		var score: float = id.similarity(_id)

		if score > best_score:
			best_score = score
			best = id

	var hint: String = ('; did you mean "' + best + '"?') if not best.is_empty() else ''

	return hint + ' available: ' + ', '.join(ids)


# --- lookup -----------------------------------------------------------------


# a key the schema does not know is a typo or a feature this builder dropped, so
# it is reported instead of silently ignored
static func _unknown_keys(_spec: Dictionary, _allowed: PackedStringArray, _context: String) -> String:
	for raw_key: Variant in _spec:
		var key: String = str(raw_key)

		if _allowed.has(key):
			continue

		var prefix: String = (_context + ': ') if not _context.is_empty() else ''

		return prefix + 'unknown key "' + key + '" (valid: ' + ', '.join(_allowed) + ')'

	return ''


static func find_var(_save_data: HenSaveData, _name: String) -> HenSaveVar:
	for v: HenSaveVar in _save_data.variables:
		if v.name.to_snake_case() == _name:
			return v

	return null


static func find_state(_save_data: HenSaveData, _name: String) -> HenSaveState:
	if _name.is_empty():
		return null

	for state: HenSaveState in _save_data.states:
		if state.name == _name:
			return state

	for sub_list: Variant in _save_data.sub_states.values():
		for state: HenSaveState in sub_list:
			if state.name == _name:
				return state

	return null


# a definition of the script carries ids nobody writes by hand, so its slots also
# answer to the name they were declared with
static func _macro_input(_macro: HenSaveMacro, _key: String) -> HenSaveParam:
	for param: HenSaveParam in _macro.inputs:
		if str(param.id) == _key:
			return param

	for param: HenSaveParam in _macro.inputs:
		if param.name == _key:
			return param

	return null


static func _macro_flow_output(_macro: HenSaveMacro, _key: String) -> HenSaveFlowParam:
	for flow: HenSaveFlowParam in _macro.flow_outputs:
		if str(flow.id) == _key or flow.name == _key:
			return flow

	return null


static func _macro_output(_macro: HenSaveMacro, _key: String) -> HenSaveParam:
	for param: HenSaveParam in _macro.outputs:
		if str(param.id) == _key:
			return param

	return null


# a parameterized source is written as "Action strength:ui_right" in the json and
# stored as its "<key>:<argument>" bind code
# the ui only offers a source the owner can answer, and the cli has to refuse the
# same ones or it writes a property the class does not have
static func _native_class_error(_save_data: HenSaveData, _name: String) -> String:
	var separator: int = _name.find(':')
	var head: String = _name.substr(0, separator) if separator > 0 else _name
	var owner: StringName = _save_data.identity.type if _save_data.identity else &''

	for source: Dictionary in HenUtils.NATIVE_SOURCES:
		if str(source.name) != head and str(source.get('key', '')) != head:
			continue

		var needs: StringName = source.get('needs_class', &'')

		if needs.is_empty() or HenUtils.class_serves(owner, [needs]):
			return ''

		return 'native source "' + str(source.name) + '" needs a ' + str(needs) + ', and this script extends ' + str(owner)

	return ''


static func _native_code(_name: String) -> String:
	var separator: int = _name.find(':')
	var head: String = _name.substr(0, separator) if separator > 0 else _name
	var arg: String = _name.substr(separator + 1).strip_edges() if separator > 0 else ''

	for source: Dictionary in HenUtils.NATIVE_SOURCES:
		if not source.has('key'):
			if str(source.name) == _name or str(source.get('code', '')) == _name:
				return str(source.code)
			continue

		if str(source.name) == head or str(source.key) == head:
			return (str(source.key) + ':' + arg) if not arg.is_empty() else ''

	return ''


static func _input_ids(_macro: HenSaveMacro) -> String:
	var ids: PackedStringArray = []

	for param: HenSaveParam in _macro.inputs:
		ids.append(str(param.id))

	return ', '.join(ids) if not ids.is_empty() else '(none)'


static func _flow_output_ids(_macro: HenSaveMacro) -> String:
	var ids: PackedStringArray = []

	for flow: HenSaveFlowParam in _macro.flow_outputs:
		ids.append(str(flow.id))

	return ', '.join(ids) if not ids.is_empty() else '(none)'


static func _output_ids(_macro: HenSaveMacro) -> String:
	var ids: PackedStringArray = []

	for param: HenSaveParam in _macro.outputs:
		ids.append(str(param.id))

	return ', '.join(ids) if not ids.is_empty() else '(none)'


static func _join(_values: Array) -> String:
	var out: PackedStringArray = []

	for value: Variant in _values:
		out.append(str(value))

	return ', '.join(out)
