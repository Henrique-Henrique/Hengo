@tool
class_name HenActionSetGravityScale extends HenScriptMacroBase


func get_id() -> StringName:
	return &'set_gravity_scale'


func get_description() -> String:
	return 'Sets how strongly gravity pulls this body. 1 is normal gravity, 0 makes it float and a negative value makes it fall upwards.'


func get_display_name() -> String:
	return 'Set Gravity Scale'


func get_icon() -> String:
	return 'arrow-down-to-line'


func get_target_classes() -> Array[StringName]:
	return [&'RigidBody2D', &'RigidBody3D']


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The body to change. Leave it empty to change this node.'),
		{
			name = 'Scale',
			type = 'float',
			id = &'scale',
			doc = 'How much gravity to apply, as a multiplier of the world gravity.',
			default_value = 1.0
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
	return '{{ref}}.gravity_scale = {{scale}}'
