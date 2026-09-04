@tool
class_name HenActionMoveSprite extends HenScriptMacroBase


# moves the owner along a velocity. on update the velocity is per second, on
# enter/exit it is a one-shot offset in pixels.


func get_id() -> StringName:
	return &'move_sprite'


func get_description() -> String:
	return 'Moves the node by a velocity. During update it is applied per second; on enter or exit it is applied once.'


func get_display_name() -> String:
	return 'Move'


func get_icon() -> String:
	return 'move'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D']


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node to move. Leave it empty to move this node.'),
		{
			name = 'Velocity',
			type = 'Vector2',
			id = &'velocity',
			doc = 'The direction and speed to move, in pixels.',
			default_value = Vector2(120, 0)
		},
		{
			name = 'Speed',
			type = 'float',
			id = &'speed',
			doc = 'Multiplier applied to the velocity.',
			default_value = 1.0
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
	return '{{ref}}.position += {{velocity}} * {{speed}}'


func get_flow_update() -> String:
	return '{{ref}}.position += {{velocity}} * {{speed}} * delta'


func get_flow_physics() -> String:
	return '{{ref}}.position += {{velocity}} * {{speed}} * delta'


func get_flow_exit() -> String:
	return '{{ref}}.position += {{velocity}} * {{speed}}'
