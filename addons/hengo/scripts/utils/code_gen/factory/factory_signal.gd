class_name HenFactorySignal extends RefCounted

static func get_signal_from_dict(_signal_data: Dictionary, _refs: HenTypeReferences) -> HenTypeSignalData:
	var signal_item: HenTypeSignalData = HenTypeSignalData.new()

	signal_item.id = _signal_data.id
	signal_item.name = _signal_data.name
	signal_item.type = _signal_data.type
	signal_item.signal_name = _signal_data.signal_name
	signal_item.signal_name_to_code = _signal_data.signal_name_to_code

	_refs.side_bar_item_ref[signal_item.id] = signal_item

	for param: Dictionary in _signal_data.params:
		signal_item.params.append(HenFactoryParam.get_param_from_dict(param))

	for param: Dictionary in _signal_data.bind_params:
		signal_item.bind_params.append(HenFactoryParam.get_param_from_dict(param))

	if _signal_data.has(&'local_vars'):
		for local_var: Dictionary in _signal_data.local_vars:
			signal_item.local_vars.append(HenFactoryVariable.get_variable_from_dict(local_var, _refs))

	if _signal_data.has(&'virtual_cnode_list'):
		for cnode: Dictionary in _signal_data.virtual_cnode_list:
			signal_item.virtual_cnode_list.append(HenFactoryCNode.get_cnode_from_dict(cnode, _refs, signal_item))

	_refs.signals.append(signal_item)

	return signal_item