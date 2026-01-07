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


static func _process_param_items(_arr: Array, _params: Array, _io_type: StringName, _target_type: StringName, _native_props: Dictionary, _config: Dictionary) -> int:
	var valid_idx: int = -1
	var current_idx: int = 0
	
	# expected config structure: { _class_name, base_name, data, is_inputs, idx_offset }
	# avoids reserved keyword collision
	var is_inputs: bool = _config.is_inputs
	var offset: int = _config.get(&'idx_offset', 0)
	var target_class: String = _config._class_name
	
	for param: HenSaveParam in _params:
		if is_inputs:
			# shows individual inputs only when dragging out wire
			if _io_type == 'out':
				if not _target_type or HenUtils.is_type_relation_valid(_target_type, param.type):
					var real_idx: int = current_idx + offset
					if valid_idx == -1: valid_idx = real_idx
					
					var dt_input: Dictionary = {
						_class_name = target_class,
						name = _config.base_name + ' (' + param.name + ')',
						data = _config.data,
						input_io_idx = real_idx
					}
					_arr.append(dt_input)
		
		else:
			# shows direct outputs only when dragging in wire
			if _io_type == 'in':
				if not _target_type or HenUtils.is_type_relation_valid(param.type, _target_type):
					if valid_idx == -1: valid_idx = current_idx
					
					var dt_direct: Dictionary = {
						_class_name = target_class,
						name = _config.base_name + '().' + param.name,
						data = _config.data,
						output_io_idx = current_idx
					}
					_arr.append(dt_direct)

			# recursive getters
			if not _io_type or _io_type == 'in':
				var props: Array = get_valid_recursive_props(param.type, _target_type, 'in', _native_props)
				for prop: Dictionary in props:
					var dt: Dictionary = {
						_class_name = target_class,
						name = _config.base_name + '().' + param.name + '.' + prop.name,
						data = _config.data,
						linked_prop = get_prop_get_data(prop, param.type),
						linked_prop_source_idx = current_idx,
						output_io_idx = 0
					}
					_arr.append(dt)

			# recursive setters on outputs
			if not _io_type or _io_type == 'out':
				var props: Array = get_valid_recursive_props(param.type, _target_type, 'out', _native_props)
				for prop: Dictionary in props:
					var dt: Dictionary = {
						_class_name = target_class,
						name = 'set: ' + _config.base_name + '().' + param.name + '.' + prop.name,
						data = _config.data,
						linked_prop = get_prop_set_data(prop, param.type),
						linked_prop_source_idx = current_idx,
						input_io_idx = 1
					}
					_arr.append(dt)
		
		current_idx += 1
		
	return valid_idx


