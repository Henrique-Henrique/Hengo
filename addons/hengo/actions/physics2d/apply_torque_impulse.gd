@tool
class_name HenActionApplyTorqueImpulse extends HenScriptMacroBase


# a one-shot spin. best on enter, so it fires once, not every frame. in 2d the
# torque is a single number: positive spins one way, negative the other.


func get_id() -> StringName:
	return &'apply_torque_impulse'


func get_description() -> String:
	return 'Gives a physics body a one-shot spin, such as a flip. Best placed on enter so it fires once instead of every frame.'


func get_display_name() -> String:
	return 'Apply Torque Impulse'


func get_icon() -> String:
	return 'rotate-cw'


func get_target_classes() -> Array[StringName]:
	return [&'RigidBody2D']


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The body to spin. Leave it empty to spin this node.'),
		{
			name = 'Torque',
			type = 'float',
			id = &'torque',
			doc = 'The spin to apply. Positive turns one way, negative the other.',
			default_value = 0.0
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
