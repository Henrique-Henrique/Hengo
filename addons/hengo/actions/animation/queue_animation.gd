@tool
class_name HenActionQueueAnimation extends HenScriptMacroBase


# lines up an animation to play after the current one finishes, on a bound
# AnimationPlayer. Play Animation cuts in right away instead.


func get_id() -> StringName:
	return &'queue_animation'


func get_description() -> String:
	return 'Lines up an animation to play after the current one finishes on an AnimationPlayer. Play Animation cuts in right away instead.'


func get_display_name() -> String:
	return 'Queue Animation'


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
			doc = 'The AnimationPlayer to queue on.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Animation',
			type = 'StringName',
			id = &'animation',
			doc = 'Name of the animation to play next.',
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
	return '{{player}}.queue({{animation}})'
