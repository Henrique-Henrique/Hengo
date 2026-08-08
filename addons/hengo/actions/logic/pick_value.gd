@tool
class_name HenActionPickValue extends HenScriptMacroBase


func get_id() -> StringName:
	return &'pick_value'


func get_description() -> String:
	return 'Picks between two values depending on a condition and keeps the chosen one.'


func get_display_name() -> String:
	return 'Pick Value'


func get_icon() -> String:
	return 'split'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Condition',
			type = 'bool',
			id = &'condition',
			doc = 'The test that decides which value is taken.',
			default_value = true
		},
		{
			name = 'If True',
			type = 'Variant',
			id = &'if_true',
			doc = 'The value taken when the condition is true.',
			default_value = 0
		},
		{
			name = 'If False',
			type = 'Variant',
			id = &'if_false',
			doc = 'The value taken when the condition is false.',
			type_from = &'if_true',
			default_value = 0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Variant', id = &'result', doc = 'The value that was picked.'}
	]


func get_output_result() -> String:
	return '{{if_true}} if {{condition}} else {{if_false}}'


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
