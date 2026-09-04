@tool
class_name HenActionSetLinearVelocity3D extends HenScriptMacroBase


# sets the rigid body linear velocity directly. zero stops it, which is how a
# reset or respawn brings the body to rest.


func get_id() -> StringName:
	return &'set_linear_velocity_3d'


func get_description() -> String:
	return 'Sets the linear velocity of a physics body directly, in units per second. Setting it to zero stops the body, which is how a reset brings it to rest.'


func get_display_name() -> String:
	return 'Set Linear Velocity'


func get_icon() -> String:
	return 'gauge'


func get_target_classes() -> Array[StringName]:
	return [&'RigidBody3D']


func get_default_phase() -> StringName:
	return &'physics'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The body to change. Leave it empty to change this node.'),
		{
			name = 'Velocity',
			type = 'Vector3',
			id = &'velocity',
			doc = 'The velocity to set, in units per second. Zero stops the body.',
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
	return '{{ref}}.linear_velocity = {{velocity}}'
