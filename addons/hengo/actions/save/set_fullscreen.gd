@tool
class_name HenActionSetFullscreen extends HenScriptMacroBase


func get_id() -> StringName:
	return &'set_fullscreen'


func get_description() -> String:
	return 'Puts the game window in fullscreen or back in a window. Pair it with Save Value to remember the choice on the next run.'


func get_display_name() -> String:
	return 'Set Fullscreen'


func get_icon() -> String:
	return 'maximize'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'On',
			type = 'bool',
			id = &'on',
			doc = 'True for fullscreen, false for a normal window.',
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
	return 'DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if {{on}} else DisplayServer.WINDOW_MODE_WINDOWED)'
