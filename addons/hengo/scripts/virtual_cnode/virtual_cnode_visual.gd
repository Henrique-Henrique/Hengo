class_name HenVirtualCNodeVisual extends RefCounted

var position: Vector2
var size: Vector2

const MOUSE_INSIDE_THRESHOLD = Vector2(25, 25)

func check_mouse_inside() -> bool:
	return Rect2(
		position - MOUSE_INSIDE_THRESHOLD,
		size + MOUSE_INSIDE_THRESHOLD * 2
	).has_point(HenGlobal.CAM.get_local_mouse_position())
