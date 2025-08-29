class_name HenFactorySignal extends RefCounted


static func get_signal_from_dict(_signal_data: Dictionary, _refs: HenTypeReferences) -> HenTypeSignalData:
	var signal_item: HenTypeSignalData = HenTypeSignalData.new()

	signal_item.id = _signal_data.id
	signal_item.name = _signal_data.name

	_refs.side_bar_item_ref[signal_item.id] = signal_item

	for input: Dictionary in _signal_data.inputs:
		signal_item.inputs.append(HenFactoryParam.get_param_from_dict(input))

	_refs.signals.append(signal_item)

	return signal_item