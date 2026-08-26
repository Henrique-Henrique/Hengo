@tool
class_name HenActionArraySort extends HenScriptMacroBase


# sorts Array in place, smallest first. Array must be bound to a variable/property.


func get_id() -> StringName:
	return &'array_sort'


func get_description() -> String:
	return 'Sorts the items of an array in place, smallest first. Numbers and text sort in their natural order.'


func get_display_name() -> String:
	return 'Array Sort'


func get_icon() -> String:
	return 'arrow-down-up'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Array',
			type = 'Array',
			id = &'array',
			doc = 'The array to sort. Must be bound to a variable or property.',
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
	return '{{array}}.sort()'
