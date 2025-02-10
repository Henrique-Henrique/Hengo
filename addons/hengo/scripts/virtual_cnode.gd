@tool
class_name HenVirtualCNode extends RefCounted


var name: String
var id: int
var position: Vector2
var is_showing: bool = false
var cnode_ref: HenCnode


func check_visibility(_rect: Rect2) -> void:
	is_showing = _rect.has_point(position)

	if is_showing and cnode_ref == null:
		for cnode: HenCnode in HenGlobal.cnode_pool:
			if not cnode.visible:
				cnode.position = position
				cnode.visible = true
				cnode_ref = cnode
				break
	elif not is_showing:
		if cnode_ref:
			cnode_ref.visible = false
			cnode_ref = null


func reset() -> void:
	is_showing = false
	cnode_ref = null