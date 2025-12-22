class_name HenVirtualCNodeFlow extends Resource

@export var flow_inputs: Array[HenVCFlow]
@export var flow_outputs: Array[HenVCFlow]

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
		(Engine.get_singleton(&'ToastContainer') as HenToast).notify.call_deferred("Not Found HenTypeFlow Connections: Id -> " + str(_id) + " or To Id -> " + str(_to_id), HenToast.MessageType.ERROR)
		return null

	var flow_connection: HenVCFlowConnectionData = HenVCFlowConnectionData.new()

	flow_connection.from_id = flow_output.id
	flow_connection.to_id = flow_input.id
	flow_connection.from = _from
	flow_connection.to = _to

	return HenVCFlowConnectionReturn.new(flow_connection)


func get_flow_input_connection_command(_id: int) -> HenVCFlowConnectionReturn:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	for connection: HenVCFlowConnectionData in global.SAVE_DATA.get_flow_connections_by_id(identity.id):
		if connection.to_id == _id:
			return HenVCFlowConnectionReturn.new(connection)

	return null

func get_flow_output_connection_command(_id: int) -> HenVCFlowConnectionReturn:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	for connection: HenVCFlowConnectionData in global.SAVE_DATA.get_flow_connections_by_id(identity.id):
		if connection.from_id == _id:
			return HenVCFlowConnectionReturn.new(connection)

	return null


func create_input_flow_connection(_owner: HenVirtualCNode) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	flow_outputs.append(HenVCFlow.create(_owner, {name = 'Flow ' + str(global.SAVE_DATA.get_flow_connections_by_id(identity.id).size())}))
	cnode_need_update.emit()


func flow_input_has_connection(_id: int, _input_id: int) -> bool:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	for flow_connection: HenVCFlowConnectionData in global.SAVE_DATA.get_flow_connections_by_id(identity.id):
		if not flow_connection.get_to():
			continue
		
		if flow_connection.to_id == _id and flow_connection.get_to().identity.id == _input_id:
			return true

	return false


func flow_output_has_connection(_id: int, _output_id: int) -> bool:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	for flow_connection: HenVCFlowConnectionData in global.SAVE_DATA.get_flow_connections_by_id(identity.id):
		if not flow_connection.get_from():
			continue

		if flow_connection.from_id == _id and flow_connection.get_from().identity.id == _output_id:
			return true

	return false


func get_flow_input_connection(_id: int, _virtual_cnode: HenVirtualCNode) -> HenVCFlowConnectionData:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	for flow_connection: HenVCFlowConnectionData in global.SAVE_DATA.get_flow_connections_by_id(identity.id):
		if flow_connection.get_to() == _virtual_cnode and flow_connection.to_id == _id:
			return flow_connection

	return null


func get_flow_output_connection(_id: int, _virtual_cnode: HenVirtualCNode) -> HenVCFlowConnectionData:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	for flow_connection: HenVCFlowConnectionData in global.SAVE_DATA.get_flow_connections_by_id(identity.id):
		if flow_connection.get_from() == _virtual_cnode and flow_connection.from_id == _id:
			return flow_connection

	return null


func on_flow_added(_is_input: bool, _data: Dictionary, _owner: HenVirtualCNode) -> void:
	# restrict creation by sub_type
	match identity.sub_type:
		HenVirtualCNode.SubType.MACRO_INPUT:
			if not _is_input: return
			_is_input = not _is_input
		HenVirtualCNode.SubType.MACRO_OUTPUT:
			if _is_input: return
			_is_input = not _is_input

	var flow: HenVCFlow = HenVCFlow.create(_owner, _data)

	if _is_input:
		flow_inputs.append(flow)
	else:
		flow_outputs.append(flow)
	
	if _data.has('id'):
		(Engine.get_singleton(&'Global') as HenGlobal).SIDE_BAR_LIST_CACHE[_data.id] = flow

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
	if _is_input:
		flow_inputs.erase(_flow_ref)
	else:
		flow_outputs.erase(_flow_ref)
	
	remove_flow_connection(_flow_ref)
	cnode_need_update.emit()


func remove_flow_connection(_flow_ref: HenVCFlow) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var connection_remove: Array = []
	var flow_connections: Array = global.SAVE_DATA.get_flow_connections_by_id(identity.id)

	for connection: HenVCFlowConnectionData in flow_connections:
		if _flow_ref.id == connection.from_id:
			connection_remove.append(connection)

	for connection: HenVCFlowConnectionData in connection_remove:
		global.SAVE_DATA.remove_flow_connection(connection)

		if connection.line_ref:
			connection.line_ref.visible = false

		connection.get_from().flow.cnode_need_update.emit()
	
	cnode_need_update.emit()


func on_delete_flow_state(_ref: HenVCFlow) -> void:
	on_flow_deleted(true, _ref)


func change_flow_name(_name: String, _ref: HenVCFlow) -> void:
	_ref.name = _name
	cnode_need_update.emit()
