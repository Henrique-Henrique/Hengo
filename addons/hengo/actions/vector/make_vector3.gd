@tool
class_name HenActionMakeVector3 extends HenScriptMacroBase


# writes Vector3(X, Y, Z) into Store.


func get_id() -> StringName:
	return &'make_vector3'


func get_description() -> String:
	return 'Builds a Vector3 from separate X, Y and Z numbers.'


func get_display_name() -> String:
	return 'Make Vector3'


func get_icon() -> String:
	return 'move-3d'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'X',
			type = 'float',
			id = &'x',
			doc = 'The value along the x axis.',
			default_value = 0.0
		},
		{
			name = 'Y',
			type = 'float',
			id = &'y',
			doc = 'The value along the y axis.',
			default_value = 0.0
		},
		{
			name = 'Z',
			type = 'float',
			id = &'z',
			doc = 'The value along the z axis.',
			default_value = 0.0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Vector3', id = &'result', doc = 'The built vector.'}
	]


func get_output_result() -> String:
	return 'Vector3({{x}}, {{y}}, {{z}})'


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
