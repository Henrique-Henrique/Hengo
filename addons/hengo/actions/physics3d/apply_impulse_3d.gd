@tool
class_name HenActionApplyImpulse3D extends HenScriptMacroBase


# a one-shot push to a rigid body. best on enter, so it fires once, not every
# frame. leave Offset at zero to push through the center.


func get_id() -> StringName:
	return &'apply_impulse_3d'


func get_description() -> String:
	return 'Gives a physics body a one-shot push, such as a jump or a boost. Best placed on enter so it fires once instead of every frame.'


func get_display_name() -> String:
	return 'Apply Impulse'


func get_icon() -> String:
	return 'zap'


func get_target_classes() -> Array[StringName]:
	return [&'RigidBody3D']


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The body to kick. Leave it empty to kick this node.'),
		{
			name = 'Impulse',
			type = 'Vector3',
			id = &'impulse',
			doc = 'The push to apply, in units times mass per second.',
			default_value = Vector3.ZERO
		},
		{
			name = 'Offset',
			type = 'Vector3',
			id = &'offset',
			doc = 'Where the push is applied, relative to the center. Zero pushes through the center.',
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
	return '{{ref}}.apply_impulse({{impulse}}, {{offset}})'
