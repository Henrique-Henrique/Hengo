@tool
class_name HenActionArrayShuffle extends HenScriptMacroBase


# randomizes the order of Array in place. Array must be bound to a variable/property.


func get_id() -> StringName:
	return &'array_shuffle'


func get_description() -> String:
	return 'Randomizes the order of the items in an array.'


func get_display_name() -> String:
	return 'Array Shuffle'


func get_icon() -> String:
	return 'shuffle'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Array',
			type = 'Array',
			id = &'array',
			doc = 'The array to shuffle. Must be bound to a variable or property.',
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
	return '{{array}}.shuffle()'
