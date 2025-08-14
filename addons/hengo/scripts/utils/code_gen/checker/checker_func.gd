class_name HenCheckerFunc extends RefCounted

static func check_changes_func(_dict: Dictionary, _refs: HenRegenerateRefs) -> void:
	var func_data: Dictionary

	for _func_data: Dictionary in _refs.side_bar_list.func_list:
		if _func_data.id == _dict.from_side_bar_id:
			func_data = _func_data
			break
	
	if func_data:
		if func_data.name != _dict.name:
			_dict.name = func_data.name
			_refs.reload = true

		var real_output_size: int = func_data.outputs.size()
		var real_input_size: int = func_data.inputs.size()
		var output_size: int = _dict.outputs.size() if _dict.has('outputs') else 0
		var input_size: int = _dict.inputs.size() - 1 if _dict.has('inputs') else 0

		_check_func_inouts(true, func_data, _dict, input_size, real_input_size, _refs)
		_check_func_inouts(false, func_data, _dict, output_size, real_output_size, _refs)

	else:
		if not _dict.has('invalid') or _dict.has('invalid') and not _dict.invalid:
			_dict.invalid = true
			_refs.reload = true


#
#
#
#
#
#
static func _check_func_inouts(
	_is_inputs: bool,
	_func_data: Dictionary,
	_dict: Dictionary,
	_output_size: int,
	_real_output_size: int,
	_refs: HenRegenerateRefs
) -> void:
	var func_arr: Array = _func_data.outputs if not _is_inputs else _func_data.inputs
	var arr: Array

	if _is_inputs:
		if _dict.has('inputs'):
			arr = _dict.inputs
		elif _real_output_size > 0:
			_dict.inputs = []
			arr = _dict.inputs
		else:
			return
	else:
		if _dict.has('outputs'):
			arr = _dict.outputs
		elif _real_output_size > 0:
			_dict.outputs = []
			arr = _dict.outputs
		else:
			return

	var old_map: Dictionary = {}
	
	for inout: Dictionary in arr:
		if inout.has('is_ref'):
			continue
		
		old_map[inout.from_id] = {
			id = inout.id,
			type = inout.type
		}

	if arr.is_empty():
		for new_inout: HenParamData in func_arr:
			arr.append({
				id=_refs.get_new_node_counter(),
				name=new_inout.name,
				type=new_inout.type,
				from_id=new_inout.id
			})
		
			_refs.reload = true
	else:
		var idx: int = 0
		var remove: Array = []
		var inout_size: int = arr.size() if not _is_inputs else arr.size() - 1

		# add the news inouts
		if func_arr.size() > inout_size:
			for i in range(func_arr.size() - inout_size):
				var data: Dictionary = func_arr[inout_size + i].get_save_with_from_id()
				data.id = _refs.get_new_node_counter()
				arr.append(data)
			
			_refs.reload = true

		# change current inouts
		for new_inout: Dictionary in arr:
			if new_inout.has('is_ref'):
				continue

			if idx >= func_arr.size():
				remove.append(new_inout)
				_refs.disconnect_list.append({
					id=_dict.id,
					output_id=new_inout.id
				})
				_refs.reload = true
				continue

			var inout_ref: HenParamData = func_arr[idx]
			new_inout.merge(inout_ref.get_save_without_id(), true)
			
			if old_map.has(new_inout.from_id):
				var old: Dictionary = old_map[new_inout.from_id]
				new_inout.id = old.id

				# check input connections
				if old.type != new_inout.type:
					if _is_inputs and _dict.has('input_connections'):
						for connection: Dictionary in _dict.input_connections:
							_refs.disconnect_list.append({
								id=connection.from_vc_id,
								output_id=connection.from_id
							})
					else:
						_refs.disconnect_list.append({
							id=_dict.id,
							output_id=old.id
						})
					
					if _is_inputs: _reset_inout_dict_value(new_inout)
					
			new_inout.from_id = inout_ref.id
			idx += 1
		
		for inout: Dictionary in remove:
			arr.erase(inout)


#
#
#
#
#
#
static func _reset_inout_dict_value(_dict: Dictionary) -> void:
	match _dict.type:
		'String', 'NodePath', 'StringName':
			_dict.code_value = '""'
		'int':
			_dict.code_value = '0'
		'float':
			_dict.code_value = '0.'
		'Vector2':
			_dict.code_value = 'Vector2(0, 0)'
		'bool':
			_dict.code_value = 'false'
		'Variant':
			_dict.code_value = 'null'
		_:
			if HenEnums.VARIANT_TYPES.has(_dict.type):
				_dict.code_value = _dict.type + '()'
			elif ClassDB.can_instantiate(_dict.type):
				_dict.code_value = _dict.type + '.new()'

	match _dict.type:
		'String', 'NodePath', 'StringName':
			_dict.value = ''
		_:
			_dict.value = _dict.code_value
