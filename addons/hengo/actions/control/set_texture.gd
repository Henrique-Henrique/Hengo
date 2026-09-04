@tool
class_name HenActionSetTexture extends HenScriptMacroBase


# swaps the image of a bound node (TextureRect, TextureButton, Sprite2D...).
# Target is bound by variable or node path; the assignment is duck-typed.


func get_id() -> StringName:
	return &'set_texture'


func get_description() -> String:
	return 'Swaps the image shown by a node such as a TextureRect or a TextureButton. Bind Texture to an image loaded into a variable.'


func get_display_name() -> String:
	return 'Set Image'


func get_icon() -> String:
	return 'image'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Control',
			id = &'target',
			doc = 'The node to change the image of. Leave it empty to change this node.',
			bind_only = true,
			optional = true,
			default_value = null
		},
		{
			name = 'Texture',
			type = 'Texture2D',
			id = &'texture',
			doc = 'The image to show, bound from a variable or resource.',
			bind_only = true,
			default_value = null
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func get_flow_exit() -> String:
	return _body()


func _body() -> String:
	return '{{target}}.texture = {{texture}}'
