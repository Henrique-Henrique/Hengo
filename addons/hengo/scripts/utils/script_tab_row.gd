@tool
class_name HenScriptTabRow extends PanelContainer

const ROW_HEIGHT: int = 32

var _is_active: bool = false
var _is_collapsed: bool = false

var _hbox: HBoxContainer
var _icon: TextureRect
var _name_label: Label

var _normal_sb: StyleBoxFlat
var _active_sb: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size.y = ROW_HEIGHT
	_build_styles()
	_build_children()
	_apply_visual_state()


func setup(_name: String, _type: StringName) -> void:
	if _name_label:
		_name_label.text = _name
	if _icon:
		if not String(_type).is_empty():
			_icon.texture = HenUtils.get_icon_texture(_type)
			_icon.modulate = HenUtils.get_type_parent_color(_type, 1.0, Color.WHITE).lightened(0.25)
			_icon.visible = true
		else:
			_icon.visible = false


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
	_icon.custom_minimum_size = Vector2(18, 18)
	_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
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
