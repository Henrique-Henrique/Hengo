class_name HenVirtualCNodeIO extends RefCounted

var inputs: Array[HenVCInOutData]
var outputs: Array[HenVCInOutData]
var connections: Array[HenVCConnectionData]

var identity: HenVirtualCNodeIdentity
var state: HenVirtualCNodeState

signal cnode_need_update


func _init(_identity: HenVirtualCNodeIdentity, _state: HenVirtualCNodeState) -> void:
	identity = _identity
	state = _state


func get_input(_id: int) -> HenVCInOutData:
	for input: HenVCInOutData in inputs:
		if input.id == _id:
			return input
	return null


func get_output(_id: int) -> HenVCInOutData:
	for output: HenVCInOutData in outputs:
		if output.id == _id:
			return output
	return null


func create_input_connection(_id: int, _from_id: int, _to: HenVirtualCNode, _from: HenVirtualCNode) -> HenVCConnectionReturn:
	var input: HenVCInOutData = get_input(_id)
	var output: HenVCInOutData = _from.io.get_output(_from_id)

	if not input or not output:
		return
	
	if not HenUtils.is_type_relation_valid(output.type, input.type):
		return

	var connection: HenVCConnectionData = HenVCConnectionData.new()

	connection.from_type = output.type
	connection.from_id = output.id
	connection.output_ref = output
	connection.from = weakref(_from)
	connection.to = weakref(_to)
	connection.to_type = input.type
	connection.to_id = input.id
	connection.input_ref = input

	return HenVCConnectionReturn.new(connection, _id)


func clear_in_out(_is_input: bool) -> void:
	if _is_input:
		inputs.clear()
	else:
		outputs.clear()


func input_has_connection(_id: int) -> bool:
	for input_connection: HenVCConnectionData in connections:
		if input_connection.to_id == _id:
			return true

	return false


func output_has_connection(_id: int) -> bool:
	for output_connection: HenVCConnectionData in connections:
		if output_connection.from_id == _id:
			return true

	return false


func get_input_connection_command(_id: int) -> HenVCConnectionReturn:
	for connection: HenVCConnectionData in connections:
		if connection.to_id == _id:
			return HenVCConnectionReturn.new(connection)

	return null


func remove_io_connection(_ref: HenVCInOutData) -> void:
	var connection_remove: Array = []

	for connection: HenVCConnectionData in connections:
		if _ref.id == connection.to_id:
			connection_remove.append(connection)

	for connection: HenVCConnectionData in connection_remove:
		connection.get_from().io.connections.erase(connection)
		connections.erase(connection)

		if connection.line_ref:
			connection.line_ref.visible = false

		connection.get_from().io.cnode_need_update.emit()
	
	cnode_need_update.emit()


func on_in_out_moved(_is_input: bool, _pos: int, _in_ou_ref: HenVCInOutData) -> void:
	var is_input: bool = _is_input
	var index_slice: int = 0

	match identity.sub_type:
		HenVirtualCNode.SubType.FUNC_INPUT, HenVirtualCNode.SubType.SIGNAL_ENTER, HenVirtualCNode.SubType.MACRO_INPUT:
			if is_input: is_input = false
			else: return
		HenVirtualCNode.SubType.FUNC_OUTPUT, HenVirtualCNode.SubType.MACRO_OUTPUT:
			if not is_input: is_input = true
			else: return
		HenVirtualCNode.SubType.SIGNAL_CONNECTION:
			# they have reference input, so start from 1
			index_slice = 1

	var new_idx: int = _pos + index_slice

	if is_input:
		HenUtils.move_array_item_to_idx(inputs, _in_ou_ref, new_idx)
	else:
		HenUtils.move_array_item_to_idx(outputs, _in_ou_ref, _pos + index_slice)

	cnode_need_update.emit()


func on_in_out_deleted(_is_input: bool, _in_ou_ref: HenVCInOutData) -> void:
	var is_input: bool = _is_input

	match identity.sub_type:
		HenVirtualCNode.SubType.FUNC_INPUT, HenVirtualCNode.SubType.SIGNAL_ENTER, HenVirtualCNode.SubType.MACRO_INPUT:
			if is_input: is_input = false
			else: return
		HenVirtualCNode.SubType.FUNC_OUTPUT, HenVirtualCNode.SubType.MACRO_OUTPUT:
			if not is_input: is_input = true
			else: return

	#TODO remove connections
	if is_input:
		inputs.erase(_in_ou_ref)
	else:
		outputs.erase(_in_ou_ref)

	remove_io_connection(_in_ou_ref)
	cnode_need_update.emit()


func on_in_out_added(_owner: HenVirtualCNode, _is_input: bool, _data: Dictionary, _check_types: bool = true) -> HenVCInOutData:
	# restrict creation by sub_type
	if _check_types:
		match identity.sub_type:
			HenVirtualCNode.SubType.FUNC_INPUT, HenVirtualCNode.SubType.MACRO_INPUT:
				if not _is_input: return
				_is_input = false
			HenVirtualCNode.SubType.FUNC_OUTPUT, HenVirtualCNode.SubType.MACRO_OUTPUT:
				if _is_input: return
				_is_input = true
			HenVirtualCNode.SubType.SIGNAL_ENTER:
				_is_input = false

	if _data.has('ref_id'):
		if not state.invalid:
			@warning_ignore('unsafe_call_argument')
			_data.ref = HenGlobal.SIDE_BAR_LIST_CACHE[int(_data.ref_id)]

	var in_out: HenVCInOutData = HenVCInOutData.new(_data, _owner)

	if _data.has('ref'):
		@warning_ignore('unsafe_call_argument')
		in_out.set_ref(_data.ref)

	in_out.moved.connect(on_in_out_moved)
	in_out.deleted.connect(on_in_out_deleted)
	in_out.update_changes.connect(on_need_update)
	in_out.type_changed.connect(on_in_out_type_changed)

	if _is_input:
		inputs.append(in_out)
	else:
		outputs.append(in_out)
	
	cnode_need_update.emit()
	return in_out


func on_need_update() -> void:
	cnode_need_update.emit()


func on_in_out_type_changed(_old_type: StringName, _type: StringName, _ref: HenVCInOutData) -> void:
	if HenUtils.is_type_relation_valid(_old_type, _type):
		remove_io_connection(_ref)


func on_in_out_reset(_is_input: bool, _new_inputs: Array, _subtype_filter: Array, _owner: HenVirtualCNode) -> void:
	var is_input: bool = _is_input

	match identity.sub_type:
		HenVirtualCNode.SubType.SIGNAL_ENTER:
			if _is_input: is_input = false
			else: return

	# filtering sub_types
	if not _subtype_filter.is_empty() and not _subtype_filter.has(identity.sub_type):
		return

	clear_in_out(is_input)

	for input_data: Dictionary in _new_inputs:
		var in_out: HenVCInOutData = on_in_out_added(_owner, is_input, input_data)

		match identity.sub_type:
			HenVirtualCNode.SubType.SIGNAL_CONNECTION, HenVirtualCNode.SubType.SIGNAL_DISCONNECTION:
				in_out.reset_input_value()

	cnode_need_update.emit()
