@tool
class_name HenVCFlowConnectionData extends HenVCFlowConnection

var line_ref: HenFlowConnectionLine
var from_id: int
var to_id: int
var from_pos: Vector2
var to_pos: Vector2
var from: HenVirtualCNode
var to: HenVirtualCNode
var to_from_ref: HenVCFromFlowConnection


func get_save() -> Dictionary:
	return {
		id = id,
		from_id = from_id,
		to_id = to_id,
		to_vc_id = to.id
	}