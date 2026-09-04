@tool
class_name HenActionGetElapsed extends HenScriptMacroBase


# writes the seconds since the game started into Store. subtract a saved start
# time to measure how long something took.


func get_id() -> StringName:
	return &'get_elapsed'


func get_description() -> String:
	return 'Reads the number of seconds since the game started and stores it. Subtract a saved start time to measure how long something took.'


func get_display_name() -> String:
	return 'Get Elapsed Time'


func get_icon() -> String:
	return 'clock'


func get_default_phase() -> StringName:
	return &'update'


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Seconds', type = 'float', id = &'result', doc = 'Where to store the seconds since the game started.'}
	]


func get_output_result() -> String:
	return '(Time.get_ticks_msec() / 1000.0)'


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
	return '{{out:result}}'
