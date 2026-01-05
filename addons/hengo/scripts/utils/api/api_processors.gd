@tool
class_name HenAPIProcessors extends RefCounted


static func check_param_validity(_params: Array, _type: StringName, _is_input: bool) -> int:
	var idx: int = 0
	
	for param: Dictionary in _params:
		var type: StringName = param.get(&'type', &'')
		
		if (_is_input and HenUtils.is_type_relation_valid(_type, type)) or \
			(not _is_input and HenUtils.is_type_relation_valid(type, _type)):
			return idx

		idx += 1
		
	return -1


static func process_states(_ast: HenMapDependencies.ProjectAST, _save_data_id: StringName, _io_type: StringName, _type: StringName, _from_another_script: bool, _arr: Array) -> void:
	var state_transitions: Dictionary = {
		name = 'State Transitions',
		icon = 'activity',
		color = '#ff9ff3',
		method_list = []
	}
	var state_category: Dictionary = {
		name = 'States',
		icon = 'activity',
		color = '#ff9ff3',
		method_list = []
	}
	
	var check_transition_validity = func(data_source: HenSaveState) -> Dictionary:
		var result = {valid = false, idx = -1}
		if not _io_type:
			result.valid = true
			return result
		
		if _io_type == 'out':
			var idx: int = 0
			for param: HenSaveParam in data_source.transition_data:
				if HenUtils.is_type_relation_valid(_type, param.type):
					result.idx = idx
					result.valid = true
					break
				idx += 1
		return result

	for state_data: HenSaveState in _ast.states:
		if not _io_type:
			(state_category.method_list as Array).append({
					_class_name = 'State',
					name = state_data.name,
					data = state_data.get_cnode_data(_save_data_id, _from_another_script)
				})
		
		var res_main = check_transition_validity.call(state_data)
		if res_main.valid:
			var dt = {
				_class_name = 'State Transitions',
				name = 'transition: ' + state_data.name,
				data = state_data.get_transition_cnode_data(_save_data_id, _from_another_script)
			}
			
			if res_main.idx != -1: dt.input_io_idx = res_main.idx
			
			(state_transitions.method_list as Array).append(dt)

		var sub_states: Array = state_data.get_sub_states((Engine.get_singleton('Global') as HenGlobal).SAVE_DATA)
		
		for sub_state: HenSaveState in sub_states:
			var res_sub = check_transition_validity.call(sub_state)
			if res_sub.valid:
				var dt_sub: Dictionary = {
					_class_name = 'State Transitions',
					name = 'sub state transition: ' + sub_state.name,
					data = sub_state.get_transition_cnode_data(_save_data_id, _from_another_script)
				}
				
				if res_sub.idx != -1: dt_sub.input_io_idx = res_sub.idx

				(state_transitions.method_list as Array).append(dt_sub)

	if not (state_category.method_list as Array).is_empty():
		_arr.append(state_category)
	
	if not (state_transitions.method_list as Array).is_empty():
		_arr.append(state_transitions)


static func process_functions(_ast: HenMapDependencies.ProjectAST, _save_data_id: StringName, _io_type: StringName, _type: StringName, _from_another_script: bool, _arr: Array) -> void:
	var func_category: Dictionary = {
		name = 'Functions',
		icon = 'braces',
		color = '#b05353',
		method_list = []
	}

	for func_data: HenSaveFunc in _ast.functions:
		var has_valid_connection: bool = false
		var input_idx: int = -1
		var output_idx: int = -1

		if not _io_type:
			has_valid_connection = true
		elif _io_type == 'in':
			var params: Array = []
			for param: HenSaveParam in func_data.outputs: params.append(param.get_data())
			
			output_idx = check_param_validity(params, _type, false)
			if output_idx != -1: has_valid_connection = true
		elif _io_type == 'out':
			if _from_another_script:
				if HenUtils.is_type_relation_valid(_type, 'Variant'):
					input_idx = 0
					has_valid_connection = true
			
			if not has_valid_connection:
				var params: Array = []
				for param: HenSaveParam in func_data.inputs: params.append(param.get_data())
				
				var idx: int = check_param_validity(params, _type, true)
				
				if idx != -1:
					input_idx = idx + 1 if _from_another_script else idx
					has_valid_connection = true

		if has_valid_connection:
			var dt: Dictionary = {
				_class_name = 'Function',
				name = func_data.name,
				data = func_data.get_cnode_data(_save_data_id, _from_another_script)
			}
			
			if input_idx != -1: dt.input_io_idx = input_idx
			if output_idx != -1: dt.output_io_idx = output_idx

			(func_category.method_list as Array).append(dt)

	if not (func_category.method_list as Array).is_empty():
		_arr.append(func_category)


