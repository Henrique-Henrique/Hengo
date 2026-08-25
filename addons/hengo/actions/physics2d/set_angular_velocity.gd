@tool
class_name HenActionSetAngularVelocity extends HenScriptMacroBase


# sets the rigid body spin directly, in degrees per second.


func get_id() -> StringName:
	return &'set_angular_velocity'


func get_description() -> String:
	return 'Sets the angular velocity (spin) of a physics body directly, in degrees per second. Zero stops the spin.'


func get_display_name() -> String:
	return 'Set Angular Velocity'


func get_icon() -> String:
	return 'rotate-cw'


func get_target_classes() -> Array[StringName]:
	return [&'RigidBody2D']


func get_default_phase() -> StringName:
	return &'physics'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The body to spin. Leave it empty to spin this node.'),
		{
			name = 'Speed',
			type = 'float',
			id = &'speed',
			doc = 'The spin to set, in degrees per second. Zero stops the spin.',
			default_value = 0.0
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


# angular_velocity is in radians, and every angle in the catalog is degrees
func _body() -> String:
	return '{{ref}}.angular_velocity = deg_to_rad({{speed}})'
