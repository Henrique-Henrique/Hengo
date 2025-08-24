class_name HenCheckerFunc extends RefCounted

static func check_changes_func(_cnode_data: Dictionary, _refs: HenRegenerateRefs) -> void:
	# syncs a function node's properties with its sidebar definition
	var func_data: Dictionary

	for data: Dictionary in _refs.side_bar_list.func_list:
		if data.id == _cnode_data.from_side_bar_id:
			func_data = data
			break

	if func_data == null:
		return

	# sync function name
	if _cnode_data.name != func_data.name:
		_cnode_data.name = func_data.name
		if _cnode_data.has('name_to_code'):
			_cnode_data.name_to_code = func_data.name
		_refs.reload = true

	var inputs_changed: bool = false
	var new_inputs: Array = []
	var existing_inputs: Dictionary = {}
	if _cnode_data.has('inputs') and _cnode_data.inputs is Array:
		for inp: Dictionary in _cnode_data.inputs:
			existing_inputs[inp.id] = inp

	# preserve existing 'is_ref' inputs first
	for inp: Dictionary in _cnode_data.inputs:
		if inp.get('is_ref', false):
			new_inputs.append(inp)

	# if no 'is_ref' input exists and the function has inputs, create a default one
	if new_inputs.is_empty() and not (func_data.inputs as Array).is_empty():
		new_inputs.append({
			'category': 'default_value', 'code_value': 'Node.new()',
			'id': int(_cnode_data.id) + 1, 'is_ref': true, 'name': 'from',
			'type': 'Node', 'value': 'Node.new()'
		})
	
	# add/update inputs from the function definition, skipping duplicates
	for f_in: Dictionary in func_data.inputs:
		var already_in_list: bool = false
		for item: Dictionary in new_inputs:
			if item.id == f_in.id:
				already_in_list = true
				break
		
		if already_in_list:
			continue

		if existing_inputs.has(f_in.id):
			var current: Dictionary = existing_inputs[f_in.id]
			current.name = f_in.name
			current.type = f_in.type
			_reset_inout_dict_value(current)
			new_inputs.append(current)
		else:
			var new_input = {
				'category': 'default_value', 'code_value': 'null',
				'id': f_in.id, 'name': f_in.name, 'type': f_in.type, 'value': 'null'
			}
			_reset_inout_dict_value(new_input)
			new_inputs.append(new_input)

	# check for changes in inputs and reset removed inputs
	if not _cnode_data.has('inputs') or (_cnode_data.inputs as Array).size() != new_inputs.size():
		inputs_changed = true
		# Reset all existing inputs that will be removed
		if _cnode_data.has('inputs'):
			var new_input_ids: Dictionary = {}
			for inp in new_inputs:
				new_input_ids[inp.id] = true
			
			for old_inp in _cnode_data.inputs:
				if not new_input_ids.has(old_inp.id):
					_reset_inout_dict_value(old_inp)
	else:
		for i: int in new_inputs.size():
			if _cnode_data.inputs[i].id != new_inputs[i].id:
				inputs_changed = true
				# Reset the old input that's being replaced
				_reset_inout_dict_value(_cnode_data.inputs[i])
				break

	if inputs_changed:
		_cnode_data.inputs = new_inputs
		_refs.reload = true

	var outputs_changed: bool = false
	var existing_outputs: Dictionary = {}
	if _cnode_data.has('outputs') and _cnode_data.outputs is Array:
		for outp: Dictionary in _cnode_data.outputs:
			existing_outputs[outp.id] = outp

	var new_outputs: Array = []
	for f_out: Dictionary in func_data.outputs:
		if existing_outputs.has(f_out.id):
			var current: Dictionary = existing_outputs[f_out.id]
			current.name = f_out.name
			current.type = f_out.type
			new_outputs.append(current)
		else:
			new_outputs.append({'id': f_out.id, 'name': f_out.name, 'type': f_out.type})

	# check for changes in outputs
	if not _cnode_data.has('outputs') or (_cnode_data.outputs as Array).size() != new_outputs.size():
		outputs_changed = true
	else:
		for i: int in new_outputs.size():
			if _cnode_data.outputs[i].id != new_outputs[i].id:
				outputs_changed = true
				break

	if outputs_changed:
		_cnode_data.outputs = new_outputs
		_refs.reload = true
	
	if _refs.connections is Array and not (_refs.connections as Array).is_empty():
		var allowed_input_ids: Dictionary = {}
		for inp: Dictionary in _cnode_data.inputs:
			allowed_input_ids[inp.id] = true
			
		var allowed_output_ids: Dictionary = {}
		for outp: Dictionary in _cnode_data.outputs:
			allowed_output_ids[outp.id] = true
		
		var filtered_conns: Array = []
		var connections_changed: bool = false
		for con: Dictionary in _refs.connections:
			var connection_is_valid: bool = true
			if con.to_vc_id == _cnode_data.id:
				if not allowed_input_ids.has(con.to_id):
					connection_is_valid = false
			if con.from_vc_id == _cnode_data.id and not allowed_output_ids.has(con.from_id):
				connection_is_valid = false
			
			if connection_is_valid:
				filtered_conns.append(con)
			else:
				connections_changed = true
		
		if connections_changed:
			_refs.connections = filtered_conns
			_refs.reload = true
	

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