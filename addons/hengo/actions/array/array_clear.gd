@tool
class_name HenActionArrayClear extends HenScriptMacroBase


# empties Array in place. Array must be bound to a variable/property.


func get_id() -> StringName:
	return &'array_clear'


func get_description() -> String:
	return 'Removes every item from an array, leaving it empty.'


func get_display_name() -> String:
	return 'Array Clear'


func get_icon() -> String:
	return 'trash-2'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Array',
			type = 'Array',
			id = &'array',
			doc = 'The array to empty. Must be bound to a variable or property.',
			bind_only = true,
			default_value = null
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
	return '{{array}}.clear()'
