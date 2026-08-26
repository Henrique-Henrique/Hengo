@tool
class_name HenActionStringTrim extends HenScriptMacroBase


# writes Value with leading and trailing whitespace removed into Store, the
# cleanup a typed-in field usually needs.


func get_id() -> StringName:
	return &'string_trim'


func get_description() -> String:
	return 'Removes the spaces and line breaks from the start and end of a piece of text. Useful to clean up what was typed into a field.'


func get_display_name() -> String:
	return 'Trim Text'


func get_icon() -> String:
	return 'scissors'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Value',
			type = 'String',
			id = &'value',
			doc = 'The text to trim.',
			default_value = ''
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'String', id = &'result', doc = 'The trimmed text.'}
	]


func get_output_result() -> String:
	return 'str({{value}}).strip_edges()'


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
