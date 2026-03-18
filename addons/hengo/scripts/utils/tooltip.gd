@tool
class_name HenTooltip extends RichTextLabel

func go_to(_pos: Vector2, _content: String, _self_pos: Vector2 = Vector2.ZERO) -> void:
	if not visible:
		visible = true
		scale = Vector2.ZERO
		set_process(true)

		var tween: Tween = get_tree().create_tween()
		tween.tween_property(self, 'scale', Vector2.ONE, .1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	if text == _content:
		_update_position(_pos, _self_pos)
		return

	text = _content
	autowrap_mode = TextServer.AUTOWRAP_OFF
	custom_minimum_size = Vector2.ZERO
	clip_contents = false
	fit_content = true
	reset_size()

	# restrict max size based on viewport
	var editor_scale: float = EditorInterface.get_editor_scale() if Engine.is_editor_hint() else 1.0
	var vp_size: Vector2 = get_viewport_rect().size
	var max_w: float = max(500.0 * editor_scale, vp_size.x * 0.4)
	var max_h: float = max(300.0 * editor_scale, vp_size.y * 0.4)

	if size.x > max_w:
		autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		custom_minimum_size.x = max_w
		reset_size()

	if size.y > max_h:
		fit_content = false
		custom_minimum_size.y = max_h
		size.y = max_h
		clip_contents = true

	_update_position(_pos, _self_pos)


func _process(_delta: float) -> void:
	if visible:
		_update_position(get_global_mouse_position(), Vector2.ZERO)


func _update_position(_pos: Vector2, _self_pos: Vector2 = Vector2.ZERO) -> void:
	var target_pos: Vector2 = _pos + (size * _self_pos)
	
	var vp_size: Vector2 = get_viewport_rect().size
	target_pos.x = clampf(target_pos.x, 0.0, vp_size.x - size.x)
	target_pos.y = clampf(target_pos.y, 0.0, vp_size.y - size.y)
	
	global_position = target_pos


func close() -> void:
	text = ''
	visible = false
	set_process(false)
