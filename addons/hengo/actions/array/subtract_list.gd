@tool
class_name HenActionSubtractList extends HenScriptMacroBase


func get_id() -> StringName:
	return &'subtract_list'


func get_description() -> String:
	return 'Stores the items of a list that are not in a second one, such as the cards of a deck that are not in the hand.'


func get_display_name() -> String:
	return 'Subtract List'


func get_icon() -> String:
	return 'list-x'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'List',
			type = 'Array',
			id = &'list',
			doc = 'The list to take items from.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Without',
			type = 'Array',
			id = &'without',
			doc = 'The items to leave out.',
			bind_only = true,
			default_value = null
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Array', id = &'result', doc = 'What is left of the first list.'}
	]


func get_output_result() -> String:
	return '{{list}}.filter(func(it): return not it in {{without}})'


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
