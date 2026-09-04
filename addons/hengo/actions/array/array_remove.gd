@tool
class_name HenActionArrayRemove extends HenScriptMacroBase


# removes the first item equal to Value. Array must be bound to a variable/property.


func get_id() -> StringName:
	return &'array_remove'


func get_description() -> String:
	return 'Removes the first item equal to a value from an array. Does nothing when the value is not found.'


func get_display_name() -> String:
	return 'Array Remove'


func get_icon() -> String:
	return 'list-x'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Array',
			type = 'Array',
			id = &'array',
			doc = 'The array to remove from. Must be bound to a variable or property.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Value',
			type = 'Variant',
			id = &'value',
			doc = 'The value to remove. Only the first match is removed.',
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
	return '{{array}}.erase({{value}})'
