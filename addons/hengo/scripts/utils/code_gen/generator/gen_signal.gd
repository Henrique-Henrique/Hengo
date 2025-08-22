class_name HenGeneratorSignal extends RefCounted


static func get_signal_call_name(_name: String) -> String:
	return '_on_' + _name.to_snake_case() + '_signal_'


static func get_signals_code(_refs: HenTypeReferences) -> String:
	var signal_code: String = ''

	for signal_item: HenTypeSignalData in _refs.signals:
		var signal_name = get_signal_call_name(signal_item.name)

		signal_code += 'func {name}({params}):\n'.format({
			name = signal_name,
			params = ', '.join(signal_item.params.map( # parsing raw inputs from signal
			func(x: HenTypeParam) -> String:
				return x.name.to_snake_case()
		# parsing custom inputs
		) + signal_item.bind_params.map(
				func(x: HenTypeParam) -> String:
					return x.name.to_snake_case()
		))
		})

		# local variable
		signal_code += '\n'.join(signal_item.local_vars.map(func(x: HenTypeVariable):
			return '\t' + HenGeneratorVariable.get_var_code(x)))

		if not signal_item.signal_enter.flow_connections.is_empty() and signal_item.signal_enter.flow_connections[0].to:
			var signal_tokens: Array = signal_item.signal_enter.flow_connections[0].get_to().get_flow_tokens(
				signal_item.signal_enter.flow_connections[0].to_id
			)
			var signal_block: Array = []

			for token in signal_tokens:
				signal_block.append(HenGeneratorByToken.get_code_by_token(token, 1))
			
			signal_code += '\n'.join(signal_block) + '\n\n' if signal_block.size() > 0 else ''
		else:
			signal_code += '\tpass\n\n'
	
	return signal_code
