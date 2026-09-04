@tool
class_name HenActionDictValues extends HenScriptMacroBase


# writes every value of Dictionary into Result, in insertion order.


func get_id() -> StringName:
	return &'dict_values'


func get_description() -> String:
	return 'Reads every value of a dictionary into an array, in insertion order.'


func get_display_name() -> String:
	return 'Dictionary Values'


func get_icon() -> String:
	return 'layout-list'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Dictionary',
			type = 'Dictionary',
			id = &'dict',
			doc = 'The dictionary to read from.',
			bind_only = true,
			default_value = null
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Array', id = &'result', doc = 'Where to store the array of values.'}
	]


func get_output_result() -> String:
	return '{{dict}}.values()'


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
