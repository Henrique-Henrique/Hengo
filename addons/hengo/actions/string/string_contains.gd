@tool
class_name HenActionStringContains extends HenScriptMacroBase


# branches on whether Value contains Substring.


func get_id() -> StringName:
	return &'string_contains'


func get_description() -> String:
	return 'Answers whether a piece of text appears inside another. It can branch on the answer or hand it to a field that takes a yes or no.'


func get_display_name() -> String:
	return 'String Contains'


func get_icon() -> String:
	return 'search'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Value',
			type = 'String',
			id = &'value',
			doc = 'The text to search within.',
			default_value = ''
		},
		{
			name = 'Substring',
			type = 'String',
			id = &'substring',
			doc = 'The piece of text to look for.',
			default_value = ''
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Yes', type = 'bool', id = &'result', doc = 'Where to store whether the text was found.'}
	]


func get_output_result() -> String:
	return 'str({{value}}).contains({{substring}})'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true', optional = true, doc = 'Where to go when the substring is found.'},
		{name = 'False', id = &'false', optional = true, doc = 'Where to go when the substring is not found.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# with no branch wired it is only the answer, which is what lets it be read
# from inside another action's field
func _body() -> String:
	if not any_flow_connected():
		return '{{out:result}}'

	return '{{out:result}}\n' \
		+ 'if str({{value}}).contains({{substring}}):\n' \
		+ '\t{{true}}\n' \
		+ 'else:\n' \
		+ '\t{{false}}'
