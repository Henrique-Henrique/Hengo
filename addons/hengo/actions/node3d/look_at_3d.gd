@tool
class_name HenActionLookAt3D extends HenScriptMacroBase


# turns the owner so its -Z axis faces Target, a point in global space. Up keeps
# the model from rolling; it must not be parallel to the looking direction.


func get_id() -> StringName:
	return &'look_at_3d'


func get_description() -> String:
	return 'Rotates the node so its front faces a point in global space.'


func get_display_name() -> String:
	return 'Look At'


func get_icon() -> String:
	return 'crosshair'


func get_target_classes() -> Array[StringName]:
	return [&'Node3D']


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node to turn. Leave it empty to turn this node.'),
		{
			name = 'Target',
			type = 'Vector3',
			id = &'target',
			doc = 'The point in global space to face.',
			default_value = Vector3.ZERO
		},
		{
			name = 'Up',
			type = 'Vector3',
			id = &'up',
			doc = 'Which direction is up, keeping the node from rolling. It must not point along the looking direction.',
			default_value = Vector3(0, 1, 0)
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
	return '{{ref}}.look_at({{target}}, {{up}})'
