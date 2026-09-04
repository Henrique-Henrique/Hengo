@tool
class_name HenActionVector3Combine extends HenScriptMacroBase


# writes a scalar built from A and B into Store — distance/dot/angle.


func get_id() -> StringName:
	return &'vector3_combine'


func get_description() -> String:
	return 'Turns two 3D vectors into one number, such as how far apart two points are or the angle between them.'


func get_display_name() -> String:
	return 'Vector3 Combine'


func get_icon() -> String:
	return 'git-merge'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Function',
			type = 'String',
			id = &'func_name',
			doc = 'distance_to is how far apart they are, dot tells how much they point the same way, and angle_to gives the angle between them.',
			raw = true,
			options = ['distance_to', 'distance_squared_to', 'dot', 'angle_to'],
			default_value = 'distance_to'
		},
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
		{name = 'Result', type = 'float', id = &'result', doc = 'The resulting number. The angle function answers in degrees.'}
	]


# angle_to answers in radians, and the rest of the catalog takes and gives degrees
func get_output_result() -> String:
	if str(value_of(&'func_name', '')) == 'angle_to':
		return 'rad_to_deg({{a}}.{{func_name}}({{b}}))'

	return '{{a}}.{{func_name}}({{b}})'


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
