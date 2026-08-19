@tool
class_name HenActionAnyInput extends HenScriptMacroBase


func get_id() -> StringName:
	return &'any_input'


func get_description() -> String:
	return 'Branches on whether any key, mouse button or gamepad button is down right now. It is the press any key to start check.'


func get_display_name() -> String:
	return 'Any Key Pressed'


func get_icon() -> String:
	return 'keyboard'


func get_default_phase() -> StringName:
	return &'update'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true', doc = 'Where to go while something is pressed.'},
		{name = 'False', id = &'false', doc = 'Where to go while nothing is pressed.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# moving the mouse alone does not count as pressed
func _body() -> String:
	return 'if Input.is_anything_pressed():\n\t{{true}}\nelse:\n\t{{false}}'
