class_name HenVirtualCNodeVisual extends RefCounted

var position: Vector2
var size: Vector2
var vc: WeakRef

const MOUSE_INSIDE_THRESHOLD = Vector2(25, 25)


func _init(_vc: HenVirtualCNode) -> void:
	vc = weakref(_vc)


func check_visibility(_rect: Rect2 = HenGlobal.CAM.get_rect()) -> void:
	var virtual_cnode: HenVirtualCNode = vc.get_ref()

	if not virtual_cnode:
		return

	virtual_cnode.state.is_showing = _rect.intersects(Rect2(
		position,
		size
	))

	if virtual_cnode.state.is_showing and virtual_cnode.references.cnode_ref == null:
		virtual_cnode.renderer.show()
	elif not virtual_cnode.state.is_showing:
		virtual_cnode.renderer.hide()


func check_mouse_inside() -> bool:
	var virtual_cnode: HenVirtualCNode = vc.get_ref()

	if not virtual_cnode:
		return false

	return Rect2(
		position - MOUSE_INSIDE_THRESHOLD,
		size + MOUSE_INSIDE_THRESHOLD * 2
	).has_point(HenGlobal.CAM.get_local_mouse_position())
