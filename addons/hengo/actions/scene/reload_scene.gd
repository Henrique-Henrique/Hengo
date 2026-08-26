@tool
class_name HenActionReloadScene extends HenScriptMacroBase


# restarts the current scene from scratch, the usual "game over, try again".


func get_id() -> StringName:
	return &'reload_scene'


func get_description() -> String:
	return 'Restarts the current scene from scratch, the usual choice for a game over and retry.'


func get_display_name() -> String:
	return 'Reload Scene'


func get_icon() -> String:
	return 'refresh-cw'


func get_default_phase() -> StringName:
	return &'enter'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return '_ref.get_tree().reload_current_scene()'
