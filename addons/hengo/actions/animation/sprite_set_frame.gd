@tool
class_name HenActionSpriteSetFrame extends HenScriptMacroBase


# jumps an AnimatedSprite2D to a specific frame of its current animation.


func get_id() -> StringName:
	return &'sprite_set_frame'


func get_description() -> String:
	return 'Jumps an AnimatedSprite2D to a specific frame of its current animation.'


func get_display_name() -> String:
	return 'Sprite Set Frame'


func get_icon() -> String:
	return 'image'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Sprite',
			type = 'Node',
			id = &'sprite',
				doc = 'The AnimatedSprite2D to change.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Frame',
			type = 'int',
			id = &'frame',
				doc = 'Index of the frame to show, starting at 0.',
			default_value = 0
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
	return '{{sprite}}.frame = {{frame}}'
