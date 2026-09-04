@tool
class_name HenActionStopTimer extends HenScriptMacroBase


func get_id() -> StringName:
	return &'stop_timer'


func get_description() -> String:
	return 'Stops a Timer node before it ends, so it never fires. Starting it again runs the countdown from the beginning.'


func get_display_name() -> String:
	return 'Stop Timer'


func get_icon() -> String:
	return 'circle-pause'


func get_default_phase() -> StringName:
	return &'exit'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Timer',
			type = 'Node',
			id = &'timer',
			doc = 'The Timer node to stop.',
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
	return '{{timer}}.stop()'
