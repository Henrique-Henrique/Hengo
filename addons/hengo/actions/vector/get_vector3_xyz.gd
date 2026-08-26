@tool
class_name HenActionGetVector3XYZ extends HenScriptMacroBase


# splits Vector into its three components, one output each. store the ones needed.


func get_id() -> StringName:
	return &'get_vector3_xyz'


func get_description() -> String:
	return 'Splits a Vector3 into its separate X, Y and Z numbers.'


func get_display_name() -> String:
	return 'Get Vector3 XYZ'


func get_icon() -> String:
	return 'axis-3d'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Vector',
			type = 'Vector3',
			id = &'vector',
			doc = 'The vector to split.',
			default_value = Vector3.ZERO
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'X', type = 'float', id = &'x', doc = 'The value along the x axis.'},
		{name = 'Y', type = 'float', id = &'y', doc = 'The value along the y axis.'},
		{name = 'Z', type = 'float', id = &'z', doc = 'The value along the z axis.'}
	]


func get_output_x() -> String:
	return '{{vector}}.x'


func get_output_y() -> String:
	return '{{vector}}.y'


func get_output_z() -> String:
	return '{{vector}}.z'


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
	return '{{out:x}}\n{{out:y}}\n{{out:z}}'
