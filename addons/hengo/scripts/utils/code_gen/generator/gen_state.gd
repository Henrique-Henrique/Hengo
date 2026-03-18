class_name HenGeneratorState extends RefCounted


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
		var virtual_tokens: Dictionary = HenGeneratorBase.parse_virtual_cnode(state.get_route(_save_data).virtual_sub_type_vc_list, _save_data)

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
				for virtual_vc: HenVirtualCNode in start_sub_state.get_route(_save_data).virtual_sub_type_vc_list:
					if virtual_vc.get_vc_name(_save_data) == 'enter':
						var flow_tokens: Array = HenVirtualCNodeCode.get_output_token_list(_save_data, virtual_vc)
						sub_state_data = (', ' if not flow_tokens.is_empty() else '') + ', '.join(flow_tokens.map(func(x: Dictionary) -> String:
							return HenVirtualCNodeCode.get_default_value_code(_save_data, x.type, false, x.get('category', ''), x.get('data', null))))
						break
				
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
						HenGeneratorByToken.get_code_by_token(_save_data, token, _level + 2)
					)
		
			func_base += '\n'.join(func_codes)
			base += func_base
			idx_1 += 1

		code += base
		idx += 1
	
	return code
