@tool
class_name HenVCFlow extends Resource

@export var name: String
@export var id: int = -1
@export var owner: Resource # TODO: remove this reference

signal update_changes
signal data_changed
signal moved
signal deleted


static func create(_owner: HenVirtualCNode, _data: Dictionary = {}) -> HenVCFlow:
	var flow: HenVCFlow = HenVCFlow.new()
	flow.owner = _owner
	flow.name = _data.name if _data.has('name') else ''
	flow.id = _data.id if _data.has('id') else (Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()
	return flow


func get_owner() -> HenVirtualCNode:
	return owner


func _on_move(_pos: int) -> void:
	moved.emit(self, _pos, self)


func _on_delete(_is_input: bool) -> void:
	deleted.emit(_is_input, self)


func on_data_changed(_name: String, _value) -> void:
	set(_name, _value)
	update_changes.emit()


func create_virtual_connection(_config: Dictionary) -> HenVCFlowConnectionReturn:
	return get_owner().add_flow_connection(
		id,
		_config.to_id,
		_config.to_cnode
	)


func on_create_connection_request() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var connection: HenVCFlowConnectionReturn = create_virtual_connection(global.flow_connection_to_data)
					
	if connection:
		global.history.create_action('Add Connection')
		global.history.add_do_method(connection.add)
		global.history.add_do_reference(connection)
		global.history.add_undo_method(connection.remove)
		global.history.commit_action()
	

func on_flow_input_hover(_id: int) -> void:
	(Engine.get_singleton(&'Global') as HenGlobal).flow_connection_to_data = {
		to_cnode = get_owner(),
		to_id = _id
	}
