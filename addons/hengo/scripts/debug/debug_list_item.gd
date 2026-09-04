@tool
class_name HenDebugListItem extends PanelContainer

# one recycled row of the debug list: either a per-script header or a node row.
# rendered by HenVirtualList, which calls set_item_data() on bind.

var _data: Dictionary = {}

var _margin: MarginContainer
var _hbox: HBoxContainer
var _icon: TextureRect
var _name_label: Label
var _path_label: Label

var _node_normal_sb: StyleBoxFlat
var _node_active_sb: StyleBoxFlat
var _header_sb: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_styles()
	_build_children()
	gui_input.connect(_on_gui_input)


func set_item_data(d: Dictionary) -> void:
	_data = d
	var is_header: bool = d.get('type', 'node') == 'header'

	mouse_default_cursor_shape = Control.CURSOR_ARROW if is_header else Control.CURSOR_POINTING_HAND

	if is_header:
		add_theme_stylebox_override('panel', _header_sb)
		_margin.add_theme_constant_override('margin_left', 6)
		var type: StringName = d.get('icon_type', &'')
		if not String(type).is_empty():
			_icon.texture = HenUtils.get_icon_texture(type)
			_icon.modulate = HenUtils.get_type_parent_color(type, 1.0, Color.WHITE).lightened(0.25)
			_icon.visible = true
		else:
			_icon.visible = false
		_name_label.text = String(d.get('name', ''))
		_name_label.add_theme_color_override('font_color', Color(0.86, 0.9, 1.0, 1))
		_path_label.visible = false
		tooltip_text = ''
	else:
		add_theme_stylebox_override('panel', _node_active_sb if d.get('active', false) else _node_normal_sb)
		_margin.add_theme_constant_override('margin_left', 22)
		_icon.visible = false
		_name_label.text = String(d.get('name', '?'))
		_name_label.remove_theme_color_override('font_color')
		_path_label.visible = true
		_path_label.text = String(d.get('path', ''))
		tooltip_text = String(d.get('path', ''))


func _on_gui_input(event: InputEvent) -> void:
	if _data.get('type', 'node') != 'node':
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
		if signal_bus:
			signal_bus.debug_instance_selected.emit(String(_data.get('script_id', '')), int(_data.get('id', -1)))


func _build_styles() -> void:
	_node_normal_sb = StyleBoxFlat.new()
	_node_normal_sb.bg_color = Color(1, 1, 1, 0)
	_node_normal_sb.set_corner_radius_all(6)
	_node_normal_sb.content_margin_top = 4
	_node_normal_sb.content_margin_bottom = 4

	_node_active_sb = _node_normal_sb.duplicate()
	_node_active_sb.bg_color = Color(0.431, 0.565, 0.906, 0.22)
	_node_active_sb.border_color = Color(0.431, 0.565, 0.906, 0.6)
	_node_active_sb.border_width_left = 2

	_header_sb = StyleBoxFlat.new()
	_header_sb.bg_color = Color(1, 1, 1, 0.04)
	_header_sb.content_margin_top = 4
	_header_sb.content_margin_bottom = 4


func _build_children() -> void:
	_margin = MarginContainer.new()
	_margin.add_theme_constant_override('margin_left', 8)
	_margin.add_theme_constant_override('margin_right', 8)
	_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_margin)

	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override('separation', 8)
	_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_margin.add_child(_hbox)

	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(16, 16)
	_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.visible = false
	_hbox.add_child(_icon)

	_name_label = Label.new()
	ThemeUtils.apply_font_size(_name_label, 13)
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.size_flags_stretch_ratio = 1.6
	_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name_label.clip_text = true
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hbox.add_child(_name_label)

	_path_label = Label.new()
	ThemeUtils.apply_font_size(_path_label, 11)
	_path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_label.size_flags_stretch_ratio = 1.0
	_path_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_path_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_path_label.clip_text = true
	_path_label.modulate = Color(1, 1, 1, 0.45)
	_path_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hbox.add_child(_path_label)
