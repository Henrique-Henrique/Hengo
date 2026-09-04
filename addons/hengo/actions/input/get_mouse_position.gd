@tool
class_name HenActionGetMousePosition extends HenScriptMacroBase


# writes the mouse position in world space into Store, the point to aim at or to
# drag a node toward.


func get_id() -> StringName:
	return &'get_mouse_position'


func get_description() -> String:
	return 'Reads the mouse position in world space and stores it. Useful to aim at the cursor or drag a node toward it.'


func get_display_name() -> String:
	return 'Get Mouse Position'


func get_icon() -> String:
	return 'mouse-pointer'


func get_target_classes() -> Array[StringName]:
	return [&'CanvasItem']


func get_default_phase() -> StringName:
	return &'update'


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Position', type = 'Vector2', id = &'result', doc = 'Where to store the mouse position, in world space.'}
	]


func get_output_result() -> String:
	return '_ref.get_global_mouse_position()'


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
