@tool
class_name HenVCFlowConnectionData extends Resource

@export var id: int
@export var from_id: int
@export var to_id: int
@export var from: HenVirtualCNode
@export var to: HenVirtualCNode

var line_ref: HenFlowConnectionLine = null
var from_old_pos: Vector2 = Vector2.ZERO
var to_old_pos: Vector2 = Vector2.ZERO


func _init() -> void:
	id = (Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()


func get_from() -> HenVirtualCNode:
	return from


func get_to() -> HenVirtualCNode:
	return to


func get_save() -> Dictionary:
	return {
		from_id = from_id,
		to_id = to_id,
		from_vc_id = get_from().id,
		to_vc_id = get_to().id
	}
