@tool
class_name HenVCFlowConnectionData extends RefCounted

var line_ref: HenFlowConnectionLine
var from_id: int
var to_id: int
var from_old_pos: Vector2
var to_old_pos: Vector2
var from: WeakRef
var to: WeakRef


func get_from() -> HenVirtualCNode:
	if not from:
		return null
	
	return from.get_ref()


func get_to() -> HenVirtualCNode:
	if not to:
		return null
	
	return to.get_ref()


func get_save() -> Dictionary:
	return {
		# id = id,
		# from_id = from_id,
		# to_id = to_id,
		# to_vc_id = (to.get_ref() as HenVirtualCNode).identity.id
	}


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		print('FLOW CONNECTION DELETED')
