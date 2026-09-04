@tool
class_name HenActionSetPosition extends HenScriptMacroBase


# moves the owner to Position, in parent space.


func get_id() -> StringName:
	return &'set_position'


func get_description() -> String:
	return 'Places the node at a position, measured in its parent space.'


func get_display_name() -> String:
	return 'Set Position'


func get_icon() -> String:
	return 'locate-fixed'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D']


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node to place. Leave it empty to place this node.'),
		{
			name = 'Position',
			type = 'Vector2',
			id = &'position',
			doc = 'The new position, in parent space.',
			default_value = Vector2.ZERO
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
	return '{{ref}}.position = {{position}}'
