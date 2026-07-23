@tool
class_name HenActionSetAnimationSpeed extends HenScriptMacroBase


# changes how fast an AnimationPlayer runs. 1 is normal, 2 is double speed and
# a negative value plays it backwards.


func get_id() -> StringName:
	return &'set_animation_speed'


func get_display_name() -> String:
	return 'Set Animation Speed'


func get_icon() -> String:
	return 'gauge'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Player',
			type = 'Node',
			id = &'player',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Speed',
			type = 'float',
			id = &'speed',
			default_value = 1.0
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
	return '{{player}}.speed_scale = {{speed}}'
