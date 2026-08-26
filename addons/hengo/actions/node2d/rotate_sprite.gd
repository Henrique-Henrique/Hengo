@tool
class_name HenActionRotateSprite extends HenScriptMacroBase


# spins the owner. on update the speed is degrees per second, on enter/exit it is
# a one-shot offset in degrees.


# stable id so hengo doesn't lose the action when reloading the project
func get_id() -> StringName:
	return &'rotate_sprite'


func get_description() -> String:
	return 'Rotates the node. During update the speed is degrees per second; on enter or exit it turns once by that amount.'


func get_display_name() -> String:
	return 'Rotate'


func get_icon() -> String:
	return 'rotate-cw'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D']


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node to spin. Leave it empty to spin this node.'),
		{
			name = 'Speed',
			type = 'float',
			id = &'speed',
			doc = 'How fast to rotate, in degrees per second.',
			default_value = 90.0
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
	return '{{ref}}.rotation_degrees += {{speed}}'


func get_flow_update() -> String:
	return '{{ref}}.rotation_degrees += {{speed}} * delta'


func get_flow_physics() -> String:
	return '{{ref}}.rotation_degrees += {{speed}} * delta'


func get_flow_exit() -> String:
	return '{{ref}}.rotation_degrees += {{speed}}'
