class_name HenVirtualCNodeIdentity extends RefCounted

var id: int
var name: String
var type: HenVirtualCNode.Type
var sub_type: HenVirtualCNode.SubType
var name_to_code: String
var category: StringName
var singleton_class: String

# references
var from_side_bar_id: int = -1
var from_id: int = -1

var vc: WeakRef

func _init(_vc: HenVirtualCNode) -> void:
	vc = weakref(_vc)


func on_change_name(_name: String) -> void:
	match sub_type:
		HenVirtualCNode.SubType.FUNC_INPUT, HenVirtualCNode.SubType.FUNC_OUTPUT:
			return

	name = _name
	
	if vc.get_ref(): vc.get_ref().renderer.update()
