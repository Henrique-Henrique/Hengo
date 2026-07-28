@tool
class_name HenActionVector3Info extends HenScriptMacroBase


# writes a scalar read of Vector into Store — length/length_squared.


func get_id() -> StringName:
	return &'vector3_info'


func get_description() -> String:
	return 'Reads a single number from a 3D vector, such as its length.'


func get_display_name() -> String:
	return 'Vector3 Info'


func get_icon() -> String:
	return 'ruler'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Function',
			type = 'String',
			id = &'func_name',
			doc = 'Which value to read from the vector.',
			raw = true,
			options = ['length', 'length_squared'],
			default_value = 'length'
		},
		{
			name = 'Vector',
			type = 'Vector3',
			id = &'vector',
			doc = 'The vector to read.',
			default_value = Vector3.ZERO
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'float', id = &'result', doc = 'The resulting number.'}
	]


func get_output_result() -> String:
	return '{{vector}}.{{func_name}}()'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_exit() -> String:
	return _body()


func _body() -> String:
	return '{{out:result}}'
