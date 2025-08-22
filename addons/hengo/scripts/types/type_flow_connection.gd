@tool
class_name HenTypeFlowConnection extends RefCounted

var from_id: int
var to_id: int
var from: WeakRef
var to: WeakRef
var to_vc_id: int

func _init(_data: Dictionary, _refs: HenTypeReferences) -> void:
	from = weakref(_refs.cnode_ref[int(_data.from_vc_id)])
	to = weakref(_refs.cnode_ref[int(_data.to_vc_id)])
	from_id = int(_data.from_id)
	to_id = int(_data.to_id)
	to_vc_id = int(_data.to_vc_id)


func get_from() -> HenTypeCnode:
	if not from:
		return null
	return from.get_ref()

func get_to() -> HenTypeCnode:
	if not to:
		return null
	return to.get_ref()