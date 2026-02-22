@tool
class_name HenSideBarRow extends PanelContainer
const FONT_BOLD = preload('res://addons/hengo/assets/fonts/bold.ttf')

signal row_pressed(meta: Variant, mouse_button_index: int)
signal add_pressed(meta: Variant)

var meta: Variant
var is_selected: bool = false

var icon_rect: TextureRect
var title_label: Label
var add_button: Button
var margin_container: MarginContainer
var _is_primary: bool = false


func _ready() -> void:
	_bind_refs()
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	add_button.pressed.connect(func() -> void:
		add_pressed.emit(meta)
	)


func setup(_title: String, _meta: Variant, _icon: Texture2D = null, _icon_color: Color = Color.WHITE, show_add: bool = false, indent: int = 0, add_label: String = 'New') -> void:
	_bind_refs()
	var editor_scale: float = EditorInterface.get_editor_scale() if Engine.is_editor_hint() else 1.0

	meta = _meta
	title_label.text = _title
	icon_rect.texture = _icon
	icon_rect.modulate = Color(_icon_color.r, _icon_color.g, _icon_color.b, 1.0)
	add_button.visible = show_add
	add_button.text = add_label
	add_button.add_theme_font_size_override('font_size', int(max(10, roundi(10 * editor_scale))))
	add_button.add_theme_constant_override('icon_max_width', int(max(14, roundi(14 * editor_scale))))
	add_button.add_theme_constant_override('h_separation', int(max(4, roundi(4 * editor_scale))))
	margin_container.add_theme_constant_override('margin_left', indent)

	var add_style := StyleBoxEmpty.new()
	add_button.add_theme_stylebox_override('normal', add_style)
	add_button.add_theme_stylebox_override('hover', add_style)
	add_button.add_theme_stylebox_override('pressed', add_style)
	add_button.add_theme_stylebox_override('focus', add_style)
	add_button.add_theme_stylebox_override('disabled', add_style)


func set_selected(selected: bool) -> void:
	is_selected = selected
	if _is_primary:
		title_label.modulate = Color('#ffffff') if selected else Color('#e7eef5')
	else:
		title_label.modulate = Color('#f0f4f8') if selected else Color('#c4cdd6')


func set_background_mode(use_filled_background: bool) -> void:
	if _is_primary:
		return

	if use_filled_background:
		var stripe := StyleBoxFlat.new()
		stripe.bg_color = Color(0, 0, 0, 0.3)
		stripe.corner_radius_top_left = 4
		stripe.corner_radius_top_right = 4
		stripe.corner_radius_bottom_left = 4
		stripe.corner_radius_bottom_right = 4
		add_theme_stylebox_override('panel', stripe)
	else:
		add_theme_stylebox_override('panel', StyleBoxEmpty.new())


func set_primary_emphasis(enable: bool = true) -> void:
	_is_primary = enable
	if not enable:
		return

	var primary_bg := StyleBoxFlat.new()
	primary_bg.bg_color = Color(0, 0, 0, 0.5)
	primary_bg.corner_radius_top_left = 6
	primary_bg.corner_radius_top_right = 6
	primary_bg.corner_radius_bottom_left = 6
	primary_bg.corner_radius_bottom_right = 6
	add_theme_stylebox_override('panel', primary_bg)
	title_label.add_theme_font_override('font', FONT_BOLD)
	icon_rect.modulate = Color('#ffffff')


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		if add_button.visible and add_button.get_global_rect().has_point(mb.global_position):
			return

		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			row_pressed.emit(meta, mb.button_index)
			accept_event()


func _on_mouse_entered() -> void:
	if not (meta is int):
		if _is_primary:
			title_label.modulate = Color('#ffffff')
		else:
			title_label.modulate = Color('#e2e9f0') if not is_selected else Color('#f0f4f8')


func _on_mouse_exited() -> void:
	if not (meta is int):
		set_selected(is_selected)


func _bind_refs() -> void:
	if icon_rect:
		return

	icon_rect = get_node('Margin/Body/Icon')
	title_label = get_node('Margin/Body/Title')
	add_button = get_node('Margin/Body/AddButton')
	margin_container = get_node('Margin')
