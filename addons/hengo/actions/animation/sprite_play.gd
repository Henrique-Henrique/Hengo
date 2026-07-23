@tool
class_name HenActionSpritePlay extends HenScriptMacroBase


# plays an animation of an AnimatedSprite2D, the sprite sheet kind. bind Sprite
# to the node, by variable or by node path.


func get_id() -> StringName:
	return &'sprite_play'


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
			bind_only = true,
			default_value = null
		},
		{
			name = 'Animation',
			type = 'StringName',
			id = &'animation',
			default_value = 'default'
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_exit() -> String:
	return _body()


func _body() -> String:
	return '{{sprite}}.play({{animation}})'
