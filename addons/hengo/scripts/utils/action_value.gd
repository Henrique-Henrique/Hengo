@tool
class_name HenActionValue extends HBoxContainer

# where a value comes from drives its color, so the line stays scannable
const KINDS: Dictionary = {
	literal = '#dbe3ef',
	variable = '#7cc0ff',
	property = '#6fd3a0',
	native = '#ffd166',
	node = '#9bb1c9',
	expression = '#c08cff',
	action = '#ff9e64',
	branch = '#8f86ff'
}

const NAME_COLOR: Color = Color('#6e7889')
const LABEL_SIZE: int = 14
const VALUE_SIZE: int = 17

signal pressed(part: Dictionary, chip: HenActionValue)

# the {kind, label, value, slot, editable} entry this chip renders
var part: Dictionary = {}

var _color: Color = Color(KINDS.literal)
var _hovered: bool = false
var _editing: bool = false


func _ready() -> void:
	var box: PanelContainer = value_anchor()
	box.gui_input.connect(_on_gui_input)
	box.mouse_entered.connect(_set_hovered.bind(true))
	box.mouse_exited.connect(_set_hovered.bind(false))


func setup(_part: Dictionary) -> void:
	part = _part
	_color = Color(str(KINDS.get(str(_part.get('kind', 'literal')), KINDS.literal)))

	var name_label: Label = get_node('Name')
	name_label.text = str(_part.get('label', ''))
	name_label.visible = not name_label.text.is_empty()
	ThemeUtils.apply_font_size(name_label, LABEL_SIZE)
	name_label.add_theme_color_override('font_color', NAME_COLOR)

	var value_label: Label = _value_label()
	value_label.text = str(_part.get('value', ''))
	ThemeUtils.apply_font_size(value_label, VALUE_SIZE)
	value_label.add_theme_color_override('font_color', _color)

	_apply_style()


func set_value_text(_text: String) -> void:
	part.value = _text
	_value_label().text = _text


func is_editable() -> bool:
	return bool(part.get('editable', false))


func value_anchor() -> PanelContainer:
	return get_node('ValueBox')


# holds the highlight while the popup edits this chip, so the target is obvious
func set_editing(_on: bool) -> void:
	_editing = _on
	_apply_style()


func _value_label() -> Label:
	return get_node('ValueBox/Value')


func _set_hovered(_on: bool) -> void:
	_hovered = _on
	_apply_style()


func _apply_style() -> void:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(4)
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	style.bg_color = Color(_color, 0.22 if _editing else (0.13 if _hovered else 0.0))

	value_anchor().add_theme_stylebox_override('panel', style)


func _on_gui_input(_event: InputEvent) -> void:
	if not _event is InputEventMouseButton:
		return

	var mb := _event as InputEventMouseButton

	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return

	value_anchor().accept_event()
	pressed.emit(part, self)
