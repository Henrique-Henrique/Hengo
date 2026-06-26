@tool
class_name HenDebugNodeRow extends PanelContainer

signal pressed(instance_id: int)

const ROW_HEIGHT: int = 30

var instance_id: int = -1

var _is_active: bool = false

var _hbox: HBoxContainer
var _name_label: Label
var _path_label: Label

var _normal_sb: StyleBoxFlat
var _active_sb: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size.y = ROW_HEIGHT
	_build_styles()
	_build_children()
	_apply_visual_state()
	gui_input.connect(_on_gui_input)


func setup(_node: Dictionary) -> void:
	instance_id = int(_node.get('id', -1))
	tooltip_text = String(_node.get('path', ''))

	if _name_label:
		_name_label.text = String(_node.get('name', '?'))
	if _path_label:
		_path_label.text = String(_node.get('path', ''))


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			pressed.emit(instance_id)


func set_active(_active: bool) -> void:
	_is_active = _active
	_apply_visual_state()


func _build_styles() -> void:
	_normal_sb = StyleBoxFlat.new()
	_normal_sb.bg_color = Color(1, 1, 1, 0)
	_normal_sb.corner_radius_top_left = 6
	_normal_sb.corner_radius_top_right = 6
	_normal_sb.corner_radius_bottom_left = 6
	_normal_sb.corner_radius_bottom_right = 6
	_normal_sb.content_margin_left = 8
	_normal_sb.content_margin_right = 6
	_normal_sb.content_margin_top = 4
	_normal_sb.content_margin_bottom = 4

	_active_sb = _normal_sb.duplicate()
	_active_sb.bg_color = Color(0.431, 0.565, 0.906, 0.22)
	_active_sb.border_color = Color(0.431, 0.565, 0.906, 0.6)
	_active_sb.border_width_left = 2


func _build_children() -> void:
	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override('separation', 8)
	_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hbox)

	_name_label = Label.new()
	_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name_label.clip_text = true
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hbox.add_child(_name_label)

	_path_label = Label.new()
	_path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_path_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_path_label.clip_text = true
	_path_label.modulate = Color(1, 1, 1, 0.45)
	_path_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hbox.add_child(_path_label)


func _apply_visual_state() -> void:
	add_theme_stylebox_override('panel', _active_sb if _is_active else _normal_sb)
