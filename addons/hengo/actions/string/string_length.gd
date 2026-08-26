@tool
class_name HenActionStringLength extends HenScriptMacroBase


# writes the number of characters in Value into Store.


func get_id() -> StringName:
	return &'string_length'


func get_description() -> String:
	return 'Counts how many characters a piece of text holds and stores the number.'


func get_display_name() -> String:
	return 'String Length'


func get_icon() -> String:
	return 'ruler'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Value',
			type = 'String',
			id = &'value',
			doc = 'The text to measure.',
			default_value = ''
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Length', type = 'int', id = &'result', doc = 'Where to store the number of characters.'}
	]


func get_output_result() -> String:
	return 'str({{value}}).length()'


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
