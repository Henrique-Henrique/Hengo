@tool
class_name HenActionCheck extends HenScriptMacroBase


func get_id() -> StringName:
	return &'check'


func get_description() -> String:
	return 'Compares two values and keeps the true or false answer as a value. Unlike Compare, it does not change state, so the answer can feed another action.'


func get_display_name() -> String:
	return 'Check'


func get_icon() -> String:
	return 'equal'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'A',
			type = 'Variant',
			id = &'a',
			doc = 'The left value in the comparison.',
			default_value = 0
		},
		{
			name = 'Operator',
			type = 'String',
			id = &'op',
			doc = 'How to compare the two values.',
			raw = true,
			options = ['==', '!=', '>', '>=', '<', '<='],
			default_value = '=='
		},
		{
			name = 'B',
			type = 'Variant',
			id = &'b',
			doc = 'The right value in the comparison.',
			type_from = &'a',
			default_value = 0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'bool', id = &'result', doc = 'True when the comparison holds, false otherwise.'}
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
