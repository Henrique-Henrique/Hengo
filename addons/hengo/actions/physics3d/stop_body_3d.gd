@tool
class_name HenActionStopBody3D extends HenScriptMacroBase


# zeroes both the linear and the angular velocity of a rigid body in one step,
# the pair a reset or respawn always needs to bring the body fully to rest.


func get_id() -> StringName:
	return &'stop_body_3d'


func get_description() -> String:
	return 'Brings a physics body fully to rest by zeroing its linear and angular velocity at once. This is what a reset or respawn needs so the body neither drifts nor spins.'


func get_display_name() -> String:
	return 'Freeze Body'


func get_icon() -> String:
	return 'gauge'


func get_target_classes() -> Array[StringName]:
	return [&'RigidBody3D']


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The body to stop. Leave it empty to stop this node.'),
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
	return '{{ref}}.linear_velocity = Vector3.ZERO\n_ref.angular_velocity = Vector3.ZERO'
