@tool
class_name HenActionLookAt2D extends HenScriptMacroBase


# rotates the owner so its right side faces Target, a point in global space.


func get_id() -> StringName:
	return &'look_at_2d'


func get_description() -> String:
	return 'Rotates the node so its right side faces a point in global space.'


func get_display_name() -> String:
	return 'Look At'


func get_icon() -> String:
	return 'crosshair'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D']


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node to turn. Leave it empty to turn this node.'),
		{
			name = 'Target',
			type = 'Vector2',
			id = &'target',
			doc = 'The point in global space to face.',
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
	return '{{ref}}.look_at({{target}})'
