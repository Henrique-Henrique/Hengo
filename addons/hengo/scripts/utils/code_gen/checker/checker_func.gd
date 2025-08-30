class_name HenCheckerFunc extends RefCounted


static func check_changes_func(_cnode_data: Dictionary, _refs: HenRegenerateRefs) -> void:
	# syncs a function node's properties with its sidebar definition
	var func_data: Dictionary

	for data: Dictionary in _refs.side_bar_list.func_list:
		if data.id == _cnode_data.from_side_bar_id:
			func_data = data
			break

	if func_data.is_empty():
		if not _cnode_data.has('invalid') or (_cnode_data.has('invalid') and not _cnode_data.invalid):
			_cnode_data.invalid = true
			_refs.reload = true
		return

	# sync function name
	if _cnode_data.name != func_data.name:
		_cnode_data.name = func_data.name
		if _cnode_data.has('name_to_code'):
			_cnode_data.name_to_code = func_data.name
		_refs.reload = true

	# ensure inputs and outputs keys exist
	if not _cnode_data.has('inputs'):
		_cnode_data.inputs = []
	if not _cnode_data.has('outputs'):
		_cnode_data.outputs = []

	# Process inputs
	var existing_inputs = _cnode_data.inputs
	var input_result = HenCheckerUtils.sync_node_inputs(_cnode_data, func_data.inputs, existing_inputs)
	if input_result.changed:
		_cnode_data.inputs = input_result.new_inputs
		_refs.reload = true

	# Process outputs
	var existing_outputs = _cnode_data.outputs
	var output_result = HenCheckerUtils.sync_node_outputs(_cnode_data, func_data.outputs, existing_outputs)
	if output_result.changed:
		_cnode_data.outputs = output_result.new_outputs
		_refs.reload = true
	
	# check and update connections if needed
	if HenCheckerUtils.update_connections(_refs, _cnode_data):
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