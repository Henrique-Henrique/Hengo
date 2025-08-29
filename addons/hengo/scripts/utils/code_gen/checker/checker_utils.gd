class_name HenCheckerUtils extends RefCounted

# Syncs node inputs with the provided definition inputs
static func sync_node_inputs(node_data: Dictionary, definition_inputs: Array, existing_inputs: Array) -> Dictionary:
	var new_inputs: Array = []
	var inputs_changed: bool = false
	var existing_inputs_dict: Dictionary = {}
	
	# Create a dictionary of existing inputs for easier lookup
	for inp: Dictionary in existing_inputs:
		existing_inputs_dict[inp.id] = inp

	# Preserve existing 'is_ref' inputs first
	for inp: Dictionary in existing_inputs:
		if inp.get('is_ref', false):
			new_inputs.append(inp)

	# If no 'is_ref' input exists and the definition has inputs, create a default one
	if new_inputs.is_empty() and not definition_inputs.is_empty():
		new_inputs.append({
			'category': 'default_value', 'code_value': 'Node.new()',
			'id': int(node_data.id) + 1, 'is_ref': true, 'name': 'from',
			'type': 'Node', 'value': 'Node.new()'
		})
	
	# Add/update inputs from the definition, skipping duplicates
	for def_in: Dictionary in definition_inputs:
		var already_in_list: bool = false
		for item: Dictionary in new_inputs:
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

	# Check for changes in inputs and reset removed inputs
	if not node_data.has('inputs') or (node_data.inputs as Array).size() != new_inputs.size():
		inputs_changed = true
		# Reset all existing inputs that will be removed
		if node_data.has('inputs'):
			var new_input_ids: Dictionary = {}
			for inp in new_inputs:
				new_input_ids[inp.id] = true
			
			for old_inp in node_data.inputs:
				if not new_input_ids.has(old_inp.id):
					_reset_inout_dict_value(old_inp)
	else:
		for i: int in new_inputs.size():
			if node_data.inputs[i].id != new_inputs[i].id:
				inputs_changed = true
				# Reset the old input that's being replaced
				_reset_inout_dict_value(node_data.inputs[i])
				break

	return {
		'new_inputs': new_inputs,
		'changed': inputs_changed
	}

# Syncs node outputs with the provided definition outputs
static func sync_node_outputs(node_data: Dictionary, definition_outputs: Array, existing_outputs: Array) -> Dictionary:
	var new_outputs: Array = []
	var outputs_changed: bool = false
	var existing_outputs_dict: Dictionary = {}
	
	# Create a dictionary of existing outputs for easier lookup
	for outp: Dictionary in existing_outputs:
		existing_outputs_dict[outp.id] = outp.duplicate(true) # Make sure to duplicate to avoid modifying the original

	for def_out: Dictionary in definition_outputs:
		var current: Dictionary
		if existing_outputs_dict.has(def_out.id):
			current = existing_outputs_dict[def_out.id]
			# Only update name and type, preserve other properties
			current.name = def_out.name
			current.type = def_out.type
		else:
			# If output doesn't exist, create a new one with just the basic properties
			current = {
				'id': def_out.id,
				'name': def_out.name,
				'type': def_out.type
			}
		new_outputs.append(current)

	# Check for changes in outputs
	if not node_data.has('outputs') or (node_data.outputs as Array).size() != new_outputs.size():
		outputs_changed = true
	else:
		for i: int in new_outputs.size():
			var existing_output = node_data.outputs[i]
			if existing_output.id != new_outputs[i].id or \
			   existing_output.name != new_outputs[i].name or \
			   existing_output.type != new_outputs[i].type:
				outputs_changed = true
				break

	return {
		'new_outputs': new_outputs,
		'changed': outputs_changed
	}

# Resets the value of an input/output dictionary
static func _reset_inout_dict_value(io_dict: Dictionary) -> void:
	if io_dict.get('category', '') == 'default_value':
		io_dict.value = 'null'
		io_dict.code_value = 'null'
