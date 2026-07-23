@tool
class_name HenActionValue extends HBoxContainer

# where a value comes from drives its icon and color, so the list stays scannable
const KINDS = {
	literal = {
		color = '#a4b0c2',
		icon = preload('res://addons/hengo/assets/new_icons/shapes.svg')
	},
	variable = {
		color = '#7cc0ff',
		icon = preload('res://addons/hengo/assets/new_icons/variable.svg')
	},
	property = {
		color = '#6fd3a0',
		icon = preload('res://addons/hengo/assets/new_icons/sliders-horizontal.svg')
	},
	native = {
		color = '#ffd166',
		icon = preload('res://addons/hengo/assets/new_icons/mouse-pointer-2.svg')
	},
	node = {
		color = '#9bb1c9',
		icon = preload('res://addons/hengo/assets/new_icons/list-tree.svg')
	},
	expression = {
		color = '#c08cff',
		icon = preload('res://addons/hengo/assets/new_icons/parentheses.svg')
	},
	branch = {
		color = '#8f86ff',
		icon = preload('res://addons/hengo/assets/new_icons/arrow-right-left.svg')
	}
}

const NAME_COLOR: Color = Color('#6e7889')


func setup(kind: StringName, label: String, value: String) -> void:
	var kind_data: Dictionary = KINDS.get(str(kind), KINDS.literal)
	var color: Color = Color(kind_data.color)

	var icon_rect: TextureRect = get_node('Icon')
	icon_rect.texture = kind_data.icon
	icon_rect.modulate = color

	var name_label: Label = get_node('Name')
	name_label.text = label
	name_label.visible = not label.is_empty()
	ThemeUtils.apply_font_size(name_label, 13)
	name_label.add_theme_color_override('font_color', NAME_COLOR)

	var value_label: Label = get_node('Value')
	value_label.text = value
	ThemeUtils.apply_font_size(value_label, 14)
	value_label.add_theme_color_override('font_color', color)
