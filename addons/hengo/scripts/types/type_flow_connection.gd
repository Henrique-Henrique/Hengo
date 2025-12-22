@tool
class_name HenTypeFlowConnection extends RefCounted

var from_id: int
var to_id: int
var from: WeakRef
var to: WeakRef
var to_vc_id: int

func _init(_data: HenVCFlowConnectionData, _refs: HenTypeReferences) -> void:
	prints(_data, _data.from_id, _data.to_id, _data.get_from().identity.id, _data.get_to().identity.id)
	prints(_refs.cnode_ref)

	from = weakref(_refs.cnode_ref[int(_data.get_from().identity.id)])
	to = weakref(_refs.cnode_ref[int(_data.get_to().identity.id)])
	from_id = int(_data.from_id)
	to_id = int(_data.to_id)
	to_vc_id = int(_data.get_to().identity.id)


func get_from() -> HenTypeCnode:
	if not from:
		return null
	return from.get_ref()

func get_to() -> HenTypeCnode:
	if not to:
		return null
	return to.get_ref()