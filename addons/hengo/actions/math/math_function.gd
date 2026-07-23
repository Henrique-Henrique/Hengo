@tool
class_name HenActionMathFunction extends HenScriptMacroBase


# writes Function(Value) into Store — one of abs/sign/round/floor/ceil/sqrt.


func get_id() -> StringName:
	return &'math_function'


func get_display_name() -> String:
	return 'Math Function'


func get_icon() -> String:
	return 'square-function'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Function',
			type = 'String',
			id = &'func_name',
			raw = true,
			options = ['abs', 'sign', 'round', 'floor', 'ceil', 'sqrt'],
			default_value = 'abs'
		},
		{
			name = 'Value',
			type = 'Variant',
			id = &'value',
			type_from = &'result',
			default_value = 0.0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Variant', id = &'result'}
	]


func get_output_result() -> String:
	return '{{func_name}}({{value}})'


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
