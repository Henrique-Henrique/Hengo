@tool
class_name HenActionArrayReverse extends HenScriptMacroBase


# flips the order of Array in place. Array must be bound to a variable/property.


func get_id() -> StringName:
	return &'array_reverse'


func get_description() -> String:
	return 'Flips the order of the items in an array in place, so the last becomes the first.'


func get_display_name() -> String:
	return 'Array Reverse'


func get_icon() -> String:
	return 'flip-vertical-2'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Array',
			type = 'Array',
			id = &'array',
			doc = 'The array to reverse. Must be bound to a variable or property.',
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
	return '{{array}}.reverse()'
