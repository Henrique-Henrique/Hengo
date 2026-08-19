@tool
class_name HenActionGetScreenSize extends HenScriptMacroBase


func get_id() -> StringName:
	return &'get_screen_size'


func get_description() -> String:
	return 'Reads how big the visible screen is, in pixels. It is what a centering, an edge check or a random spawn spot needs to know the play area.'


func get_display_name() -> String:
	return 'Get Screen Size'


func get_icon() -> String:
	return 'monitor'


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Vector2', id = &'result', doc = 'Where to store the screen size, in pixels.'}
	]


# get_visible_rect() follows the stretched game viewport, not the os window size
func get_output_result() -> String:
	return '_ref.get_viewport().get_visible_rect().size'


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
