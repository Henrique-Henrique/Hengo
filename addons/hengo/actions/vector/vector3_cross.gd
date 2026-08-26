@tool
class_name HenActionVector3Cross extends HenScriptMacroBase


# writes the cross product of A and B into Store — a vector perpendicular to both.


func get_id() -> StringName:
	return &'vector3_cross'


func get_description() -> String:
	return 'Takes two 3D directions and gives the one standing at a right angle to both. Feeding the facing direction and the up direction gives the side direction, which is how strafing left and right is worked out.'


func get_display_name() -> String:
	return 'Vector3 Cross'


func get_icon() -> String:
	return 'axis-3d'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'A',
			type = 'Vector3',
			id = &'a',
			doc = 'The first vector.',
			default_value = Vector3.ZERO
		},
		{
			name = 'B',
			type = 'Vector3',
			id = &'b',
			doc = 'The second vector.',
			default_value = Vector3.ZERO
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Vector3', id = &'result', doc = 'The direction at a right angle to both, such as the side of a body.'}
	]


func get_output_result() -> String:
	return '{{a}}.cross({{b}})'


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
