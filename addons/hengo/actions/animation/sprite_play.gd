@tool
class_name HenActionSpritePlay extends HenScriptMacroBase


# plays an animation of an AnimatedSprite2D, the sprite sheet kind. bind Sprite
# to the node, by variable or by node path.


func get_id() -> StringName:
	return &'sprite_play'


func get_description() -> String:
	return 'Plays an animation on an AnimatedSprite2D, the sprite sheet kind of sprite.'


func get_display_name() -> String:
	return 'Sprite Play'


func get_icon() -> String:
	return 'images'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Sprite',
			type = 'Node',
			id = &'sprite',
				doc = 'The AnimatedSprite2D to play.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Animation',
			type = 'StringName',
			id = &'animation',
				doc = 'Name of the animation to play, such as walk or jump.',
			default_value = 'default'
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
	return '{{sprite}}.play({{animation}})'
