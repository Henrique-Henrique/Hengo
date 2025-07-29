@tool
class_name HenVCConnectionData extends RefCounted

var from_id: int
var to_id: int
var line_ref: HenConnectionLine
var type: StringName


class InputConnectionData extends HenVCConnectionData:
	var from: HenVirtualCNode
	var from_ref: OutputConnectionData
	var from_old_pos: Vector2
	var from_type: StringName
	var input_ref: HenVCInOutData

	func get_save() -> Dictionary:
		return {
			from_id = from_id,
			to_id = to_id,
			from_vc_id = from.id,
		}


class OutputConnectionData extends HenVCConnectionData:
	var to: HenVirtualCNode
	var to_ref: InputConnectionData
	var to_old_pos: Vector2
	var to_type: StringName
	var output_ref: HenVCInOutData