@tool
class_name HenActionJoinLists extends HenScriptMacroBase


func get_id() -> StringName:
	return &'join_lists'


func get_description() -> String:
	return 'Puts two lists together into a new one, such as pouring a discard pile back into a deck.'


func get_display_name() -> String:
	return 'Join Lists'


func get_icon() -> String:
	return 'list-plus'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'First',
			type = 'Array',
			id = &'a',
			doc = 'The list that comes first.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Second',
			type = 'Array',
			id = &'b',
			doc = 'The list added after it.',
			bind_only = true,
			default_value = null
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Array', id = &'result', doc = 'The two lists, one after the other.'}
	]


func get_output_result() -> String:
	return '{{a}} + {{b}}'


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
