class_name HenGeneratorSignalCallback extends RefCounted


static func get_signal_call_name(_name: String) -> String:
	return '_on_' + _name.to_snake_case() + '_signal_'


static func get_signals_callback_code(_save_data: HenSaveData) -> String:
	var signal_code: String = ''

	for signal_item: HenSaveSignalCallback in _save_data.signals_callback:
		var signal_name = get_signal_call_name(signal_item.name)
		var signal_enter: HenVirtualCNode = search_signal_enter(signal_item)
		var signal_enter_connections: Array = _save_data.get_flow_connection_from_vc(signal_enter)

		signal_code += 'func {name}({params}):\n'.format({
			name = signal_name,
			params = ', '.join(signal_item.params.map( # parsing raw inputs from signal
			func(x: HenSaveParam) -> String:
				return x.name.to_snake_case()
		# parsing custom inputs
		) + signal_item.bind_params.map(
				func(x: HenSaveParam) -> String:
					return x.name.to_snake_case()
		))
		})

		# local variable
		signal_code += '\n'.join(signal_item.local_vars.map(func(x: HenSaveParam):
			return '\t' + HenGeneratorVariable.get_var_code_from_param(x)))

		if not signal_enter_connections.is_empty() and signal_enter_connections[0].to:
			var signal_tokens: Array = HenVirtualCNodeCode.get_flow_tokens(
				(signal_enter_connections[0] as HenVCFlowConnectionData).get_to(),
				(signal_enter_connections[0] as HenVCFlowConnectionData).to_id
			)
			var signal_block: Array = []

			for token in signal_tokens:
				signal_block.append(HenGeneratorByToken.get_code_by_token(token, 1))
			
			signal_code += '\n'.join(signal_block) + '\n\n' if signal_block.size() > 0 else ''
		else:
			signal_code += '\tpass\n\n'
	
	return signal_code


static func search_signal_enter(_signal_callback: HenSaveSignalCallback) -> HenVirtualCNode:
	for vc: HenVirtualCNode in _signal_callback.route.virtual_cnode_list:
		if vc.sub_type == HenVirtualCNode.SubType.SIGNAL_ENTER:
			return vc
	return null