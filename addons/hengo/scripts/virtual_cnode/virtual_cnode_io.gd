class_name HenVirtualCNodeIO extends RefCounted

var inputs: Array[HenVCInOutData]
var outputs: Array[HenVCInOutData]

var input_connections: Array = []
var output_connections: Array = []

var vc: WeakRef

func _init(_vc: HenVirtualCNode) -> void:
	vc = weakref(_vc)


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


func create_input_connection(_id: int, _from_id: int, _from: HenVirtualCNode) -> HenVCConnectionReturn:
	var virtual_cnode: HenVirtualCNode = vc.get_ref()

	if not virtual_cnode:
		return null

	var input_connection: HenVCConnectionData.InputConnectionData = HenVCConnectionData.InputConnectionData.new()
	var output_connection: HenVCConnectionData.OutputConnectionData = HenVCConnectionData.OutputConnectionData.new()

	var input: HenVCInOutData = get_input(_id)
	var output: HenVCInOutData = _from.io.get_output(_from_id)

	if not input or not output:
		return
	
	if not HenUtils.is_type_relation_valid(output.type, input.type):
		return

	# output
	output_connection.type = output.type
	output_connection.from_id = output.id
	output_connection.to_id = input.id

	output_connection.to = virtual_cnode
	output_connection.to_ref = input_connection
	output_connection.to_type = input.type
	output_connection.output_ref = output

	# inputs
	input_connection.from_id = output.id
	input_connection.to_id = input.id
	input_connection.type = input.type
	
	input_connection.from = _from
	input_connection.from_ref = output_connection
	input_connection.from_type = output.type
	input_connection.input_ref = input

	return HenVCConnectionReturn.new(input_connection, output_connection, _from, virtual_cnode, _id)


func add_input_connection(_idx: int, _from_id: int, _from: HenVirtualCNode) -> void:
	var connection: HenVCConnectionReturn = create_input_connection(_idx, _from_id, _from)
	if connection: connection.add(false)


func clear_in_out(_is_input: bool) -> void:
	if _is_input:
		inputs.clear()
	else:
		outputs.clear()


func input_has_connection(_id: int) -> bool:
	for input_connection: HenVCConnectionData.InputConnectionData in input_connections:
		if input_connection.to_id == _id:
			return true

	return false


func output_has_connection(_id: int) -> bool:
	for output_connection: HenVCConnectionData.OutputConnectionData in output_connections:
		if output_connection.from_id == _id:
			return true

	return false


func get_input_connection(_id: int) -> HenVCConnectionReturn:
	var virtual_cnode: HenVirtualCNode = vc.get_ref()

	if not virtual_cnode:
		return null

	for connection: HenVCConnectionData.InputConnectionData in input_connections:
		if connection.to_id == _id:
			return HenVCConnectionReturn.new(connection, connection.from_ref, connection.from, virtual_cnode)

	return null


func remove_inout_connection(_ref: HenVCInOutData) -> void:
	var virtual_cnode: HenVirtualCNode = vc.get_ref()

	if not virtual_cnode:
		return

	var input_remove: Array = []
	var output_remove: Array = []

	for connection: HenVCConnectionData.InputConnectionData in input_connections:
		if _ref.id == connection.to_id:
			input_remove.append(connection)
		
	for connection: HenVCConnectionData.OutputConnectionData in output_connections:
		if _ref.id == connection.from_id:
			output_remove.append(connection)

	for connection: HenVCConnectionData.InputConnectionData in input_remove:
		connection.from.io.output_connections.erase(connection.from_ref)
		input_connections.erase(connection)

		if connection.line_ref:
			connection.line_ref.visible = false

		connection.from.renderer.update()
	
	for connection: HenVCConnectionData.OutputConnectionData in output_remove:
		connection.to.io.input_connections.erase(connection.to_ref)
		output_connections.erase(connection)

		if connection.line_ref:
			connection.line_ref.visible = false

		connection.to.renderer.update()
	
	virtual_cnode.renderer.update()


func on_in_out_moved(_is_input: bool, _pos: int, _in_ou_ref: HenVCInOutData) -> void:
	var virtual_cnode: HenVirtualCNode = vc.get_ref()

	if not virtual_cnode:
		return

	var is_input: bool = _is_input
	var index_slice: int = 0

	match virtual_cnode.identity.sub_type:
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

	virtual_cnode.renderer.update()


func on_in_out_deleted(_is_input: bool, _in_ou_ref: HenVCInOutData) -> void:
	var virtual_cnode: HenVirtualCNode = vc.get_ref()

	if not virtual_cnode:
		return

	var is_input: bool = _is_input

	match virtual_cnode.identity.sub_type:
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

	remove_inout_connection(_in_ou_ref)
	virtual_cnode.renderer.update()


func on_in_out_added(_is_input: bool, _data: Dictionary, _check_types: bool = true) -> HenVCInOutData:
	var virtual_cnode: HenVirtualCNode = vc.get_ref()

	if not virtual_cnode:
		return null

	# restrict creation by sub_type
	if _check_types:
		match virtual_cnode.identity.sub_type:
			HenVirtualCNode.SubType.FUNC_INPUT, HenVirtualCNode.SubType.MACRO_INPUT:
				if not _is_input: return
				_is_input = false
			HenVirtualCNode.SubType.FUNC_OUTPUT, HenVirtualCNode.SubType.MACRO_OUTPUT:
				if _is_input: return
				_is_input = true
			HenVirtualCNode.SubType.SIGNAL_ENTER:
				_is_input = false

	if _data.has('ref_id'):
		if not virtual_cnode.state.invalid:
			_data.ref = HenGlobal.SIDE_BAR_LIST_CACHE[int(_data.ref_id)]

	var in_out: HenVCInOutData = HenVCInOutData.new(_data)

	if _data.has('ref'):
		in_out.set_ref(_data.ref)

	in_out.moved.connect(on_in_out_moved)
	in_out.deleted.connect(on_in_out_deleted)
	in_out.update_changes.connect(virtual_cnode.renderer.update)
	in_out.type_changed.connect(on_in_out_type_changed)

	if _is_input:
		inputs.append(in_out)
	else:
		outputs.append(in_out)
	
	virtual_cnode.renderer.update()

	return in_out


func on_in_out_type_changed(_old_type: StringName, _type: StringName, _ref: HenVCInOutData) -> void:
	if HenUtils.is_type_relation_valid(_old_type, _type):
		remove_inout_connection(_ref)


func on_in_out_reset(_is_input: bool, _new_inputs: Array, _subtype_filter: Array = []) -> void:
	var virtual_cnode: HenVirtualCNode = vc.get_ref()

	if not virtual_cnode:
		return

	var is_input: bool = _is_input

	match virtual_cnode.identity.sub_type:
		HenVirtualCNode.SubType.SIGNAL_ENTER:
			if _is_input: is_input = false
			else: return

	# filtering sub_types
	if not _subtype_filter.is_empty() and not _subtype_filter.has(virtual_cnode.identity.sub_type):
		return

	clear_in_out(is_input)

	for input_data: Dictionary in _new_inputs:
		var in_out: HenVCInOutData = on_in_out_added(is_input, input_data)

		match virtual_cnode.identity.sub_type:
			HenVirtualCNode.SubType.SIGNAL_CONNECTION, HenVirtualCNode.SubType.SIGNAL_DISCONNECTION:
				in_out.reset_input_value()

	virtual_cnode.renderer.update()
