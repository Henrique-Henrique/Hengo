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


static func get_prop_get_data(_prop: Dictionary, _type: StringName) -> Dictionary:
	var router: HenRouter = Engine.get_singleton(&'Router')
	return {
		name = 'Get -> ' + _prop.name,
		sub_type = HenVirtualCNode.SubType.GET_PROP,
		category = 'native',
		inputs = [
			{
				is_ref = true,
				name = _type,
				type = _type
			}
		],
		outputs = [
			{
				name = _prop.name,
				type = _prop.type
			}
		],
		route = router.current_route
	}


static func get_prop_set_data(_prop: Dictionary, _type: StringName) -> Dictionary:
	var router: HenRouter = Engine.get_singleton(&'Router')
	return {
		name = 'Set -> ' + _prop.name,
		sub_type = HenVirtualCNode.SubType.SET_PROP,
		category = 'native',
		inputs = [
			{
				is_ref = true,
				name = _type,
				type = _type
			},
			{
				name = _prop.name,
				type = _prop.type
			}
		],
		route = router.current_route
	}


static func get_valid_recursive_props(_root_type: StringName, _target_type: StringName, _io_type: StringName, _native_props: Dictionary = {}) -> Array:
	var arr: Array = []
	var queue: Array = [ {
		type = _root_type,
		prefix = '',
		depth = 0
	}]
	
	while not queue.is_empty():
		var current: Dictionary = queue.pop_front()
		
		if current.depth > 2:
			continue
			
		if _native_props.has(current.type):
			for prop_data: Dictionary in _native_props.get(current.type):
				var full_name: String = (current.prefix + '.' + prop_data.name) if current.prefix else prop_data.name
				var synthetic_prop: Dictionary = {
					name = full_name,
					type = prop_data.type
				}
				
				queue.push_back({
					type = prop_data.type,
					prefix = full_name,
					depth = current.depth + 1
				})

				if _target_type and (_io_type == 'in' and not HenUtils.is_type_relation_valid(prop_data.type, _target_type) or \
					_io_type == 'out' and not (HenUtils.is_type_relation_valid(_target_type, prop_data.type))):
						continue
				
				arr.append(synthetic_prop)
				
	return arr

static func process_states(_ast: HenMapDependencies.ProjectAST, _save_data_id: StringName, _io_type: StringName, _type: StringName, _from_another_script: bool, _arr: Array, _native_props: Dictionary = {}) -> void:
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
		var result = {valid = false, idx = -1, is_prop = false, prop_data = {}}
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
				
				var props: Array = get_valid_recursive_props(param.type, _type, 'out', _native_props)
				if not props.is_empty():
					result.idx = idx
					result.valid = true
					result.is_prop = true
					result.prop_data = props[0]
					break
				
				if result.valid: break

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
			var name_suffix: String = ('.' + res_main.prop_data.name) if res_main.is_prop else ''
			var dt = {
				_class_name = 'State Transitions',
				name = 'transition: ' + state_data.name + name_suffix,
				data = state_data.get_transition_cnode_data(_save_data_id, _from_another_script)
			}
			
			if res_main.idx != -1: dt.input_io_idx = res_main.idx
			
			(state_transitions.method_list as Array).append(dt)

		var sub_states: Array = state_data.get_sub_states((Engine.get_singleton('Global') as HenGlobal).SAVE_DATA)
		
		for sub_state: HenSaveState in sub_states:
			var res_sub = check_transition_validity.call(sub_state)
			if res_sub.valid:
				var name_suffix: String = ('.' + res_sub.prop_data.name) if res_sub.is_prop else ''
				var dt_sub: Dictionary = {
					_class_name = 'State Transitions',
					name = 'sub state transition: ' + sub_state.name + name_suffix,
					data = sub_state.get_transition_cnode_data(_save_data_id, _from_another_script)
				}
				
				if res_sub.idx != -1: dt_sub.input_io_idx = res_sub.idx

				(state_transitions.method_list as Array).append(dt_sub)

	if not (state_category.method_list as Array).is_empty():
		_arr.append(state_category)
	
	if not (state_transitions.method_list as Array).is_empty():
		_arr.append(state_transitions)


