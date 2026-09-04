@tool
class_name HenActionTranslate extends HenScriptMacroBase


# shifts the owner by Offset. on update the offset is per second, on enter/exit
# it is applied once.


func get_id() -> StringName:
	return &'translate'


func get_description() -> String:
	return 'Moves the node by an offset. During update it is applied per second; on enter or exit it is applied once.'


func get_display_name() -> String:
	return 'Translate'


func get_icon() -> String:
	return 'move-right'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D']


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node to move. Leave it empty to move this node.'),
		{
			name = 'Offset',
			type = 'Vector2',
			id = &'offset',
			doc = 'The amount to move, in pixels.',
			default_value = Vector2(100, 0)
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
	return '{{ref}}.position += {{offset}}'


func get_flow_update() -> String:
	return '{{ref}}.position += {{offset}} * delta'


func get_flow_physics() -> String:
	return '{{ref}}.position += {{offset}} * delta'


func get_flow_exit() -> String:
	return '{{ref}}.position += {{offset}}'
