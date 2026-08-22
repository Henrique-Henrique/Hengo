class_name HenGeneratorState extends RefCounted


# puts hook lines at the top of a lifecycle method, creating it when the state
# has nothing else in that phase
static func _prepend_hook(_save_data: HenSaveData, _state: HenSaveState, _virtual_tokens: Dictionary, _phase: StringName, _hook_tokens: Array) -> void:
	if _hook_tokens.is_empty():
		return

	var key: String = str(_phase)

	if not _virtual_tokens.has(key):
		_virtual_tokens[key] = {
			tokens = [],
			params = HenGeneratorAction.get_phase_params(_save_data, _state, _phase)
		}

	_virtual_tokens[key].tokens = _hook_tokens + (_virtual_tokens[key].tokens as Array)


static func get_states_start_code(_save_data: HenSaveData) -> String:
	var code: String = ''
	var idx: int = 0
	for state: HenSaveState in _save_data.states:
		code += ('\n' if idx > 0 else '') + '\t\t{key}={c_name}.new(self),'.format({
			key = state.name.to_snake_case(),
			c_name = state.name.to_pascal_case()
		})
		idx += 1
	
	return code


static func get_states_code(_save_data: HenSaveData) -> String:
	return get_states_code_with_arr(_save_data, _save_data.states)

static func get_states_code_with_arr(_save_data: HenSaveData, _state_arr: Array, _level: int = 0) -> String:
	var code: String = ''
	var idx: int = 0
	# generate classes implementation
	for state: HenSaveState in _state_arr:
		# the phases a state has come from its action list alone: the scaffolding
		# vcnode that used to stand for each one carried no logic of its own
		var virtual_tokens: Dictionary = {}

		# inject linear action bodies into the state's lifecycle methods.
		# exit gets super() for free (the != 'enter' rule), which the base needs
		# to tear down current_sub_state
		for phase: StringName in HenSaveAction.PHASE_ORDER:
			var action_tokens: Array = HenGeneratorAction.get_state_action_tokens(_save_data, state, phase)
			if action_tokens.is_empty():
				continue

			var key: String = str(phase)
			if not virtual_tokens.has(key):
				virtual_tokens[key] = {
					tokens = [],
					params = HenGeneratorAction.get_phase_params(_save_data, state, phase)
				}

			(virtual_tokens[key].tokens as Array).append_array(action_tokens)

		# an action that keeps state resets it on entry and undoes it on exit,
		# whatever phase it runs in
		_prepend_hook(_save_data, state, virtual_tokens, &'enter', HenGeneratorAction.get_state_reset_tokens(_save_data, state))
		_prepend_hook(_save_data, state, virtual_tokens, &'exit', HenGeneratorAction.get_state_teardown_tokens(_save_data, state))

		var base = '{new_line}{indent}class {name} extends HengoState:\n'.format({
			name = state.name.to_pascal_case(),
			new_line = '\n\n' if idx > 0 else '',
			indent = '\t'.repeat(_level)
		})

		# local variable
		base += '\n'.join(state.local_vars.map(func(x: HenSaveParam):
			return '\t'.repeat(_level + 1) + HenGeneratorVariable.get_var_code_from_param(x, x.name.to_snake_case())))
		
		# add new line if local var is not empty
		base += '\n' if not state.local_vars.is_empty() else ''

		# class-level declarations the actions need, indented line by line
		var action_base: Array = HenGeneratorAction.get_state_base_lines(_save_data, state)

		if not action_base.is_empty():
			base += '\n'.join(action_base.map(func(line: String) -> String:
				return ('\t'.repeat(_level + 1) + line) if not line.is_empty() else line)) + '\n'

		var sub_states: Array = state.get_sub_states(_save_data)

		if not sub_states.is_empty():
			base += get_states_code_with_arr(_save_data, sub_states, _level + 1)
			var sub_state_tokens: Array = []
			var start_sub_state: HenSaveState = null

			for sub_state: HenSaveState in sub_states:
				if sub_state.start:
					start_sub_state = sub_state
				sub_state_tokens.append('add_sub_state("{name_key}", {name}.new(_p))'.format(({
					name_key = sub_state.name.to_snake_case(),
					name = sub_state.name.to_pascal_case()
				})))
			
			virtual_tokens.set('_init', {
				tokens = sub_state_tokens,
				params = [ {name = '_p'}]
			})

			if start_sub_state:
				var sub_state_data: String = ''
				var flow_tokens: Array = HenGeneratorAction.get_phase_params(_save_data, start_sub_state, &'enter')

				sub_state_data = (', ' if not flow_tokens.is_empty() else '') + ', '.join(flow_tokens.map(func(x: Dictionary) -> String:
					return HenActionCode.get_default_value_code(_save_data, x.type, false, x.get('category', ''), x.get('data', null))))
				
				var change_sub_command = '_ref._STATE_CONTROLLER.current_state.change_sub_state("{name}"{data})'.format({
					name = start_sub_state.name.to_snake_case(),
					data = sub_state_data
				})

				if not virtual_tokens.has('enter'):
					virtual_tokens['enter'] = {
						tokens = [change_sub_command],
						params = []
					}
				else:
					(virtual_tokens['enter'].tokens as Array).append(change_sub_command)
		else:
			if virtual_tokens.is_empty():
				base += '\t'.repeat(_level + 1) + 'pass'
				code += base
				idx += 1
				continue

		var idx_1: int = 0

		for virtual_name in virtual_tokens.keys():
			var func_tokens: Array = virtual_tokens[virtual_name].tokens
			var func_params: Array = virtual_tokens[virtual_name].params

			if func_tokens.is_empty():
				continue
			
			var params_str: String = ', '.join(func_params.map(
				func(x: Dictionary) -> String:
					return (x.name as String).to_snake_case()
			))

			var func_base: String = '{new_line}{indent}func {name}({params}) -> void:\n{super_call}'.format({
				name = virtual_name,
				new_line = '\n\n' if idx_1 > 0 or not state.get_sub_states(_save_data).is_empty() else '',
				indent = '\t'.repeat(_level + 1),
				super_call = '\t'.repeat(_level + 2) + 'super({params})\n'.format({
					params = params_str
				}) if virtual_name != 'enter' else '',
				params = params_str
			})

			var func_codes: Array = []

			for token in func_tokens:
				if token is String:
					func_codes.append('\t'.repeat(_level + 2) + token)
				elif token is Dictionary:
					func_codes.append(
						''
					)
		
			func_base += '\n'.join(func_codes)
			base += func_base
			idx_1 += 1

		code += base
		idx += 1
	
	return code
