@tool
class_name HenActionArrayContains extends HenScriptMacroBase


# branches on whether Array holds Value.


func get_id() -> StringName:
	return &'array_contains'


func get_display_name() -> String:
	return 'Array Contains'


func get_icon() -> String:
	return 'list-checks'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Array',
			type = 'Array',
			id = &'array',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Value',
			type = 'Variant',
			id = &'value',
			default_value = 0
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
	return 'if {{value}} in {{array}}:\n\t{{true}}\nelse:\n\t{{false}}'
