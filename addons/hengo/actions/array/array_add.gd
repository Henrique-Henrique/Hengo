@tool
class_name HenActionArrayAdd extends HenScriptMacroBase


# appends Value to Array. Array must be bound to a variable/property.


func get_id() -> StringName:
	return &'array_add'


func get_description() -> String:
	return 'Appends a value to the end of an array.'


func get_display_name() -> String:
	return 'Array Add'


func get_icon() -> String:
	return 'list-plus'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Array',
			type = 'Array',
			id = &'array',
				doc = 'The array to append to. Must be bound to a variable or property.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Value',
			type = 'Variant',
			id = &'value',
				doc = 'The value to add to the array.',
			default_value = 0
		}
	]


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
	return '{{array}}.append({{value}})'
