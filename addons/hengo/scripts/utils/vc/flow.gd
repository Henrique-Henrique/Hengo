@tool
class_name HenVCFlow extends Resource

@export var name: String
@export var id: int = -1


static func create(_owner: HenVirtualCNode, _data: Dictionary = {}) -> HenVCFlow:
	var flow: HenVCFlow = HenVCFlow.new()
	flow.name = _data.name if _data.has('name') else ''
	flow.id = _data.id if _data.has('id') else (Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()
	return flow


func create_virtual_connection(_vc: HenVirtualCNode, _config: Dictionary) -> HenVCFlowConnectionReturn:
	return _vc.add_flow_connection(
		id,
		_config.to_id,
		_config.to_cnode
	)


func on_create_connection_request(_vc: HenVirtualCNode) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var connection: HenVCFlowConnectionReturn = create_virtual_connection(_vc, global.flow_connection_to_data)
					
	if connection:
		global.history.create_action('Add Connection')
		global.history.add_do_method(connection.add)
		global.history.add_do_reference(connection)
		global.history.add_undo_method(connection.remove)
		global.history.commit_action()
	

func on_flow_input_hover(_id: int, _vc: HenVirtualCNode) -> void:
	(Engine.get_singleton(&'Global') as HenGlobal).flow_connection_to_data = {
		to_cnode = _vc,
		to_id = _id
	}
