class_name HenCheckerUtils extends RefCounted


# syncs node inputs with the provided definition inputs
static func sync_node_inputs(_node_data: Dictionary, _definition_inputs: Array, _existing_inputs: Array) -> Dictionary:
	var new_inputs: Array = []
	var inputs_changed: bool = false
	var existing_inputs_dict: Dictionary = {}
	
	# create a dictionary of existing inputs for easier lookup
	for inp in _existing_inputs:
		existing_inputs_dict[inp.id] = inp

	# preserve existing 'is_ref' inputs first
	for inp in _existing_inputs:
		if inp.get('is_ref', false):
			new_inputs.append(inp)

	# create default ref input if none exists and definition has inputs
	if new_inputs.is_empty() and not _definition_inputs.is_empty():
		new_inputs.append({
			'category': 'default_value', 'code_value': 'Node.new()',
			'id': int(_node_data.id) + 1, 'is_ref': true, 'name': 'from',
			'type': 'Node', 'value': 'Node.new()'
		})
	
	# process definition inputs, adding or updating as needed
	for def_in in _definition_inputs:
		var already_in_list: bool = false
		for item in new_inputs:
			if item.id == def_in.id:
				already_in_list = true
				break
		
		if already_in_list:
			continue

		if existing_inputs_dict.has(def_in.id):
			var current: Dictionary = existing_inputs_dict[def_in.id].duplicate(true)
			current.name = def_in.name
			current.type = def_in.type
			_reset_inout_dict_value(current)
			new_inputs.append(current)
		else:
			var new_input = {
				'category': 'default_value', 'code_value': 'null',
				'id': def_in.id, 'name': def_in.name, 'type': def_in.type, 'value': 'null'
			}
			_reset_inout_dict_value(new_input)
			new_inputs.append(new_input)

	# check for changes in inputs and reset removed inputs
	if not _node_data.has('inputs') or (_node_data.inputs as Array).size() != new_inputs.size():
		inputs_changed = true
		# reset all existing inputs that will be removed
		if _node_data.has('inputs'):
			var new_input_ids: Dictionary = {}
			for inp in new_inputs:
				new_input_ids[inp.id] = true
			
			for old_inp in _node_data.inputs:
				if not new_input_ids.has(old_inp.id):
					_reset_inout_dict_value(old_inp)
	else:
		for i in new_inputs.size():
			if _node_data.inputs[i].id != new_inputs[i].id:
				inputs_changed = true
				_reset_inout_dict_value(_node_data.inputs[i])
				break

	return {
		'new_inputs': new_inputs,
		'changed': inputs_changed
	}


# syncs node outputs with the provided definition outputs
static func sync_node_outputs(_node_data: Dictionary, _definition_outputs: Array, _existing_outputs: Array) -> Dictionary:
	var new_outputs: Array = []
	var outputs_changed: bool = false
	var existing_outputs_dict: Dictionary = {}
	
	# create a dictionary of existing outputs for easier lookup
	for outp in _existing_outputs:
		existing_outputs_dict[outp.id] = outp.duplicate(true)

	# process definition outputs, adding or updating as needed
	for def_out in _definition_outputs:
		var current: Dictionary
		if existing_outputs_dict.has(def_out.id):
			current = existing_outputs_dict[def_out.id]
			current.name = def_out.name
			current.type = def_out.type
		else:
			current = {
				'id': def_out.id,
				'name': def_out.name,
				'type': def_out.type
			}
		new_outputs.append(current)

	# check for changes in outputs
	if not _node_data.has('outputs') or (_node_data.outputs as Array).size() != new_outputs.size():
		outputs_changed = true
	else:
		for i in new_outputs.size():
			var existing_output = _node_data.outputs[i]
			if existing_output.id != new_outputs[i].id or \
			   existing_output.name != new_outputs[i].name or \
			   existing_output.type != new_outputs[i].type:
				outputs_changed = true
				break

	return {
		'new_outputs': new_outputs,
		'changed': outputs_changed
	}


# updates connections based on valid inputs and outputs of a cnode
static func update_connections(_refs: HenRegenerateRefs, _cnode_data: Dictionary) -> bool:
	if _refs.connections is Array and not _refs.connections.is_empty():
		var allowed_input_ids: Dictionary = {}
		if _cnode_data.has('inputs'):
			for inp in _cnode_data.inputs:
				allowed_input_ids[inp.id] = true
			
		var allowed_output_ids: Dictionary = {}
		if _cnode_data.has('outputs'):
			for outp in _cnode_data.outputs:
				allowed_output_ids[outp.id] = true
		
		var filtered_conns: Array = []
		var connections_changed: bool = false
		
		for con in _refs.connections:
			var connection_is_valid: bool = true
			if con.to_vc_id == _cnode_data.id and not allowed_input_ids.has(con.to_id):
				connection_is_valid = false
			if con.from_vc_id == _cnode_data.id and not allowed_output_ids.has(con.from_id):
				connection_is_valid = false
			
			if connection_is_valid:
				filtered_conns.append(con)
			else:
				connections_changed = true
		
		if connections_changed:
			_refs.connections = filtered_conns
			return true
	
	return false


# resets the value of an input/output dictionary
static func _reset_inout_dict_value(_io_dict: Dictionary) -> void:
	if _io_dict.get('category', '') == 'default_value':
		_io_dict.value = 'null'
		_io_dict.code_value = 'null'
