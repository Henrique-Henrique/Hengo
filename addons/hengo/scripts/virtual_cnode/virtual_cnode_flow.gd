@tool
@abstract
class_name HenVirtualCNodeFlow extends HenVirtualCNodeRoute

@export var flow_inputs: Array[HenVCFlow]
@export var flow_outputs: Array[HenVCFlow]


func get_flow_input(_id: int, _save_data: HenSaveData) -> HenVCFlow:
	for flow: HenVCFlow in get_flow_inputs(_save_data):
		if flow.id == _id:
			return flow
	
	return null


func get_flow_output(_id: int, _save_data: HenSaveData) -> HenVCFlow:
	for flow: HenVCFlow in get_flow_outputs(_save_data):
		if flow.id == _id:
			return flow
	
	return null


func add_flow_connection_with_return(_id: int, _to_id: int, _from: HenVirtualCNode, _to: HenVirtualCNode) -> HenVCFlowConnectionReturn:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var flow_input: HenVCFlow = _to.get_flow_input(_to_id, global.SAVE_DATA)
	var flow_output: HenVCFlow = get_flow_output(_id, global.SAVE_DATA)

	if not flow_input or not flow_output:
		(Engine.get_singleton(&'ToastContainer') as HenToast).notify.call_deferred("Not Found HenTypeFlow Connections: Id -> " + str(_id) + " or To Id -> " + str(_to_id), HenToast.MessageType.ERROR)
		return null

	var flow_connection: HenVCFlowConnectionData = HenVCFlowConnectionData.new()

	flow_connection.from_id = flow_output.id
	flow_connection.to_id = flow_input.id
	flow_connection.from_node_id = _from.id
	flow_connection.to_node_id = _to.id

	return HenVCFlowConnectionReturn.new(flow_connection)


func get_flow_input_connection_command(_id: int) -> HenVCFlowConnectionReturn:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	for connection: HenVCFlowConnectionData in global.SAVE_DATA.get_flow_connections_by_id(id):
		if connection.to_id == _id:
			return HenVCFlowConnectionReturn.new(connection)

	return null


func get_flow_output_connection_command(_id: int) -> HenVCFlowConnectionReturn:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	for connection: HenVCFlowConnectionData in global.SAVE_DATA.get_flow_connections_by_id(id):
		if connection.from_id == _id:
			return HenVCFlowConnectionReturn.new(connection)

	return null


func create_input_flow_connection(_owner: HenVirtualCNode) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	flow_outputs.append(HenVCFlow.create(_owner, {name = 'Flow ' + str(global.SAVE_DATA.get_flow_connections_by_id(id).size())}))
	cnode_need_update.emit()


func flow_input_has_connection(_id: int, _input_id: int) -> bool:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	for flow_connection: HenVCFlowConnectionData in global.SAVE_DATA.get_flow_connections_by_id(id):
		if not flow_connection.get_to(global.SAVE_DATA):
			continue
		
		if flow_connection.to_id == _id and flow_connection.get_to(global.SAVE_DATA).id == _input_id:
			var from_node: HenVirtualCNode = flow_connection.get_from(global.SAVE_DATA)
			
			if from_node and from_node.get_flow_output(flow_connection.from_id, global.SAVE_DATA):
				return true

	return false


func flow_output_has_connection(_id: int, _output_id: int) -> bool:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	for flow_connection: HenVCFlowConnectionData in global.SAVE_DATA.get_flow_connections_by_id(id):
		if not flow_connection.get_from(global.SAVE_DATA):
			continue

		if flow_connection.from_id == _id and flow_connection.get_from(global.SAVE_DATA).id == _output_id:
			return true

	return false


func get_flow_input_connection_data(_id: int, _virtual_cnode: HenVirtualCNode) -> HenVCFlowConnectionData:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	for flow_connection: HenVCFlowConnectionData in global.SAVE_DATA.get_flow_connections_by_id(id):
		if flow_connection.get_to(global.SAVE_DATA) == _virtual_cnode and flow_connection.to_id == _id:
			return flow_connection

	return null


func get_flow_output_connection_data(_id: int, _virtual_cnode: HenVirtualCNode) -> HenVCFlowConnectionData:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	for flow_connection: HenVCFlowConnectionData in global.SAVE_DATA.get_flow_connections_by_id(id):
		if flow_connection.get_from(global.SAVE_DATA) == _virtual_cnode and flow_connection.from_id == _id:
			return flow_connection

	return null


func on_flow_added(_is_input: bool, _data: Dictionary, _owner: HenVirtualCNode) -> void:
	# restrict creation by sub_type
	match sub_type:
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
	var flow_connections: Array = global.SAVE_DATA.get_flow_connections_by_id(id)

	for connection: HenVCFlowConnectionData in flow_connections:
		if _flow_ref.id == connection.from_id:
			connection_remove.append(connection)

	for connection: HenVCFlowConnectionData in connection_remove:
		global.SAVE_DATA.remove_flow_connection(connection)

		if connection.line_ref:
			connection.line_ref.visible = false

		connection.get_from(global.SAVE_DATA).cnode_need_update.emit()
	
	cnode_need_update.emit()


func on_delete_flow_state(_ref: HenVCFlow) -> void:
	on_flow_deleted(true, _ref)


func change_flow_name(_name: String, _ref: HenVCFlow) -> void:
	_ref.name = _name
	cnode_need_update.emit()


func get_flow_inputs(_save_data: HenSaveData) -> Array[HenVCFlow]:
	var res = get_res(_save_data)

	if res and res is HenSaveResType:
		var new_data_list: Array = (res as HenSaveResType).get_flow_inputs(sub_type)

		for i: int in new_data_list.size():
			var data: Dictionary = new_data_list[i]

			if i < flow_inputs.size():
				var existing: HenVCFlow = flow_inputs[i]
				if existing.id != data.get('id'): existing.id = data.get('id')
				if data.has('name') and existing.name != data.get('name'): existing.name = data.get('name')
			else:
				create_flow(true, data)
		
		if flow_inputs.size() > new_data_list.size():
			flow_inputs.resize(new_data_list.size())
			
	return flow_inputs


func get_flow_outputs(_save_data: HenSaveData) -> Array[HenVCFlow]:
	var res = get_res(_save_data)

	if res and res is HenSaveResType:
		var new_data_list: Array = (res as HenSaveResType).get_flow_outputs(sub_type)

		for i: int in new_data_list.size():
			var data: Dictionary = new_data_list[i]

			if i < flow_outputs.size():
				var existing: HenVCFlow = flow_outputs[i]
				if existing.id != data.get('id'): existing.id = data.get('id')
				if data.has('name') and existing.name != data.get('name'): existing.name = data.get('name')
			else:
				create_flow(false, data)
		
		if flow_outputs.size() > new_data_list.size():
			flow_outputs.resize(new_data_list.size())
	
	return flow_outputs


func create_flow(_is_input: bool, _data: Dictionary) -> HenVCFlow:
	var flow: HenVCFlow = HenVCFlow.create(self, _data)

	if _is_input:
		flow_inputs.append(flow)
	else:
		flow_outputs.append(flow)
	
	cnode_need_update.emit()
	return flow
