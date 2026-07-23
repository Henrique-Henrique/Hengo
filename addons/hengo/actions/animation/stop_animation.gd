@tool
class_name HenActionStopAnimation extends HenScriptMacroBase


# stops an AnimationPlayer where it is.


func get_id() -> StringName:
	return &'stop_animation'


func get_display_name() -> String:
	return 'Stop Animation'


func get_icon() -> String:
	return 'square'


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
	return '{{player}}.stop()'
