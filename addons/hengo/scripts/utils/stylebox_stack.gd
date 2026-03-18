@tool
class_name StyleboxStack
extends StyleBox

@export var style_boxes: Array[StyleBox] = []:
	set(new_style_boxes):
		for box in style_boxes:
			if is_instance_valid(box):
				box.changed.disconnect(emit_changed)
		style_boxes = new_style_boxes
		for box in style_boxes:
			if is_instance_valid(box):
				box.changed.connect(emit_changed)

func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if style_boxes.is_empty():
		return
	for box in style_boxes:
		box.draw(to_canvas_item, rect)


func _test_mask(point: Vector2, rect: Rect2) -> bool:
	return style_boxes.any( # if any can be clicked, everything can be
		func is_mask_clicked(style_box: StyleBox):
			return style_box.test_mask(point, rect)
	)


func _get_minimum_size() -> Vector2:
	return style_boxes.reduce(
		func find_biggest_minimum(biggest: Vector2, box: StyleBox):
			return biggest.max(box.get_minimum_size()),
		Vector2.ZERO
	)
