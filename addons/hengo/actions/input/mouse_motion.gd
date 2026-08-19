@tool
class_name HenActionMouseMotion extends HenScriptMacroBase


func get_id() -> StringName:
	return &'mouse_motion'


func get_description() -> String:
	return 'Reads how the mouse is moving and stores it as a direction whose length is the speed in pixels per second. It stays at zero while the mouse is still.'


func get_display_name() -> String:
	return 'Get Mouse Motion'


func get_icon() -> String:
	return 'mouse'


func get_default_phase() -> StringName:
	return &'update'


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Vector2', id = &'result', doc = 'Where to store the mouse movement, in pixels per second.'}
	]


# the engine refreshes this value every 0.1s, so a quick flick reads late
func get_output_result() -> String:
	return 'Input.get_last_mouse_velocity()'


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
