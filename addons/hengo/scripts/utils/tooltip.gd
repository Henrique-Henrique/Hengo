@tool
class_name HenTooltip extends RichTextLabel

const SHOW_TIME: float = 0.13
const HIDE_TIME: float = 0.1
const START_SCALE: Vector2 = Vector2(0.97, 0.97)
const CURSOR_OFFSET: Vector2 = Vector2(16, 20)
const FOLLOW_SPEED: float = 26.0

var _tween: Tween
var _hiding: bool = false
var _dwell_token: int = 0


func go_to(_pos: Vector2, _content: String, _self_pos: Vector2 = Vector2.ZERO, _dwell: float = 0.0) -> void:
	_dwell_token += 1

	if _dwell > 0.0 and not visible:
		var token: int = _dwell_token

		await get_tree().create_timer(_dwell).timeout

		if token != _dwell_token or not is_inside_tree():
			return

		# the cursor moved while the wait ran, and the follow would slide in from there
		_pos = get_global_mouse_position()

	var fully_hidden: bool = not visible
	var reappear: bool = fully_hidden or _hiding

	if reappear:
		_kill_tween()
		_hiding = false
		visible = true
		set_process(true)

		# a cold show starts small and transparent; interrupting a fade-out just
		# springs back from where it is, so scanning a list stays continuous
		if fully_hidden:
			scale = START_SCALE
			modulate.a = 0.0

		# get_tree() and not create_tween(): a node-bound tween does not run in the @tool editor
		_tween = get_tree().create_tween().set_parallel(true)
		_tween.tween_property(self, 'scale', Vector2.ONE, SHOW_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.tween_property(self, 'modulate:a', 1.0, SHOW_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if text == _content and not reappear:
		_move_to(_pos, _self_pos)
		return

	text = _content
	autowrap_mode = TextServer.AUTOWRAP_OFF
	custom_minimum_size = Vector2.ZERO
	clip_contents = false
	fit_content = true
	reset_size()

	# restrict max size based on viewport
	var vp_size: Vector2 = get_viewport_rect().size
	var max_w: float = max(500.0, vp_size.x * 0.4)
	var max_h: float = max(300.0, vp_size.y * 0.4)

	if size.x > max_w:
		autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		custom_minimum_size.x = max_w
		reset_size()

	if size.y > max_h:
		fit_content = false
		custom_minimum_size.y = max_h
		size.y = max_h
		clip_contents = true

	global_position = _clamped(_pos + size * _self_pos)


func _process(delta: float) -> void:
	if not visible:
		return

	var target: Vector2 = _clamped(get_global_mouse_position() + CURSOR_OFFSET)
	global_position = global_position.lerp(target, clampf(delta * FOLLOW_SPEED, 0.0, 1.0))


func _move_to(_pos: Vector2, _self_pos: Vector2) -> void:
	global_position = _clamped(_pos + size * _self_pos)


# keeps the tooltip fully inside the viewport
func _clamped(_pos: Vector2) -> Vector2:
	var vp_size: Vector2 = get_viewport_rect().size
	return Vector2(
		clampf(_pos.x, 0.0, vp_size.x - size.x),
		clampf(_pos.y, 0.0, vp_size.y - size.y)
	)


func close() -> void:
	_dwell_token += 1

	if not visible or _hiding:
		return

	_hiding = true
	_kill_tween()

	_tween = get_tree().create_tween().set_parallel(true)
	_tween.tween_property(self, 'modulate:a', 0.0, HIDE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, 'scale', START_SCALE, HIDE_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.chain().tween_callback(_finish_close)


func _finish_close() -> void:
	if not _hiding:
		return

	text = ''
	visible = false
	_hiding = false
	set_process(false)


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
