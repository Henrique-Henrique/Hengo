@tool
class_name HenActionMoveForward extends HenScriptMacroBase


# drives the body along its own facing at Speed pixels per second. a negative
# speed reverses. it only moves the body once Move And Slide runs.


func get_id() -> StringName:
	return &'move_forward'


func get_display_name() -> String:
	return 'Move Forward'


func get_icon() -> String:
	return 'move-right'


func get_target_classes() -> Array[StringName]:
	return [&'CharacterBody2D']


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Speed',
			type = 'float',
			id = &'speed',
			default_value = 200.0
		}
	]


func get_default_phase() -> StringName:
	return &'physics'


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
	return '_ref.velocity = Vector2.RIGHT.rotated(_ref.rotation) * {{speed}}'
