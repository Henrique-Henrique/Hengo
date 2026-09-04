@tool
class_name HenActionSetRotation3D extends HenScriptMacroBase


# points the owner at an angle on each axis. Rotate adds to the current one
# instead, so zeroing a rotation was only reachable through an expression.


func get_id() -> StringName:
	return &'set_rotation_3d'


func get_description() -> String:
	return 'Points the node at an angle on each axis, in degrees, replacing whatever rotation it had. Zero puts it back upright. Rotate adds to the current angle instead.'


func get_display_name() -> String:
	return 'Set Rotation'


func get_icon() -> String:
	return 'rotate-3d'


func get_target_classes() -> Array[StringName]:
	return [&'Node3D']


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node to turn. Leave it empty to turn this node.'),
		{
			name = 'Angle',
			type = 'Vector3',
			id = &'angle',
			doc = 'The angle to point at on each axis, in degrees. Zero is upright.',
			default_value = Vector3.ZERO
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
	return '{{ref}}.rotation_degrees = {{angle}}'
