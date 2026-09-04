@tool
class_name HenActionDictSet extends HenScriptMacroBase


# writes Value at Key. Dictionary must be bound to a variable/property.


func get_id() -> StringName:
	return &'dict_set'


func get_description() -> String:
	return 'Writes a value under a given key in a dictionary. Overwrites the key if it already exists.'


func get_display_name() -> String:
	return 'Dictionary Set'


func get_icon() -> String:
	return 'square-plus'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Dictionary',
			type = 'Dictionary',
			id = &'dict',
			doc = 'The dictionary to write into. Must be bound to a variable or property.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Key',
			type = 'String',
			id = &'key',
			doc = 'The key to write the value under.',
			default_value = ''
		},
		{
			name = 'Value',
			type = 'Variant',
			id = &'value',
			doc = 'The value stored at the key.',
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
	return '{{dict}}[{{key}}] = {{value}}'
