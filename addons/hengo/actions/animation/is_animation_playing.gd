@tool
class_name HenActionIsAnimationPlaying extends HenScriptMacroBase


# branches on whether an AnimationPlayer is still running, the usual way to hold
# a state until the animation ends.


func get_id() -> StringName:
	return &'is_animation_playing'


func get_description() -> String:
	return 'Checks whether an AnimationPlayer is still running and branches on the result. Useful for holding a state until an animation finishes.'


func get_display_name() -> String:
	return 'Is Animation Playing'


func get_icon() -> String:
	return 'film'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Player',
			type = 'Node',
			id = &'player',
				doc = 'The AnimationPlayer to check.',
			bind_only = true,
			default_value = null
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true', doc = 'Where to go while the animation is still playing.'},
		{name = 'False', id = &'false', doc = 'Where to go once the animation has stopped.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'if {{player}}.is_playing():\n\t{{true}}\nelse:\n\t{{false}}'
