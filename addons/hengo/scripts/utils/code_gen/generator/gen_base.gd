class_name HenGeneratorBase extends RefCounted

const TEXT_BASE: String = """var _STATE_CONTROLLER = HengoStateController.new(self)

const _EVENTS = {events}


func _init() -> void:
	_STATE_CONTROLLER.set_states({
{states_dict}
	}){reenterable}


func _ready() -> void:
	if not _STATE_CONTROLLER.current_state:
		_STATE_CONTROLLER.change_state("{start_state_name}"{start_state_data})
{_ready}


func trigger_event(_event: StringName) -> void:
	if _EVENTS.has(_event):
		_STATE_CONTROLLER.change_state(_EVENTS[_event])


func _process(delta: float) -> void:
	_STATE_CONTROLLER.static_process(delta)
{_process}


func _physics_process(delta: float) -> void:
	_STATE_CONTROLLER.static_physics_process(delta)
{_physics_process}
{custom_virtuals}{functions}{states}"""


static func get_base_script_code(_save_data: HenSaveData, _refs: HenTypeReferences) -> String:
	var code: String = ''
	var start_state_ref: HenSaveState
	var events: Array[Dictionary] = []

	# get start state
	for s: HenSaveState in _save_data.states:
		if s.start:
			start_state_ref = s
			break


	# an action may reach script scope too: declarations first, then the virtual
	# overrides it contributes (mouse look needs _input, which a state cannot have)
	var action_scope: Array = HenGeneratorAction.get_script_scope_lines(_save_data)

	# a function has no state class to declare in, so what its steps keep and what
	# it hands back both live here
	action_scope.append_array(HenGeneratorFunction.get_output_var_lines(_save_data))
	action_scope.append_array(HenGeneratorFunction.get_base_lines(_save_data))
	action_scope.append_array(HenGeneratorState.get_macro_input_lines(_save_data))

	if not action_scope.is_empty():
		code += '\n'.join(action_scope) + '\n\n'

	HenGeneratorAction.merge_script_overrides(_save_data, _refs.override_virtual_data)

	var ready_code: Array = []
	var process_code: Array = []
	var physics_process_code: Array = []
	var custom_virtual_code: String = ''

	for key: StringName in _refs.override_virtual_data.keys():
		var item = _refs.override_virtual_data.get(key)

		match key:
			&'_ready':
				ready_code.append_array(_token_lines(_save_data, item.tokens))
			&'_process':
				process_code.append_array(_token_lines(_save_data, item.tokens))
			&'_physics_process':
				physics_process_code.append_array(_token_lines(_save_data, item.tokens))
			_:
				custom_virtual_code += _get_custom_virtual_code(key, item, _save_data)

	var start_state_data: String = ''

	# start state params generation
	if start_state_ref:
		# the args a transition into the start state carries, declared by the state
		var flow_tokens: Array = HenGeneratorAction.get_phase_params(_save_data, start_state_ref, &'enter')

		start_state_data = (', ' if not flow_tokens.is_empty() else '') + ', '.join(flow_tokens.map(func(x: Dictionary) -> String:
			return HenActionCode.get_default_value_code(_save_data, x.type, false, x.get('category', ''), x.get('data', null))))

	return code + TEXT_BASE.format({
		events = ' {\n\t' + ',\n\t'.join(events.map(
			func(ev: Dictionary) -> String:
			return '{event_name}="{to_state_name}"'.format({
				event_name = (ev.name as String).to_snake_case(),
				to_state_name = (ev.to_state_name as String).to_snake_case()
			})
			)) + '\n}' if not events.is_empty() else '{}',
		start_state_name = start_state_ref.name.to_snake_case() if start_state_ref else '',
		start_state_data = start_state_data,
		_ready = ' \n'.join(ready_code),
		_process = '\n'.join(process_code),
		_physics_process = '\n'.join(physics_process_code),
		custom_virtuals = (custom_virtual_code + '\n') if not custom_virtual_code.is_empty() else '',
		functions = HenGeneratorFunction.get_functions_code(_save_data),
		reenterable = HenGeneratorState.get_reenterable_code(_save_data),
		states_dict = HenGeneratorState.get_states_start_code(_save_data),
		states = HenGeneratorState.get_states_code(_save_data)
	})


# body lines of a virtual override. a cnode contributes dictionary tokens, an
# action contributes plain lines already split, one per token
static func _get_custom_virtual_code(_name: StringName, _item: Dictionary, _save_data: HenSaveData) -> String:
	var params: Array = _item.get('params', [])
	var params_str: String = ', '.join(params.map(func(p: Dictionary) -> String:
		return '{name}: {type}'.format({name = p.name, type = p.type})
	))
	
	var body: String = '\n'.join(_token_lines(_save_data, _item.tokens))

	if body.is_empty():
		body = '\tpass'
	
	return 'func {name}({params}) -> void:\n{body}\n'.format({
		name = _name,
		params = params_str,
		body = body
	})


# an action emits plain lines: the dictionary tokens were the cnode side of this
static func _token_lines(_save_data: HenSaveData, _tokens: Array) -> Array:
	var lines: Array = []

	for token: Variant in _tokens:
		if token is String:
			lines.append('	' + str(token))

	return lines
