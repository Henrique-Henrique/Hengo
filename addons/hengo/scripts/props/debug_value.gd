@tool
extends PanelContainer


var text_label: Label
var vec2
var vec3
var texture_node: TextureRect

var need_clean: bool = true

func _ready() -> void:
	text_label = get_node('%TextLabel')
	vec2 = get_node('%Vec2')
	vec3 = get_node('%Vec3')
	texture_node = get_node('%Texture')

	need_clean = true


func show_value(_value: Variant) -> void:
	for node in get_children():
		node.visible = false


	match typeof(_value):
		TYPE_VECTOR2:
			vec2.visible = true
			vec2.set_default_raw(_value)
		TYPE_VECTOR3:
			vec3.visible = true
			vec3.set_default_raw(_value)
		TYPE_OBJECT:
			if _value is Texture2D:
				texture_node.visible = true
				texture_node.texture = _value
			else:
				text_label.visible = true
				text_label.text = 'Work In Progress\nClass: ' + _value.get_class() + '\n' + str(_value)
		_:
			text_label.visible = true
			text_label.text = var_to_str(_value)