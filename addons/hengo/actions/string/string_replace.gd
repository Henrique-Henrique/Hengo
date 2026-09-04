@tool
class_name HenActionStringReplace extends HenScriptMacroBase


# writes Value with every From occurrence swapped for To into Store.


func get_id() -> StringName:
	return &'string_replace'


func get_description() -> String:
	return 'Replaces every occurrence of one piece of text with another and stores the result.'


func get_display_name() -> String:
	return 'String Replace'


func get_icon() -> String:
	return 'replace'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Value',
			type = 'String',
			id = &'value',
			doc = 'The text to search through.',
			default_value = ''
		},
		{
			name = 'From',
			type = 'String',
			id = &'from',
			doc = 'The piece of text to replace.',
			default_value = ''
		},
		{
			name = 'To',
			type = 'String',
			id = &'to',
			doc = 'The text to put in its place.',
			default_value = ''
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'String', id = &'result', doc = 'Where to store the updated text.'}
	]


func get_output_result() -> String:
	return 'str({{value}}).replace({{from}}, {{to}})'


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