static func process_states(_ast: HenMapDependencies.ProjectAST, _save_data_id: StringName, _io_type: StringName, _type: StringName, _from_another_script: bool, _arr: Array, _native_props: Dictionary = {}) -> void:
	var router: HenRouter = Engine.get_singleton(&'Router')
	var global: HenGlobal = Engine.get_singleton(&'Global')
	
	var state_transitions: Dictionary = {
		name = 'State Transitions',
		icon = 'activity',
		color = '#ff9ff3',
		method_list = []
	}
	var sub_state_transitions: Dictionary = {
		name = 'Sub State Transitions',
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
	
	var process_state_list = func(list: Array, category: Dictionary, label_prefix: String):
		for state_data: HenSaveState in list:
			var sub_items: Array = []
			var input_idx: int = -1
			
			var cnode_data: Dictionary = state_data.get_transition_cnode_data(_save_data_id, _from_another_script)
			
			input_idx = _process_param_items(
				sub_items,
				state_data.transition_data,
				_io_type,
				_type,
				_native_props,
				{
					_class_name = category.name,
					base_name = label_prefix + state_data.name,
					data = cnode_data,
					is_inputs = true,
					idx_offset = 0
				}
			)

			var is_main_valid: bool = false
			
			if not _io_type:
				is_main_valid = true
			elif _io_type == 'out':
				if input_idx != -1: is_main_valid = true
				
			var dt_main: Dictionary = {
				_class_name = category.name,
				name = label_prefix + state_data.name,
				data = cnode_data
			}
			
			if is_main_valid and input_idx != -1:
				dt_main.input_io_idx = input_idx
			
			if not _io_type: dt_main.force_valid = true

			if not _io_type:
				sub_items.append(dt_main)

			if not sub_items.is_empty():
				(category.method_list as Array).append_array(sub_items)

	for state_data: HenSaveState in _ast.states:
		if not _io_type:
			(state_category.method_list as Array).append({
					_class_name = 'State',
					name = state_data.name,
					data = state_data.get_cnode_data(_save_data_id, _from_another_script),
					force_valid = true
				})
		
	process_state_list.call(_ast.states, state_transitions, 'transition: ')

	var target_sub_states: Array = []
	var current_state: HenSaveState = null
	var current_route_id: StringName = router.current_route.id
	
	for s: HenSaveState in global.SAVE_DATA.states:
		if str(s.id) == current_route_id:
			current_state = s
			break
			
	if not current_state:
		for subs: Array in global.SAVE_DATA.sub_states.values():
			for s: HenSaveState in subs:
				if str(s.id) == current_route_id:
					current_state = s
					break
			if current_state: break
	
	if current_state:
		if current_state.is_sub_state:
			for subs: Array in global.SAVE_DATA.sub_states.values():
				if subs.has(current_state):
					target_sub_states = subs
					break
		else:
			target_sub_states = current_state.get_sub_states(global.SAVE_DATA)

	if not target_sub_states.is_empty():
		process_state_list.call(target_sub_states, sub_state_transitions, 'sub state transition: ')

	if not (state_category.method_list as Array).is_empty():
		_arr.append(state_category)
	
	if not (state_transitions.method_list as Array).is_empty():
		_arr.append(state_transitions)

	if not (sub_state_transitions.method_list as Array).is_empty():
		_arr.append(sub_state_transitions)


static func process_functions(_ast: HenMapDependencies.ProjectAST, _save_data_id: StringName, _io_type: StringName, _type: StringName, _from_another_script: bool, _arr: Array, _native_props: Dictionary = {}) -> void:
	var func_category: Dictionary = {
		name = 'Functions',
		icon = 'braces',
		color = '#b05353',
		method_list = []
	}

	for func_data: HenSaveFunc in _ast.functions:
		var sub_items: Array = []
		var cnode_data: Dictionary = func_data.get_cnode_data(_save_data_id, _from_another_script)
		
		var output_idx: int = _process_param_items(
			sub_items, func_data.outputs, _io_type, _type, _native_props,
			{
				_class_name = 'Function', base_name = func_data.name, data = cnode_data,
				is_inputs = false
			}
		)

		var input_idx: int = _process_param_items(
			sub_items, func_data.inputs, _io_type, _type, _native_props,
			{
				_class_name = 'Function', base_name = func_data.name, data = cnode_data,
				is_inputs = true,
				idx_offset = 1 if _from_another_script else 0
			}
		)

		var is_main_valid: bool = false
		if not _io_type: is_main_valid = true
		elif _io_type == 'in' and output_idx != -1: is_main_valid = true
		elif _io_type == 'out' and input_idx != -1: is_main_valid = true
		
		var dt_main: Dictionary = {
			_class_name = 'Function',
			name = func_data.name,
			data = cnode_data
		}
		
		if not _io_type: dt_main.force_valid = true
		if is_main_valid:
			if input_idx != -1: dt_main.input_io_idx = input_idx
			if output_idx != -1: dt_main.output_io_idx = output_idx

		# adds main node only if not filtering by wire
		if not _io_type:
			sub_items.append(dt_main)

		if not sub_items.is_empty():
			var dt_folder: Dictionary = {
				_class_name = 'Function',
				name = func_data.name,
				data = cnode_data,
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
				dt_set.input_io_idx = 0 if not _from_another_script else 1

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
		var cnode_data: Dictionary = macro_data.get_cnode_data(_save_data_id, _from_another_script)
		
		var output_idx: int = _process_param_items(
			sub_items, macro_data.outputs, _io_type, _type, _native_props,
			{_class_name = 'Macro', base_name = macro_data.name, data = cnode_data, is_inputs = false}
		)

		var input_idx: int = _process_param_items(
			sub_items, macro_data.inputs, _io_type, _type, _native_props,
			{_class_name = 'Macro', base_name = macro_data.name, data = cnode_data, is_inputs = true, idx_offset = 1 if _from_another_script else 0}
		)

		var is_main_valid: bool = false
		if not _io_type: is_main_valid = true
		elif _io_type == 'in' and output_idx != -1: is_main_valid = true
		elif _io_type == 'out' and input_idx != -1: is_main_valid = true

		var dt_main: Dictionary = {
			_class_name = 'Macro',
			name = macro_data.name,
			data = cnode_data
		}
		
		if not _io_type: dt_main.force_valid = true
		if is_main_valid:
			if input_idx != -1: dt_main.input_io_idx = input_idx
			if output_idx != -1: dt_main.output_io_idx = output_idx
		
		# adds main node only if not filtering by wire
		if not _io_type:
			sub_items.append(dt_main)
		
		if not sub_items.is_empty():
			var dt_folder: Dictionary = {
				_class_name = 'Macro',
				name = macro_data.name,
				data = cnode_data,
				recursive_props = sub_items,
				is_match = is_main_valid if _type else true
			}
			(macro_category.method_list as Array).append(dt_folder)

	if not (macro_category.method_list as Array).is_empty():
		_arr.append(macro_category)