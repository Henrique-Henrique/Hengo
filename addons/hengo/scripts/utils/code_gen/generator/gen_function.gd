class_name HenGeneratorFunc extends RefCounted

static func get_functions_code(_refs: HenSaveCodeType.References) -> String:
	var func_code: String = ''

	for func_data: HenSaveCodeType.Func in _refs.functions:
		# generating function
		func_code += 'func {name}({params}):\n'.format({
			name = func_data.name.to_snake_case(),
			params = ', '.join(func_data.inputs.map(
				func(x: HenSaveCodeType.Param) -> String:
					return x.name.to_snake_case()
		))
		})
		
		# local variable
		func_code += '\n'.join(func_data.local_vars.map(func(x: HenSaveCodeType.Variable):
			return '\t' + HenGeneratorVariable.get_var_code(x)))

		# func output (return)
		var output_code: Array = []
		
		print('NAME ', func_data.name)
		for token: Dictionary in func_data.output_ref.get_input_token_list():
			output_code.append(HenGeneratorByToken.get_code_by_token(token))

		if not func_data.input_ref.flow_connections.is_empty() and func_data.input_ref.flow_connections[0].to:
			var func_tokens: Array = func_data.input_ref.flow_connections[0].get_to().get_flow_tokens(
				func_data.input_ref.flow_connections[0].to_id
			)
			var func_block: Array = []

			for token in func_tokens:
				func_block.append(HenGeneratorByToken.get_code_by_token(token, 1))

			func_code += '\n'.join(func_block) + '\n' if func_block.size() > 0 else ''
		else:
			func_code += '\tpass\n\n' if func_data.local_vars.is_empty() and output_code.is_empty() else ''
		
	# 	#TODO output when not connected return empty field, make a default values for all types
		if output_code.size() == 1:
			func_code += '\treturn {output}\n\n'.format({
				output = ', '.join(output_code)
			})
		elif not output_code.is_empty():
			func_code += '\treturn [{outputs}]\n\n'.format({
				outputs = ', '.join(output_code)
			})
		
		func_code += '\n'
		# end func output
	
	return func_code