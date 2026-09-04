@tool
class_name HenSideBarCategory extends VBoxContainer
const FONT_BOLD = preload('res://addons/hengo/assets/fonts/bold.ttf')

signal add_pressed(add_type: int)

static var _title_font: FontVariation

var add_type: int = -1

var icon_rect: TextureRect
var title_label: Label
var add_button: Button
var items_container: VBoxContainer
var divider: HSeparator


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
	title_label.text = title.to_upper()
	title_label.modulate = Color(1, 1, 1, 0.92)
	title_label.add_theme_font_override('font', _get_title_font())
	ThemeUtils.apply_font_size(title_label, 11)

	# show icon tinted with solid category color
	var solid_color: Color = Color(icon_color.r, icon_color.g, icon_color.b, 1.0)
	icon_rect.texture = icon
	icon_rect.modulate = solid_color
	icon_rect.visible = icon != null

	add_button.tooltip_text = add_label
	add_button.add_theme_constant_override('icon_max_width', 13)
	add_button.add_theme_color_override('icon_normal_color', Color(1, 1, 1, 0.3))
	add_button.add_theme_color_override('icon_hover_color', Color(1, 1, 1, 0.9))
	add_button.add_theme_color_override('icon_pressed_color', Color(1, 1, 1, 1))
	divider.visible = show_divider

	var add_style := StyleBoxEmpty.new()
	add_button.add_theme_stylebox_override('normal', add_style)
	add_button.add_theme_stylebox_override('hover', add_style)
	add_button.add_theme_stylebox_override('pressed', add_style)
	add_button.add_theme_stylebox_override('focus', add_style)
	add_button.add_theme_stylebox_override('disabled', add_style)


func add_row(row: Control) -> void:
	items_container.add_child(row)


static func _get_title_font() -> FontVariation:
	if not _title_font:
		_title_font = FontVariation.new()
		_title_font.base_font = FONT_BOLD
		_title_font.spacing_glyph = 1

	return _title_font


func _bind_refs() -> void:
	if icon_rect:
		return

	icon_rect = get_node('%Icon')
	title_label = get_node('%Title')
	add_button = get_node('%AddButton')
	items_container = get_node('%Items')
	divider = get_node('%Divider')
