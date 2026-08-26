@tool
class_name HenActionCameraCurrent extends HenScriptMacroBase


func get_id() -> StringName:
	return &'camera_current'


func get_description() -> String:
	return 'Makes a camera the one the player looks through, replacing whichever was active. Works with a 2D and a 3D camera.'


func get_display_name() -> String:
	return 'Use This Camera'


func get_icon() -> String:
	return 'video'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Camera',
			type = 'Node',
			id = &'camera',
			doc = 'The camera to switch to, a 2D or a 3D one.',
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
	return '{{camera}}.make_current()'
