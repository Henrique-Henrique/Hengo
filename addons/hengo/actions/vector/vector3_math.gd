@tool
class_name HenActionVector3Math extends HenScriptMacroBase


func get_id() -> StringName:
	return &'vector3_math'


func get_description() -> String:
	return 'Combines two 3D vectors with an arithmetic operator, such as add or multiply. Adding is how a position gets offset.'


func get_display_name() -> String:
	return 'Vector3 Math'


func get_icon() -> String:
	return 'calculator'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'A',
			type = 'Vector3',
			id = &'a',
			doc = 'The left-hand vector.',
			default_value = Vector3.ZERO
		},
		{
			name = 'Operator',
			type = 'String',
			id = &'op',
			doc = 'The arithmetic operation to apply.',
			raw = true,
			options = ['+', '-', '*', '/'],
			default_value = '+'
		},
		{
			name = 'B',
			type = 'Vector3',
			id = &'b',
			doc = 'The right-hand vector.',
			default_value = Vector3.ZERO
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Vector3', id = &'result', doc = 'The resulting vector.'}
	]


func get_output_result() -> String:
	return '{{a}} {{op}} {{b}}'


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
