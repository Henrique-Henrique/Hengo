@tool
class_name HenScriptTabRow extends PanelContainer

signal pressed(save_data: HenSaveData)

const ROW_HEIGHT: int = 32

var save_data: HenSaveData

var _is_active: bool = false
var _is_collapsed: bool = false

var _hbox: HBoxContainer
var _icon: TextureRect
var _name_label: Label

var _normal_sb: StyleBoxFlat
var _active_sb: StyleBoxFlat
var _tooltip: String = ''


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size.y = ThemeUtils.fs(ROW_HEIGHT)
	_build_styles()
	_build_children()
	_apply_visual_state()
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))


func setup(_save_data: HenSaveData) -> void:
	save_data = _save_data

	var _name: String = _save_data.identity.name
	var _type: StringName = _save_data.identity.type

	_tooltip = '[b]' + _name + '[/b]'
	if not String(_type).is_empty():
		_tooltip += '\n[color=#5f6a7a]' + String(_type) + '[/color]'

	if _name_label:
		_name_label.text = _name
	if _icon:
		if not String(_type).is_empty():
			_icon.texture = HenUtils.get_icon_texture(_type)
			_icon.modulate = HenUtils.get_type_parent_color(_type, 1.0, Color.WHITE).lightened(0.25)
			_icon.visible = true
		else:
			_icon.visible = false


func _on_hover(hovered: bool) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global or not global.TOOLTIP:
		return

	if hovered and not _tooltip.is_empty():
		global.TOOLTIP.go_to(get_global_mouse_position(), _tooltip)
	else:
		global.TOOLTIP.close()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			pressed.emit(save_data)


func set_active(_active: bool) -> void:
	_is_active = _active
	_apply_visual_state()


func set_collapsed(_collapsed: bool) -> void:
	_is_collapsed = _collapsed
	if _name_label:
		_name_label.visible = not _collapsed
	if _hbox:
		_hbox.alignment = BoxContainer.ALIGNMENT_CENTER if _collapsed else BoxContainer.ALIGNMENT_BEGIN


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
	_hbox.add_theme_constant_override('separation', 6)
	_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hbox)

	_icon = TextureRect.new()
	var _icon_size: int = ThemeUtils.fs(16)
	_icon.custom_minimum_size = Vector2(_icon_size, _icon_size)
	# shrink-center keeps the icon at its size instead of stretching to row height
	_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hbox.add_child(_icon)

	_name_label = Label.new()
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name_label.clip_text = true
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hbox.add_child(_name_label)


func _apply_visual_state() -> void:
	add_theme_stylebox_override('panel', _active_sb if _is_active else _normal_sb)
