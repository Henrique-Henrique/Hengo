@tool
class_name HenActionCombineChecks extends HenScriptMacroBase


func get_id() -> StringName:
	return &'combine_checks'


func get_description() -> String:
	return 'Joins two tests into one, demanding both or accepting either. It is what a condition with two parts needs before reaching Do If or Pick Value.'


func get_display_name() -> String:
	return 'Combine Checks'


func get_icon() -> String:
	return 'git-branch-plus'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'First',
			type = 'bool',
			id = &'a',
			doc = 'The first test.',
			default_value = true
		},
		{
			name = 'Mode',
			type = 'String',
			id = &'op',
			doc = 'Whether both tests have to pass, or just one of them.',
			raw = true,
			options = ['and', 'or'],
			default_value = 'and'
		},
		{
			name = 'Second',
			type = 'bool',
			id = &'b',
			doc = 'The second test.',
			default_value = true
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'bool', id = &'result', doc = 'The answer of the two tests together.'}
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
