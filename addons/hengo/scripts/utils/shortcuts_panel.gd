@tool
class_name HenShortcutsPanel extends MarginContainer

# renders HenShortcuts.LIST, which is also what the flow handler dispatches from:
# a binding added there shows up here without touching this file

const GROUP_COLOR: Color = Color('#8fa0b8')
const KEY_BG: Color = Color(1, 1, 1, 0.10)
const KEY_TEXT: Color = Color('#e6ebf2')
const DESC_COLOR: Color = Color(1, 1, 1, 0.55)


func _ready() -> void:
	ThemeUtils.apply_font_size(get_node('%Title'), 18)

	var list: VBoxContainer = get_node('%List')

	for group: StringName in HenShortcuts.groups():
		list.add_child(_group_label(HenShortcuts.group_name(group)))

		for entry: Dictionary in HenShortcuts.of_group(group):
			list.add_child(_row(entry))


func _group_label(_text: String) -> Control:
	var margin: MarginContainer = MarginContainer.new()
	var label: Label = Label.new()

	margin.add_theme_constant_override('margin_top', 10)
	label.text = _text.to_upper()
	label.add_theme_color_override('font_color', GROUP_COLOR)
	ThemeUtils.apply_font_size(label, 11)
	margin.add_child(label)

	return margin


func _row(_entry: Dictionary) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	var keys: HBoxContainer = HBoxContainer.new()
	var text: VBoxContainer = VBoxContainer.new()
	var title: Label = Label.new()
	var description: Label = Label.new()

	row.add_theme_constant_override('separation', 12)
	keys.add_theme_constant_override('separation', 4)
	keys.custom_minimum_size = Vector2(170, 0)
	keys.alignment = BoxContainer.ALIGNMENT_END
	keys.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	for name: String in _entry.combo:
		keys.add_child(_key_chip(name))

	text.add_theme_constant_override('separation', 1)
	title.text = str(_entry.title)
	ThemeUtils.apply_font_size(title, 13)

	description.text = str(_entry.description)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override('font_color', DESC_COLOR)
	ThemeUtils.apply_font_size(description, 12)

	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_child(title)
	text.add_child(description)

	row.add_child(keys)
	row.add_child(text)

	return row


func _key_chip(_name: String) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	var margin: MarginContainer = MarginContainer.new()
	var label: Label = Label.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()

	# a PanelContainer fills its cell by default, and the chip has to be the size
	# of the key name
	panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	style.bg_color = KEY_BG
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override('panel', style)

	margin.add_theme_constant_override('margin_left', 6)
	margin.add_theme_constant_override('margin_right', 6)
	margin.add_theme_constant_override('margin_top', 2)
	margin.add_theme_constant_override('margin_bottom', 2)

	label.text = _name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override('font_color', KEY_TEXT)
	ThemeUtils.apply_font_size(label, 12)

	margin.add_child(label)
	panel.add_child(margin)

	return panel
