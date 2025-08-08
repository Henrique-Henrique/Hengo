@tool
class_name HenVCConnectionData extends RefCounted

var line_ref: HenConnectionLine
var from_id: int
var to_id: int
var from: WeakRef
var to: WeakRef
var from_type: StringName
var to_type: StringName
var input_ref: HenVCInOutData
var output_ref: HenVCInOutData
var from_old_pos: Vector2
var to_old_pos: Vector2


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
		from_id = from_id,
		to_id = to_id,
		from_vc_id = get_from().identity.id,
	}