@tool
class_name HenActionStringContains extends HenScriptMacroBase


# branches on whether Value contains Substring.


func get_id() -> StringName:
	return &'string_contains'


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
			default_value = ''
		},
		{
			name = 'Substring',
			type = 'String',
			id = &'substring',
			default_value = ''
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true'},
		{name = 'False', id = &'false'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func _body() -> String:
	return 'if str({{value}}).contains({{substring}}):\n\t{{true}}\nelse:\n\t{{false}}'
