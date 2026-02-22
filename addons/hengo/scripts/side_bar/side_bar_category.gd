@tool
class_name HenSideBarCategory extends VBoxContainer
const FONT_BOLD = preload('res://addons/hengo/assets/fonts/bold.ttf')

signal add_pressed(add_type: int)

var add_type: int = -1

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


func setup(title: String, type: int, icon: Texture2D, icon_color: Color, show_divider: bool = true, add_label: String = 'New') -> void:
	_bind_refs()
	var editor_scale: float = EditorInterface.get_editor_scale() if Engine.is_editor_hint() else 1.0

	add_type = type
	title_label.text = title
	icon_rect.visible = false
	title_label.modulate = Color('#e3ebf2')
	title_label.add_theme_font_override('font', FONT_BOLD)
	add_button.text = add_label
	add_button.add_theme_font_size_override('font_size', int(max(10, roundi(10 * editor_scale))))
	add_button.add_theme_constant_override('icon_max_width', int(max(14, roundi(14 * editor_scale))))
	add_button.add_theme_constant_override('h_separation', int(max(4, roundi(4 * editor_scale))))
	divider.visible = show_divider
	divider.color = Color('#2c3138')

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

	icon_rect = get_node('HeaderPanel/Header/HeaderRow/Icon')
	title_label = get_node('HeaderPanel/Header/HeaderRow/Title')
	add_button = get_node('HeaderPanel/Header/HeaderRow/AddButton')
	items_container = get_node('Items')
	divider = get_node('Divider')
