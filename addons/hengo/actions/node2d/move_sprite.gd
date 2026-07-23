@tool
class_name HenActionMoveSprite extends HenScriptMacroBase


# moves the owner along a velocity. on update the velocity is per second, on
# enter/exit it is a one-shot offset in pixels.


func get_id() -> StringName:
	return &'move_sprite'


func get_display_name() -> String:
	return 'Move'


func get_icon() -> String:
	return 'move'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D']


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Velocity',
			type = 'Vector2',
			id = &'velocity',
			default_value = Vector2(120, 0)
		},
		{
			name = 'Speed',
			type = 'float',
			id = &'speed',
			default_value = 1.0
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return '_ref.position += {{velocity}} * {{speed}}'


func get_flow_update() -> String:
	return '_ref.position += {{velocity}} * {{speed}} * delta'


func get_flow_exit() -> String:
	return '_ref.position += {{velocity}} * {{speed}}'
