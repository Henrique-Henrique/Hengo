class_name HenGeneratorFunc extends RefCounted

static func get_functions_code(_save_data: HenSaveData) -> String:
	var func_code: String = ''

	for func_data: HenSaveFunc in _save_data.functions:
		# generating function
		func_code += 'func {name}({params}):\n'.format({
			name = func_data.name.to_snake_case(),
			params = ', '.join(func_data.inputs.map(
				func(x: HenSaveParam) -> String:
					return x.name.to_snake_case()
		))
		})
		
		# local variable
		func_code += '\n'.join(func_data.local_vars.map(func(x: HenSaveParam):
			return '\t' + HenGeneratorVariable.get_var_code_from_param(x, x.name.to_snake_case())))

		# func output (return)
		var output_code: Array = []
		var input_ref: HenVirtualCNode = search_input_ref(_save_data, func_data)
		var output_ref: HenVirtualCNode = search_output_ref(_save_data, func_data)
		
		for token: Dictionary in HenVirtualCNodeCode.get_input_token_list(_save_data, output_ref):
			output_code.append(HenGeneratorByToken.get_code_by_token(_save_data, token))

		var input_flow_connections: Array = _save_data.get_flow_connection_from_vc(input_ref)

		if not input_flow_connections.is_empty() and (input_flow_connections.get(0) as HenVCFlowConnectionData).get_to(_save_data):
			var func_tokens: Array = HenVirtualCNodeCode.get_flow_tokens(_save_data, (input_flow_connections.get(0) as HenVCFlowConnectionData).get_to(_save_data), (input_flow_connections.get(0) as HenVCFlowConnectionData).to_id)
			var func_block: Array = []

			for token in func_tokens:
				func_block.append(HenGeneratorByToken.get_code_by_token(_save_data, token, 1))

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


static func search_input_ref(_save_data: HenSaveData, _func: HenSaveFunc) -> HenVirtualCNode:
	for vc: HenVirtualCNode in _func.get_route(_save_data).virtual_cnode_list:
		if vc.sub_type == HenVirtualCNode.SubType.FUNC_INPUT:
			return vc
	return null


static func search_output_ref(_save_data: HenSaveData, _func: HenSaveFunc) -> HenVirtualCNode:
	for vc: HenVirtualCNode in _func.get_route(_save_data).virtual_cnode_list:
		if vc.sub_type == HenVirtualCNode.SubType.FUNC_OUTPUT:
			return vc
	return null