@tool
class_name HenActionMathFunction2 extends HenScriptMacroBase


# writes Function(A, B) into Store — one of min/max/pow/snapped/fmod.


func get_id() -> StringName:
	return &'math_function2'


func get_description() -> String:
	return 'Applies a two-number math function to A and B, such as min, max or pow.'


func get_display_name() -> String:
	return 'Math Function 2'


func get_icon() -> String:
	return 'sigma'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Function',
			type = 'String',
			id = &'func_name',
			doc = 'The math function to apply.',
			raw = true,
			options = ['min', 'max', 'pow', 'snapped', 'fmod'],
			default_value = 'min'
		},
		{
			name = 'A',
			type = 'Variant',
			id = &'a',
			doc = 'The first number.',
			type_from = &'result',
			default_value = 0.0
		},
		{
			name = 'B',
			type = 'Variant',
			id = &'b',
			doc = 'The second number.',
			type_from = &'result',
			default_value = 0.0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Variant', id = &'result', doc = 'The function result.'}
	]


func get_output_result() -> String:
	return '{{func_name}}({{a}}, {{b}})'


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
