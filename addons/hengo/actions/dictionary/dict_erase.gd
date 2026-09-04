@tool
class_name HenActionDictErase extends HenScriptMacroBase


# removes Key from Dictionary. Dictionary must be bound to a variable/property.


func get_id() -> StringName:
	return &'dict_erase'


func get_description() -> String:
	return 'Removes a key and its value from a dictionary. Does nothing if the key is missing.'


func get_display_name() -> String:
	return 'Dictionary Erase'


func get_icon() -> String:
	return 'circle-minus'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Dictionary',
			type = 'Dictionary',
			id = &'dict',
			doc = 'The dictionary to remove from. Must be bound to a variable or property.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Key',
			type = 'String',
			id = &'key',
			doc = 'The key to remove.',
			default_value = ''
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
	return '{{dict}}.erase({{key}})'
