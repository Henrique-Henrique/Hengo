class_name HenVirtualCNodeFlow extends RefCounted

var flow_connections: Array = []
var from_flow_connections: Array = []
var identity: HenVirtualCNodeIdentity

signal cnode_need_update

func _init(_identity: HenVirtualCNodeIdentity) -> void:
	identity = _identity

func get_flow(_id: int) -> HenVCFlowConnection:
	for flow: HenVCFlowConnection in flow_connections:
		if flow.id == _id:
			return flow
	
	return null


func get_from_flow(_id: int) -> HenVCFlowConnection:
	for flow: HenVCFlowConnection in from_flow_connections:
		if flow.id == _id:
			return flow
	
	return null


func add_flow_connection(_id: int, _to_id: int, _from: WeakRef, _to: WeakRef) -> HenVCFlowConnectionReturn:
	if not _to or not _to.get_ref():
		push_error('Not Found To: Id -> ', _to_id)
		return null

	var flow_connection: HenVCFlowConnectionData = get_flow(_id)
	var flow_from_connection: HenVCFromFlowConnectionData = (_to.get_ref() as HenVirtualCNode).flow.get_from_flow(_to_id)

	if not flow_connection or not flow_from_connection:
		push_error('Not Found Flow Connections: Id -> ', _id, ' or To Id -> ', _to_id)
		return null

	return HenVCFlowConnectionReturn.new(flow_connection, _id, _to, _to_id, _from, flow_from_connection)


func get_flow_connection(_from: WeakRef, _id: int) -> HenVCFlowConnectionReturn:
	var flow_connection: HenVCFlowConnectionData = get_flow(_id)

	if not flow_connection or (not flow_connection or (flow_connection.to and not flow_connection.to.get_ref())):
		return null

	return HenVCFlowConnectionReturn.new(flow_connection, _id, flow_connection.to, flow_connection.to_id, _from, flow_connection.to_from_ref)


func create_flow_connection() -> void:
	flow_connections.append(HenVCFlowConnectionData.new({name = 'Flow ' + str(flow_connections.size())}))
	cnode_need_update.emit()


func from_flow_has_connection(_id: int) -> bool:
	for from_flow: HenVCFromFlowConnectionData in from_flow_connections:
		if from_flow.id == _id:
			return not from_flow.from_connections.is_empty()

	return false


func flow_has_connection(_id: int) -> bool:
	for flow: HenVCFlowConnectionData in flow_connections:
		if flow.id == _id:
			return not flow.to or flow.to.get_ref() != null

	return false


func move_flow(_direction: HenArrayItem.ArrayMove, _ref: HenVCFlowConnectionData, _is_input: bool) -> void:
	var arr: Array

	if _is_input:
		arr = from_flow_connections
	else:
		arr = flow_connections

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

	var flow: HenVCFlowConnection

	if _is_input:
		flow = HenVCFromFlowConnectionData.new(_data)
		from_flow_connections.append(flow)
	else:
		flow = HenVCFlowConnectionData.new(_data)
		flow_connections.append(flow)
	
	
	if _data.has('id'):
		HenGlobal.SIDE_BAR_LIST_CACHE[_data.id] = flow

	flow.moved.connect(on_flow_moved)
	flow.deleted.connect(on_flow_deleted)
	flow.update_changes.connect(on_need_update)

	cnode_need_update.emit()


func on_need_update() -> void:
	cnode_need_update.emit()


func on_flow_moved(_is_input: bool, _pos: int, _flow_ref: HenVCFlowConnection) -> void:
	var index_slice: int = 0

	if _is_input:
		HenUtils.move_array_item_to_idx(from_flow_connections, _flow_ref, _pos + index_slice)
	else:
		HenUtils.move_array_item_to_idx(flow_connections, _flow_ref, _pos + index_slice)
	
	cnode_need_update.emit()


func on_flow_deleted(_is_input: bool, _flow_ref: HenVCFlowConnection) -> void:
	if _is_input:
		var flow: HenVCFlowConnectionData = _flow_ref as HenVCFlowConnectionData
		flow_connections.erase(flow)

		if flow.line_ref:
			flow.line_ref.visible = false

		flow.line_ref = null
		if flow.to_from_ref: flow.to_from_ref.from_connections.erase(flow)
	else:
		var flow: HenVCFromFlowConnectionData = _flow_ref as HenVCFromFlowConnectionData
		
		for connection: HenVCFlowConnectionData in flow.from_connections:
			if connection.line_ref:
				connection.line_ref.visible = false
			
			connection.line_ref = null
			(connection.from.get_ref() as HenVirtualCNode).flow.flow_connections.erase(connection)
		
		from_flow_connections.erase(flow)

	cnode_need_update.emit()


func on_delete_flow_state(_ref: HenVCFlowConnectionData) -> void:
	on_flow_deleted(true, _ref)


func change_flow_name(_name: String, _ref: HenVCFlowConnectionData) -> void:
	_ref.name = _name
	cnode_need_update.emit()