static func process_functions(_ast: HenMapDependencies.ProjectAST, _save_data_id: StringName, _io_type: StringName, _type: StringName, _from_another_script: bool, _arr: Array, _native_props: Dictionary = {}) -> void:
	var func_category: Dictionary = {
		name = 'Functions',
		icon = 'braces',
		color = '#b05353',
		method_list = []
	}

	for func_data: HenSaveFunc in _ast.functions:
		var sub_items: Array = []
		var is_main_valid: bool = false
		var input_idx: int = -1
		var output_idx: int = -1
		
		var has_valid_connection: bool = false

		if not _io_type:
			has_valid_connection = true
		elif _io_type == 'in':
			var params: Array = []
			for param: HenSaveParam in func_data.outputs: params.append(param.get_data())
			
			output_idx = check_param_validity(params, _type, false)
			if output_idx != -1:
				has_valid_connection = true

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

		is_main_valid = has_valid_connection

		var dt_main: Dictionary = {
			_class_name = 'Function',
			name = func_data.name,
			data = func_data.get_cnode_data(_save_data_id, _from_another_script)
		}
		
		if not _io_type:
			dt_main.force_valid = true

		if is_main_valid:
			if input_idx != -1: dt_main.input_io_idx = input_idx
			if output_idx != -1: dt_main.output_io_idx = output_idx

		sub_items.append(dt_main)

		if not _io_type or _io_type == 'in':
			var out_idx: int = 0
			for param: HenSaveParam in func_data.outputs:
				var props: Array = get_valid_recursive_props(param.type, _type, 'in', _native_props)
				for prop: Dictionary in props:
					var getter_name: String = func_data.name + '().' + param.name + '.' + prop.name
					
					var dt: Dictionary = {
						_class_name = 'Function',
						name = getter_name,
						data = func_data.get_cnode_data(_save_data_id, _from_another_script),
						linked_prop = get_prop_get_data(prop, param.type),
						linked_prop_source_idx = out_idx,
						output_io_idx = 0
					}
					sub_items.append(dt)
				out_idx += 1
		
		if not _io_type or _io_type == 'out':
			var out_idx: int = 0
			for param: HenSaveParam in func_data.outputs:
				var props: Array = get_valid_recursive_props(param.type, _type, 'out', _native_props)
				for prop: Dictionary in props:
					var setter_name: String = 'set: ' + func_data.name + '().' + param.name + '.' + prop.name
					
					var dt: Dictionary = {
						_class_name = 'Function',
						name = setter_name,
						data = func_data.get_cnode_data(_save_data_id, _from_another_script),
						linked_prop = get_prop_set_data(prop, param.type),
						linked_prop_source_idx = out_idx,
						input_io_idx = 1
					}

					sub_items.append(dt)
				out_idx += 1

		if not sub_items.is_empty():
			var dt_folder: Dictionary = {
				_class_name = 'Function',
				name = func_data.name,
				data = func_data.get_cnode_data(_save_data_id, _from_another_script),
				recursive_props = sub_items,
				is_match = is_main_valid if _type else true
			}
			(func_category.method_list as Array).append(dt_folder)

	if not (func_category.method_list as Array).is_empty():
		_arr.append(func_category)


static func process_variables(_ast: HenMapDependencies.ProjectAST, _save_data_id: StringName, _io_type: StringName, _type: StringName, _from_another_script: bool, _arr: Array, _native_props: Dictionary = {}) -> void:
	var var_category: Dictionary = {
		name = 'Variables',
		icon = 'variable',
		color = '#509fa6',
		method_list = []
	}

	for var_data: HenSaveVar in _ast.variables:
		var sub_items: Array = []
		var is_variable_valid_source: bool = false
		
		if not _io_type or _io_type == 'in':
			var is_main_get_valid: bool = false
			if not _type or HenUtils.is_type_relation_valid(var_data.type, _type):
				is_main_get_valid = true
				if _type: is_variable_valid_source = true

			var dt_get: Dictionary = {
				_class_name = 'Variable',
				name = 'get: ' + var_data.name,
				data = var_data.get_getter_cnode_data(_save_data_id, _from_another_script),
			}
			if is_main_get_valid:
				dt_get.output_io_idx = 0
				
			sub_items.append(dt_get)
			
			var props: Array = get_valid_recursive_props(var_data.type, _type, 'in', _native_props)
			for prop: Dictionary in props:
				var getter_name: String = 'get: ' + var_data.name + '.' + prop.name
				var dt: Dictionary = {
					_class_name = 'Variable',
					name = getter_name,
					data = var_data.get_getter_cnode_data(_save_data_id, _from_another_script),
					linked_prop = get_prop_get_data(prop, var_data.type),
					output_io_idx = 0
				}
				sub_items.append(dt)

		if not _io_type or _io_type == 'out':
			var is_main_set_valid: bool = false
			if not _type or HenUtils.is_type_relation_valid(_type, var_data.type):
				is_main_set_valid = true
				if _type: is_variable_valid_source = true

			var dt_set: Dictionary = {
				_class_name = 'Variable',
				name = 'set: ' + var_data.name,
				data = var_data.get_setter_cnode_data(_save_data_id, _from_another_script),
			}
			if is_main_set_valid:
				dt_set.input_io_idx = 0

			sub_items.append(dt_set)

			var props: Array = get_valid_recursive_props(var_data.type, _type, 'out', _native_props)
			for prop: Dictionary in props:
				var setter_name: String = 'set: ' + var_data.name + '.' + prop.name
				var dt: Dictionary = {
					_class_name = 'Variable',
					name = setter_name,
					data = var_data.get_getter_cnode_data(_save_data_id, _from_another_script),
					linked_prop = get_prop_set_data(prop, var_data.type),
					input_io_idx = 1
				}
				sub_items.append(dt)

		if not sub_items.is_empty():
			var dt: Dictionary = {
				_class_name = 'Variable',
				name = var_data.name,
				recursive_props = sub_items,
				is_match = is_variable_valid_source if _type else true
			}
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


