class_name HenGeneratorSignal extends RefCounted

static func get_signals_code(_refs: HenTypeReferences) -> String:
	var signal_code: String = ''

	for signal_item: HenTypeSignalData in _refs.signals:
		signal_code += 'signal ' + signal_item.name.to_snake_case() + '\n'

	return signal_code + ' \n' if signal_code else ''