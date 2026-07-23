@tool
class_name HenActionMath extends HenScriptMacroBase


# writes `A <op> B` into Store. division follows gdscript semantics, so two ints
# give an int; `%` is left out because it breaks on floats — use the expression
# toggle with fmod() for that.


func get_id() -> StringName:
	return &'math_operator'


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
			type_from = &'result',
			default_value = 0
		},
		{
			name = 'Operator',
			type = 'String',
			id = &'op',
			raw = true,
			options = ['+', '-', '*', '/'],
			default_value = '+'
		},
		{
			name = 'B',
			type = 'Variant',
			id = &'b',
			type_from = &'result',
			default_value = 0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Variant', id = &'result'}
	]


func get_output_result() -> String:
	return '{{a}} {{op}} {{b}}'


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