static func process_macros(_ast: HenMapDependencies.ProjectAST, _save_data_id: StringName, _io_type: StringName, _type: StringName, _from_another_script: bool, _arr: Array, _native_props: Dictionary = {}) -> void:
	var macro_category: Dictionary = {
		name = 'Macros',
		icon = 'wand-sparkles',
		color = '#9f50a6',
		method_list = []
	}

	for macro_data: HenSaveMacro in _ast.macros:
		var sub_items: Array = []
		var is_main_valid: bool = false
		var input_idx: int = -1
		var output_idx: int = -1
		
		var has_valid_connection: bool = false

		if not _io_type:
			has_valid_connection = true
		elif _io_type == 'in':
			var params: Array = []
			for param: HenSaveParam in macro_data.outputs: params.append(param.get_data())

			output_idx = check_param_validity(params, _type, false)
			if output_idx != -1:
				has_valid_connection = true

		elif _io_type == 'out':
			var params: Array = []
			for param: HenSaveParam in macro_data.inputs: params.append(param.get_data())

			input_idx = check_param_validity(params, _type, true)
			if input_idx != -1: has_valid_connection = true

		is_main_valid = has_valid_connection

		var dt_main: Dictionary = {
			_class_name = 'Macro',
			name = macro_data.name,
			data = macro_data.get_cnode_data(_save_data_id, _from_another_script)
		}
		
		if not _io_type:
			dt_main.force_valid = true

		if is_main_valid:
			if input_idx != -1: dt_main.input_io_idx = input_idx
			if output_idx != -1: dt_main.output_io_idx = output_idx
		
		sub_items.append(dt_main)
		
		if not _io_type or _io_type == 'in':
			var out_idx: int = 0
			for param: HenSaveParam in macro_data.outputs:
				var props: Array = get_valid_recursive_props(param.type, _type, 'in', _native_props)
				for prop: Dictionary in props:
					var getter_name: String = macro_data.name + '().' + param.name + '.' + prop.name
					
					var dt: Dictionary = {
						_class_name = 'Macro',
						name = getter_name,
						data = macro_data.get_cnode_data(_save_data_id, _from_another_script),
						linked_prop = get_prop_get_data(prop, param.type),
						linked_prop_source_idx = out_idx,
						output_io_idx = 0
					}
					sub_items.append(dt)
				out_idx += 1
		
		if not _io_type or _io_type == 'out':
			var out_idx: int = 0
			for param: HenSaveParam in macro_data.outputs:
				var props: Array = get_valid_recursive_props(param.type, _type, 'out', _native_props)
				for prop: Dictionary in props:
					var setter_name: String = 'set: ' + macro_data.name + '().' + param.name + '.' + prop.name
					
					var dt: Dictionary = {
						_class_name = 'Macro',
						name = setter_name,
						data = macro_data.get_cnode_data(_save_data_id, _from_another_script),
						linked_prop = get_prop_set_data(prop, param.type),
						linked_prop_source_idx = out_idx,
						input_io_idx = 1
					}
					sub_items.append(dt)
				out_idx += 1
		
		if not sub_items.is_empty():
			var dt_folder: Dictionary = {
				_class_name = 'Macro',
				name = macro_data.name,
				data = macro_data.get_cnode_data(_save_data_id, _from_another_script),
				recursive_props = sub_items,
				is_match = is_main_valid if _type else true
			}
			(macro_category.method_list as Array).append(dt_folder)

	if not (macro_category.method_list as Array).is_empty():
		_arr.append(macro_category)
