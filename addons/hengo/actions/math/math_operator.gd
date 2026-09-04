@tool
class_name HenActionMath extends HenScriptMacroBase


# writes `A <op> B` into Store. division follows gdscript semantics, so two ints
# give an int, and `%` errors on a float operand the same way gdscript does.


func get_id() -> StringName:
	return &'math_operator'


func get_description() -> String:
	return 'Combines two numbers with an arithmetic operator, such as add or multiply.'


func get_display_name() -> String:
	return 'Math'


func get_icon() -> String:
	return 'calculator'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'A',
			type = 'Variant',
			id = &'a',
			doc = 'The left-hand number.',
			type_from = &'result',
			default_value = 0
		},
		{
			name = 'Operator',
			type = 'String',
			id = &'op',
			doc = 'The arithmetic operation to apply. The remainder only works on whole numbers.',
			raw = true,
			options = ['+', '-', '*', '/', '%'],
			default_value = '+'
		},
		{
			name = 'B',
			type = 'Variant',
			id = &'b',
			doc = 'The right-hand number.',
			type_from = &'result',
			default_value = 0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Variant', id = &'result', doc = 'The result of the operation.'}
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
