@tool
class_name HenActionGetAngleTo extends HenScriptMacroBase


# writes the angle (degrees) from the owner toward Target into Store.


func get_id() -> StringName:
	return &'get_angle_to'


func get_description() -> String:
	return 'Measures the angle from the node to a target and stores it, in degrees.'


func get_display_name() -> String:
	return 'Get Angle To'


func get_icon() -> String:
	return 'compass'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D']


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node the angle is measured from. Leave it empty to measure from this node.'),
		{
			name = 'Target',
			type = 'Node2D',
			id = &'target',
			doc = 'The node to measure the angle to, such as another Node2D.',
			bind_only = true,
			default_value = null
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Angle', type = 'float', id = &'angle', doc = 'Where to store the resulting angle, in degrees.'}
	]


func get_output_angle() -> String:
	return 'rad_to_deg({{ref}}.get_angle_to({{target}}.global_position))'


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
	return '{{out:angle}}'
