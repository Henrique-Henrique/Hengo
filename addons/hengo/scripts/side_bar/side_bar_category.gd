@tool
class_name HenSideBarCategory extends VBoxContainer
const FONT_BOLD = preload('res://addons/hengo/assets/fonts/bold.ttf')

signal add_pressed(add_type: int)

var add_type: int = -1

var header_panel: PanelContainer
var icon_rect: TextureRect
var title_label: Label
var add_button: Button
var items_container: VBoxContainer
var divider: ColorRect


func _ready() -> void:
	_bind_refs()
	add_button.pressed.connect(func() -> void:
		if add_type >= 0:
			add_pressed.emit(add_type)
	)


func setup(title: String, type: int, icon: Texture2D, icon_color: Color, show_divider: bool = true, add_label: String = 'New', show_add: bool = true) -> void:
	_bind_refs()

	add_type = type
	add_button.visible = show_add
	title_label.text = title
	title_label.modulate = Color('#e3ebf2')
	title_label.add_theme_font_override('font', FONT_BOLD)
	ThemeUtils.apply_font_size(title_label, 13)

	# show icon tinted with solid category color
	var solid_color: Color = Color(icon_color.r, icon_color.g, icon_color.b, 1.0)
	icon_rect.texture = icon
	icon_rect.modulate = solid_color
	icon_rect.visible = icon != null

	# tinted header background with rounded corners matching design system
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = Color(icon_color.r, icon_color.g, icon_color.b, 0.14)
	header_style.border_color = Color(icon_color.r, icon_color.g, icon_color.b, 0.35)
	header_style.set_border_width_all(1)
	var radius: int = 10
	header_style.corner_radius_top_left = radius
	header_style.corner_radius_top_right = radius
	header_style.corner_radius_bottom_left = radius
	header_style.corner_radius_bottom_right = radius
	header_panel.add_theme_stylebox_override('panel', header_style)

	add_button.text = add_label
	ThemeUtils.apply_font_size(add_button, 10)
	add_button.add_theme_constant_override('icon_max_width', 14)
	add_button.add_theme_constant_override('h_separation', 4)
	divider.visible = show_divider
	divider.color = Color('#2c3138', 0.4)

	var add_style := StyleBoxEmpty.new()
	add_button.add_theme_stylebox_override('normal', add_style)
	add_button.add_theme_stylebox_override('hover', add_style)
	add_button.add_theme_stylebox_override('pressed', add_style)
	add_button.add_theme_stylebox_override('focus', add_style)
	add_button.add_theme_stylebox_override('disabled', add_style)


func add_row(row: Control) -> void:
	items_container.add_child(row)


func _bind_refs() -> void:
	if icon_rect:
		return

	header_panel = get_node('%HeaderPanel')
	icon_rect = get_node('%Icon')
	title_label = get_node('%Title')
	add_button = get_node('%AddButton')
	items_container = get_node('%Items')
	divider = get_node('%Divider')
