@tool
class_name HenPopupContainer extends Panel

const ANCHOR_GAP: float = 8.0

signal closed

var _default_panel_style: StyleBox
var _transparent_panel_style: StyleBoxEmpty = StyleBoxEmpty.new()
var _layout: HenGeneralPopup.Layout = HenGeneralPopup.Layout.CENTER


func _ready() -> void:
	_default_panel_style = get('theme_override_styles/panel')
	gui_input.connect(_on_gui)


func _on_gui(_event: InputEvent) -> void:
	if _event is InputEventMouseButton:
		if _event.pressed:
			if _event.button_index == MOUSE_BUTTON_LEFT or _event.button_index == MOUSE_BUTTON_RIGHT:
				hide_popup()


func clean() -> void:
	var container = get_node('%GeneralPopUp').get_child(0)
	# cleaning other controls of popup
	for node in container.get_children():
		container.remove_child(node)
		node.queue_free()


func show_content(_content: Control, opts: Dictionary = {}) -> HenPopupContainer:
	var gp: PanelContainer = get_node('%GeneralPopUp')
	var container = gp.get_child(0)
	var global: HenGlobal = Engine.get_singleton(&'Global')

	_layout = opts.get('layout', HenGeneralPopup.Layout.CENTER)
	var lod: float = opts.get('lod', _default_lod_for(_layout))
	var min_size: Vector2 = opts.get('min_size', Vector2.ZERO)
	var blur: bool = opts.get('blur', false)

	clean()
	container.add_child(_content)

	if min_size != Vector2.ZERO:
		gp.custom_minimum_size = min_size

	_apply_layout(gp, opts)
	_apply_panel_style(lod, blur)

	modulate = Color.WHITE
	show()

	gp.pivot_offset = gp.size / 2.0
	var tween: Tween = get_tree().create_tween()

	gp.scale = Vector2(.95, .95)
	gp.modulate.a = 0.0

	tween.set_parallel(true)
	tween.tween_property(gp, 'scale', Vector2.ONE, .4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(gp, 'modulate:a', 1.0, .4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	global.CAM.can_scroll = false

	return self


func _default_lod_for(layout: HenGeneralPopup.Layout) -> float:
	if layout == HenGeneralPopup.Layout.ANCHORED:
		return 0.0
	return 1.0


func _apply_panel_style(lod: float, blur: bool) -> void:
	_tune_blur_shader(blur)

	if blur or (lod > 0 and _default_panel_style):
		add_theme_stylebox_override('panel', _default_panel_style)
	else:
		add_theme_stylebox_override('panel', _transparent_panel_style)


func _tune_blur_shader(blur: bool) -> void:
	if not material is ShaderMaterial:
		return

	var m: ShaderMaterial = material as ShaderMaterial
	if blur:
		m.set_shader_parameter('transparency', 0.08)
		m.set_shader_parameter('lod', 2.0)
	else:
		m.set_shader_parameter('transparency', 0.6)
		m.set_shader_parameter('lod', 3.0)


func _apply_layout(gp: PanelContainer, opts: Dictionary) -> void:
	match _layout:
		HenGeneralPopup.Layout.CENTER:
			_apply_center_layout(gp)
		HenGeneralPopup.Layout.COMPACT:
			_apply_compact_layout(gp)
		HenGeneralPopup.Layout.ANCHORED:
			_apply_anchored_layout(gp, opts)


func _apply_center_layout(gp: PanelContainer) -> void:
	gp.anchor_left = 0.2
	gp.anchor_top = 0.05
	gp.anchor_right = 0.8
	gp.anchor_bottom = 0.9
	gp.offset_left = 0.0
	gp.offset_top = 0.0
	gp.offset_right = 0.0
	gp.offset_bottom = 0.0
	gp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER | Control.SIZE_EXPAND
	gp.size_flags_vertical = Control.SIZE_SHRINK_CENTER | Control.SIZE_EXPAND


func _apply_compact_layout(gp: PanelContainer) -> void:
	_reset_anchors(gp)
	_position_anchored.call_deferred(gp, {})


func _apply_anchored_layout(gp: PanelContainer, opts: Dictionary) -> void:
	_reset_anchors(gp)
	_position_anchored.call_deferred(gp, opts)


func _reset_anchors(gp: PanelContainer) -> void:
	gp.anchor_left = 0.0
	gp.anchor_top = 0.0
	gp.anchor_right = 0.0
	gp.anchor_bottom = 0.0
	gp.grow_horizontal = Control.GROW_DIRECTION_END
	gp.grow_vertical = Control.GROW_DIRECTION_END
	gp.offset_left = 0.0
	gp.offset_top = 0.0
	gp.offset_right = 0.0
	gp.offset_bottom = 0.0
	gp.size_flags_horizontal = 0
	gp.size_flags_vertical = 0


func _position_anchored(gp: PanelContainer, opts: Dictionary) -> void:
	if not is_instance_valid(gp):
		return

	# force gp to fit content (or custom_minimum_size, whichever is bigger)
	var sz: Vector2 = gp.get_combined_minimum_size()
	var anchor_to: Control = opts.get('anchor_to', null)
	var side: int = opts.get('side', SIDE_RIGHT)

	# fill the axis perpendicular to `side` using anchor_to's size
	if opts.get('fill_axis', false) and anchor_to and is_instance_valid(anchor_to):
		var anchor_rect: Rect2 = anchor_to.get_global_rect()
		if side == SIDE_LEFT or side == SIDE_RIGHT:
			sz.y = anchor_rect.size.y
		else:
			sz.x = anchor_rect.size.x

	gp.size = sz

	var pos: Vector2 = opts.get('pos', Vector2.INF)
	var offset: Vector2 = opts.get('offset', Vector2.ZERO)

	if pos == Vector2.INF:
		if anchor_to and is_instance_valid(anchor_to):
			pos = _pos_relative_to(anchor_to, side, gp.size)
		else:
			var rect: Rect2 = (Engine.get_singleton(&'Global') as HenGlobal).CNODE_UI.get_viewport_rect()
			pos = Vector2(rect.position.x + (rect.size.x - gp.size.x) * 0.5, rect.position.y + (rect.size.y - gp.size.y) * 0.5)

	gp.position = pos + offset
	HenUtils.reposition_control_inside(gp)


func _pos_relative_to(anchor_to: Control, side: int, sz: Vector2) -> Vector2:
	var rect: Rect2 = anchor_to.get_global_rect()
	match side:
		SIDE_LEFT:
			return Vector2(rect.position.x - sz.x - ANCHOR_GAP, rect.position.y)
		SIDE_RIGHT:
			return Vector2(rect.position.x + rect.size.x + ANCHOR_GAP, rect.position.y)
		SIDE_TOP:
			return Vector2(rect.position.x, rect.position.y - sz.y - ANCHOR_GAP)
		SIDE_BOTTOM:
			return Vector2(rect.position.x, rect.position.y + rect.size.y + ANCHOR_GAP)
	return rect.position


func move(_pos: Vector2) -> void:
	var gp = get_node('%GeneralPopUp')
	gp.position += _pos
	HenUtils.reposition_control_inside(gp)


func show_container() -> void:
	(Engine.get_singleton(&'Global') as HenGlobal).CAM.can_scroll = false
	show()


func hide_popup() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	global.CAM.can_scroll = true
	global.CURRENT_INSPECTOR = null
	hide()

	closed.emit()
