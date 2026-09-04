@tool
class_name HenActionPlayAnimation extends HenScriptMacroBase


# plays an animation of an AnimationPlayer. bind Player to the node, by variable
# or by node path.


func get_id() -> StringName:
	return &'play_animation'


func get_description() -> String:
	return 'Plays a named animation on an AnimationPlayer.'


func get_display_name() -> String:
	return 'Play Animation'


func get_icon() -> String:
	return 'film'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Player',
			type = 'Node',
			id = &'player',
				doc = 'The AnimationPlayer to play.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Animation',
			type = 'StringName',
			id = &'animation',
				doc = 'Name of the animation to play, such as idle or run.',
			default_value = 'idle'
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
	return '{{player}}.play({{animation}})'
