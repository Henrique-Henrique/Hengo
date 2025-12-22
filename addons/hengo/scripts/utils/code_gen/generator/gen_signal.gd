class_name HenGeneratorSignal extends RefCounted

static func get_signals_code(_save_data: HenSaveData) -> String:
	var signal_code: String = ''

	for signal_item: HenSaveSignal in _save_data.signals:
		signal_code += 'signal ' + signal_item.name.to_snake_case() + '\n'

	return signal_code + ' \n' if signal_code else ''