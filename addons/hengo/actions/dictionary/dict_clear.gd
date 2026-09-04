@tool
class_name HenActionDictClear extends HenScriptMacroBase


# empties Dictionary in place. Dictionary must be bound to a variable/property.


func get_id() -> StringName:
	return &'dict_clear'


func get_description() -> String:
	return 'Removes every key and value from a dictionary, leaving it empty.'


func get_display_name() -> String:
	return 'Dictionary Clear'


func get_icon() -> String:
	return 'trash-2'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Dictionary',
			type = 'Dictionary',
			id = &'dict',
			doc = 'The dictionary to empty. Must be bound to a variable or property.',
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
	return '{{dict}}.clear()'
