@tool
class_name HenActionStringFormat extends HenScriptMacroBase


# writes Template with Value spliced in via % into Store; bind Value to an
# array for multiple placeholders (e.g. `%s/%s`).


func get_id() -> StringName:
	return &'string_format'


func get_description() -> String:
	return 'Fills placeholders in a template with a value and stores the result. A value bound to an array fills several placeholders at once.'


func get_display_name() -> String:
	return 'Format String'


func get_icon() -> String:
	return 'type'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Template',
			type = 'String',
			id = &'template',
			doc = 'The text with placeholders such as %s to fill in.',
			default_value = '%s'
		},
		{
			name = 'Value',
			type = 'Variant',
			id = &'value',
			doc = 'The value to place into the template.',
			default_value = ''
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'String', id = &'result', doc = 'Where to store the filled-in text.'}
	]


func get_output_result() -> String:
	return '{{template}} % {{value}}'


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
