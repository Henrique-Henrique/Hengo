@tool
class_name HenVCFlowConnectionData extends Resource

@export var id: int
@export var from_id: int
@export var to_id: int
@export var from_node_id: int
@export var to_node_id: int

var line_ref: HenFlowConnectionLine = null
var from_old_pos: Vector2 = Vector2.ZERO
var to_old_pos: Vector2 = Vector2.ZERO


func _init() -> void:
	id = (Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()


func get_from(_save_data: HenSaveData) -> HenVirtualCNode:
	return _save_data.get_cnode_by_id(from_node_id)


func get_to(_save_data: HenSaveData) -> HenVirtualCNode:
	return _save_data.get_cnode_by_id(to_node_id)