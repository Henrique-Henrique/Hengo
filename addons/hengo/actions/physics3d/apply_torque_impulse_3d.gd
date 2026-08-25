@tool
class_name HenActionApplyTorqueImpulse3D extends HenScriptMacroBase


# a one-shot spin around each axis. best on enter, so it fires once, not every
# frame.


func get_id() -> StringName:
	return &'apply_torque_impulse_3d'


func get_description() -> String:
	return 'Gives a physics body a one-shot spin around each axis, such as a flip. Best placed on enter so it fires once instead of every frame.'


func get_display_name() -> String:
	return 'Apply Torque Impulse'


func get_icon() -> String:
	return 'rotate-cw'


func get_target_classes() -> Array[StringName]:
	return [&'RigidBody3D']


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The body to spin. Leave it empty to spin this node.'),
		{
			name = 'Torque',
			type = 'Vector3',
			id = &'torque',
			doc = 'The spin to apply around each axis.',
			default_value = Vector3.ZERO
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return '{{ref}}.apply_torque_impulse({{torque}})'
