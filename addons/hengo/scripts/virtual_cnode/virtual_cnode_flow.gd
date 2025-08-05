class_name HenVirtualCNodeFlow extends RefCounted

var flow_inputs: Array[HenVCFlow]
var flow_outputs: Array[HenVCFlow]
var flow_connections_2: Array[HenVCFlowConnectionData]

var identity: HenVirtualCNodeIdentity

signal cnode_need_update

func _init(_identity: HenVirtualCNodeIdentity) -> void:
	identity = _identity


func get_flow_input(_id: int) -> HenVCFlow:
	for flow: HenVCFlow in flow_inputs:
		if flow.id == _id:
			return flow
	
	return null


func get_flow_output(_id: int) -> HenVCFlow:
	for flow: HenVCFlow in flow_outputs:
		if flow.id == _id:
			return flow
	
	return null


func add_flow_connection(_id: int, _to_id: int, _from: HenVirtualCNode, _to: HenVirtualCNode) -> HenVCFlowConnectionReturn:
	var flow_input: HenVCFlow = _to.flow.get_flow_input(_to_id)
	var flow_output: HenVCFlow = get_flow_output(_id)

	if not flow_input or not flow_output:
		push_error('Not Found Flow Connections: Id -> ', _id, ' or To Id -> ', _to_id)
		return null

	var flow_connection: HenVCFlowConnectionData = HenVCFlowConnectionData.new()

	flow_connection.from_id = flow_output.id
	flow_connection.to_id = flow_input.id
	flow_connection.from = weakref(_from)
	flow_connection.to = weakref(_to)

	return HenVCFlowConnectionReturn.new(flow_connection, _id)


func get_flow_input_connection_command(_id: int) -> HenVCFlowConnectionReturn:
	for connection: HenVCFlowConnectionData in flow_connections_2:
		if connection.to_id == _id:
			return HenVCFlowConnectionReturn.new(connection)

	return null


func create_input_flow_connection() -> void:
	flow_connections_2.append(HenVCFlow.new({name = 'Flow ' + str(flow_connections_2.size())}))
	cnode_need_update.emit()


func flow_input_has_connection(_id: int) -> bool:
	for flow: HenVCFlowConnectionData in flow_connections_2:
		if flow.from_id == _id:
			return not flow.from or flow.from.get_ref() != null

	return false


func flow_output_has_connection(_id: int) -> bool:
	for flow: HenVCFlowConnectionData in flow_connections_2:
		if flow.to_id == _id:
			return not flow.to or flow.to.get_ref() != null

	return false


func move_flow(_direction: HenArrayItem.ArrayMove, _ref: HenVCFlowConnectionData, _is_input: bool) -> void:
	var arr: Array

	if _is_input:
		arr = flow_inputs
	else:
		arr = flow_outputs

	match _direction:
		HenArrayItem.ArrayMove.UP:
			HenUtils.move_array_item(arr, _ref, 1)
		HenArrayItem.ArrayMove.DOWN:
			HenUtils.move_array_item(arr, _ref, -1)

	cnode_need_update.emit()


func on_flow_added(_is_input: bool, _data: Dictionary) -> void:
	# restrict creation by sub_type
	match identity.sub_type:
		HenVirtualCNode.SubType.MACRO_INPUT:
			if not _is_input: return
			_is_input = not _is_input
		HenVirtualCNode.SubType.MACRO_OUTPUT:
			if _is_input: return
			_is_input = not _is_input

	var flow: HenVCFlow = HenVCFlow.new(_data)

	if _is_input:
		flow_inputs.append(flow)
	else:
		flow_outputs.append(flow)
	
	if _data.has('id'):
		HenGlobal.SIDE_BAR_LIST_CACHE[_data.id] = flow

	flow.moved.connect(on_flow_moved)
	flow.deleted.connect(on_flow_deleted)
	flow.update_changes.connect(on_need_update)

	cnode_need_update.emit()


func on_need_update() -> void:
	cnode_need_update.emit()


func on_flow_moved(_is_input: bool, _pos: int, _flow_ref: HenVCFlow) -> void:
	var index_slice: int = 0

	if _is_input:
		HenUtils.move_array_item_to_idx(flow_inputs, _flow_ref, _pos + index_slice)
	else:
		HenUtils.move_array_item_to_idx(flow_outputs, _flow_ref, _pos + index_slice)
	
	cnode_need_update.emit()


func on_flow_deleted(_is_input: bool, _flow_ref: HenVCFlow) -> void:
	# if _is_input:
	# 	var flow: HenVCFlowConnectionData = _flow_ref as HenVCFlowConnectionData
	# 	flow_connections.erase(flow)
	# 	if flow.line_ref:
	# 		flow.line_ref.visible = false
	# 	flow.line_ref = null
	# 	if flow.to_from_ref: flow.to_from_ref.from_connections.erase(flow)
	# else:
	# 	for connection: HenVCFlowConnectionData in flow.from_connections:
	# 		if connection.line_ref:
	# 			connection.line_ref.visible = false
	# 		connection.line_ref = null
	# 		(connection.from.get_ref() as HenVirtualCNode).flow.flow_connections.erase(connection)
	# 	flow_inputs.erase(flow)
	cnode_need_update.emit()


func on_delete_flow_state(_ref: HenVCFlow) -> void:
	on_flow_deleted(true, _ref)


func change_flow_name(_name: String, _ref: HenVCFlow) -> void:
	_ref.name = _name
	cnode_need_update.emit()
