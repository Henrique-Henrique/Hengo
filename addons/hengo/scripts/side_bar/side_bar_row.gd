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
var type_badge: PanelContainer
var type_label: Label
var badge_label: Label
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

	meta = _meta
	title_label.text = _title
	ThemeUtils.apply_font_size(title_label, 13)
	icon_rect.texture = _icon
	icon_rect.modulate = Color(_icon_color.r, _icon_color.g, _icon_color.b, 1.0)
	add_button.visible = show_add
	add_button.tooltip_text = add_label
	add_button.add_theme_constant_override('icon_max_width', 12)
	add_button.add_theme_color_override('icon_normal_color', Color(1, 1, 1, 0.28))
	add_button.add_theme_color_override('icon_hover_color', Color(1, 1, 1, 0.9))
	add_button.add_theme_color_override('icon_pressed_color', Color(1, 1, 1, 1))
	margin_container.add_theme_constant_override('margin_left', indent)

	var add_style := StyleBoxEmpty.new()
	add_button.add_theme_stylebox_override('normal', add_style)
	add_button.add_theme_stylebox_override('hover', add_style)
	add_button.add_theme_stylebox_override('pressed', add_style)
	add_button.add_theme_stylebox_override('focus', add_style)
	add_button.add_theme_stylebox_override('disabled', add_style)


func set_type_badge(type_name: String, _color_override: Color = Color(0, 0, 0, 0)) -> void:
	_bind_refs()
	if type_name.is_empty():
		type_badge.visible = false
		return

	var color: Color = _color_override if _color_override.a > 0.0 else HenUtils.get_type_parent_color(type_name, 1.0, Color('#72788a'))

	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.22)
	var radius: int = 5
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	type_badge.add_theme_stylebox_override('panel', style)

	type_label.text = type_name
	type_label.add_theme_color_override('font_color', color)
	ThemeUtils.apply_font_size(type_label, 9)
	type_badge.visible = true


func set_start_badge(is_start: bool) -> void:
	if not badge_label:
		badge_label = Label.new()
		badge_label.text = 'start'

		badge_label.add_theme_color_override('font_color', Color('#63ff92'))

		var badge_style := StyleBoxFlat.new()
		badge_style.bg_color = Color('#26482f')
		badge_style.corner_radius_top_left = 4
		badge_style.corner_radius_top_right = 4
		badge_style.corner_radius_bottom_left = 4
		badge_style.corner_radius_bottom_right = 4
		badge_style.content_margin_left = 6
		badge_style.content_margin_right = 6
		badge_style.content_margin_top = 0
		badge_style.content_margin_bottom = 0
		badge_label.add_theme_stylebox_override('normal', badge_style)

		# insert between type_badge and add_button
		get_node('Margin/Body').add_child(badge_label)
		get_node('Margin/Body').move_child(badge_label, 3)

	badge_label.visible = is_start


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

	var accent: Color = Color('#9fb2c7')

	custom_minimum_size = Vector2(0, 36)

	var primary_bg := StyleBoxFlat.new()
	primary_bg.bg_color = Color(accent.r, accent.g, accent.b, 0.12)
	var radius: int = 8
	primary_bg.corner_radius_top_left = radius
	primary_bg.corner_radius_top_right = radius
	primary_bg.corner_radius_bottom_left = radius
	primary_bg.corner_radius_bottom_right = radius
	add_theme_stylebox_override('panel', primary_bg)

	margin_container.add_theme_constant_override('margin_left', 10)
	margin_container.add_theme_constant_override('margin_right', 10)

	title_label.add_theme_font_override('font', FONT_BOLD)
	ThemeUtils.apply_font_size(title_label, 13)
	icon_rect.modulate = Color('#ffffff')
	icon_rect.custom_minimum_size = Vector2(18, 18)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
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
	type_badge = get_node('Margin/Body/TypeBadge')
	type_label = get_node('Margin/Body/TypeBadge/TypeLabel')
