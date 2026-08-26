@tool
class_name HenActionSetVsync extends HenScriptMacroBase


func get_id() -> StringName:
	return &'set_vsync'


func get_description() -> String:
	return 'Turns vertical sync on or off. With it on the game matches the screen refresh rate and stops tearing, with it off the frame rate runs free.'


func get_display_name() -> String:
	return 'Set VSync'


func get_icon() -> String:
	return 'refresh-cw'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'On',
			type = 'bool',
			id = &'on',
			doc = 'True to sync with the screen, false to let frames run free.',
			default_value = true
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
	return 'DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if {{on}} else DisplayServer.VSYNC_DISABLED)'