static func process_variables(_ast: HenMapDependencies.ProjectAST, _save_data_id: StringName, _io_type: StringName, _type: StringName, _from_another_script: bool, _arr: Array) -> void:
	var var_category: Dictionary = {
		name = 'Variables',
		icon = 'variable',
		color = '#509fa6',
		method_list = []
	}

	for var_data: HenSaveVar in _ast.variables:
		var input_type: bool = _io_type == 'in'
		var output_type: bool = _io_type == 'out'

		if _io_type and input_type:
			if not HenUtils.is_type_relation_valid(var_data.type, _type):
				continue
		elif _io_type and output_type:
			if not HenUtils.is_type_relation_valid(_type, var_data.type):
				continue
		
		if not _io_type or input_type:
			var getter_name: String = 'get: ' + var_data.name
			var dt: Dictionary = {
				_class_name = 'Variable',
				name = getter_name,
				data = var_data.get_getter_cnode_data(_save_data_id, _from_another_script),
			}

			if input_type:
				dt.output_io_idx = 0

			(var_category.method_list as Array).append(dt)

		if not _io_type or output_type:
			var setter_name: String = 'set: ' + var_data.name
			var dt: Dictionary = {
				_class_name = 'Variable',
				name = setter_name,
				data = var_data.get_setter_cnode_data(_save_data_id, _from_another_script),
			}

			if output_type:
				dt.input_io_idx = 0

			(var_category.method_list as Array).append(dt)

	if not (var_category.get(&'method_list', []) as Array).is_empty():
		_arr.append(var_category)


static func process_signals(_ast: HenMapDependencies.ProjectAST, _io_type: StringName, _type: StringName, _arr: Array) -> void:
	var signal_category: Dictionary = {
		name = 'Signals',
		icon = 'radio-tower',
		color = '#51a650',
		method_list = []
	}

	for signal_data: HenSaveSignalCallback in _ast.signals_callback:
		var connect_name: String = 'connect: ' + signal_data.name
		var disconnect_name: String = 'disconnect: ' + signal_data.name
		
		
		var connect_valid: bool = false
		var connect_input_idx: int = -1
		
		if not _io_type:
			connect_valid = true
		elif _io_type == 'out':
			if HenUtils.is_type_relation_valid(_type, signal_data.type):
				connect_input_idx = 0
				connect_valid = true
			
			if not connect_valid:
				var params: Array = []
				for param: HenSaveParam in signal_data.bind_params: params.append(param.get_data())

				var idx: int = check_param_validity(params, _type, true)
				if idx != -1:
					connect_input_idx = idx + 1
					connect_valid = true

		if connect_valid:
			var dt: Dictionary = {
				_class_name = 'Signal',
				name = connect_name,
				data = signal_data.get_connect_cnode_data()
			}
			if connect_input_idx != -1: dt.input_io_idx = connect_input_idx
			(signal_category.method_list as Array).append(dt)

		var disconnect_valid: bool = false

		var disconnect_input_idx: int = -1
		
		if not _io_type:
			disconnect_valid = true
		elif _io_type == 'out':
			if HenUtils.is_type_relation_valid(_type, signal_data.type):
				disconnect_input_idx = 0
				disconnect_valid = true

		if disconnect_valid:
			var dt: Dictionary = {
				_class_name = 'Signal',
				name = disconnect_name,
				data = signal_data.get_diconnect_cnode_data()
			}
			if disconnect_input_idx != -1: dt.input_io_idx = disconnect_input_idx
			(signal_category.method_list as Array).append(dt)

	if not (signal_category.method_list as Array).is_empty():
		_arr.append(signal_category)


static func process_macros(_ast: HenMapDependencies.ProjectAST, _save_data_id: StringName, _io_type: StringName, _type: StringName, _from_another_script: bool, _arr: Array) -> void:
	var macro_category: Dictionary = {
		name = 'Macros',
		icon = 'wand-sparkles',
		color = '#9f50a6',
		method_list = []
	}

	for macro_data: HenSaveMacro in _ast.macros:
		var has_valid_connection: bool = false
		var input_idx: int = -1
		var output_idx: int = -1

		if not _io_type:
			has_valid_connection = true
		elif _io_type == 'in':
			var params: Array = []
			for param: HenSaveParam in macro_data.outputs: params.append(param.get_data())

			output_idx = check_param_validity(params, _type, false)
			if output_idx != -1: has_valid_connection = true

		elif _io_type == 'out':
			var params: Array = []
			for param: HenSaveParam in macro_data.inputs: params.append(param.get_data())

			input_idx = check_param_validity(params, _type, true)
			if input_idx != -1: has_valid_connection = true

		if has_valid_connection:
			var dt: Dictionary = {
				_class_name = 'Macro',
				name = macro_data.name,
				data = macro_data.get_cnode_data(_save_data_id, _from_another_script)
			}
			if input_idx != -1: dt.input_io_idx = input_idx
			if output_idx != -1: dt.output_io_idx = output_idx

			(macro_category.method_list as Array).append(dt)

	if not (macro_category.method_list as Array).is_empty():
		_arr.append(macro_category)
