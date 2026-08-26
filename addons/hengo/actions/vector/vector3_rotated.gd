@tool
class_name HenActionVector3Rotated extends HenScriptMacroBase


# writes Vector turned around Axis by Angle (degrees) into Store.


func get_id() -> StringName:
	return &'vector3_rotated'


func get_description() -> String:
	return 'Rotates a 3D vector around an axis by an angle and returns the turned vector.'


func get_display_name() -> String:
	return 'Vector3 Rotated'


func get_icon() -> String:
	return 'rotate-3d'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Vector',
			type = 'Vector3',
			id = &'vector',
			doc = 'The vector to rotate.',
			default_value = Vector3.FORWARD
		},
		{
			name = 'Axis',
			type = 'Vector3',
			id = &'axis',
			doc = 'The axis to turn around. It is normalized before use.',
			default_value = Vector3.UP
		},
		{
			name = 'Angle',
			type = 'float',
			id = &'angle',
			doc = 'How far to turn it, in degrees.',
			default_value = 0.0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Vector3', id = &'result', doc = 'The rotated vector.'}
	]


func get_output_result() -> String:
	return '{{vector}}.rotated({{axis}}.normalized(), deg_to_rad({{angle}}))'


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
	return '{{out:result}}'
