class_name HenFactoryFunc extends RefCounted

static func get_func_from_dict(_func_data: Dictionary, _refs: HenSaveCodeType.References) -> HenSaveCodeType.Func:
	var function: HenSaveCodeType.Func = HenSaveCodeType.Func.new()

	function.id = _func_data.id
	function.name = _func_data.name

	_refs.side_bar_item_ref[function.id] = function

	for input: Dictionary in _func_data.inputs:
		function.inputs.append(HenFactoryParam.get_param_from_dict(input))

	for output: Dictionary in _func_data.outputs:
		function.outputs.append(HenFactoryParam.get_param_from_dict(output))

	if _func_data.has(&'local_vars'):
		for local_var: Dictionary in _func_data.local_vars:
			function.local_vars.append(HenFactoryVariable.get_variable_from_dict(local_var, _refs))

	if _func_data.has(&'virtual_cnode_list'):
		for cnode: Dictionary in _func_data.virtual_cnode_list:
			function.virtual_cnode_list.append(HenFactoryCNode.get_cnode_from_dict(cnode, _refs, function))
	
	_refs.functions.append(function)

	return function
