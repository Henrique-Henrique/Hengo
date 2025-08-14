class_name HenGeneratorState extends RefCounted

static func get_states_start_code(_refs: HenSaveCodeType.References) -> String:
	var code: String = ''

	# parsing dictionaries
	if not _refs.states_data.is_empty():
		code += ',\n'.join(_refs.states_data.keys().map(
				func(state_name: String) -> String:
					return '\t\t{key}={c_name}.new(self{transitions})'.format({
						key=state_name,
						c_name=state_name.to_pascal_case(),
						transitions=', {\n\t\t\t' + ',\n\t\t\t'.join(_refs.states_data[state_name].transitions.map(
						func(trans: Dictionary) -> String:
						return '{state_name}="{to_state_name}"'.format({
							state_name=trans.name.to_snake_case(),
							to_state_name=trans.to_state_name.to_snake_case()
						})
						)) + '\n\t\t}' if _refs.states_data[state_name].transitions.size() > 0 else ''
					})
		))
	
	return code


static func get_states_code(_refs: HenSaveCodeType.References) -> String:
	var code: String = ''
	var idx: int = 0
	# generating classes implementation
	for state_name in _refs.states_data.keys():
		var item = _refs.states_data[state_name]

		var base = '{new_line}class {name} extends HengoState:\n'.format({
			name=state_name.to_pascal_case(),
			new_line='\n\n' if idx > 0 else ''
		})

		if item.virtual_tokens.is_empty():
			base += '\tpass'
			code += base
			continue

		var idx_1: int = 0

		for virtual_name in item.virtual_tokens.keys():
			var func_tokens = item.virtual_tokens[virtual_name].tokens
			var func_params = item.virtual_tokens[virtual_name].params

			if func_tokens.is_empty():
				continue

			var func_base: String = '{new_line}\tfunc {name}({params}) -> void:\n'.format({
				name=virtual_name,
				new_line='\n\n' if idx_1 > 0 else '',
				params=', '.join(func_params.map(
					func(x: Dictionary) -> String:
						return x.name
				
			))
			})

			var func_codes: Array = []

			for token in func_tokens:
				func_codes.append(
					HenGeneratorByToken.get_code_by_token(token, 2)
				)
		
			func_base += '\n'.join(func_codes)
			base += func_base
			idx_1 += 1

		code += base
		idx += 1

	return code
