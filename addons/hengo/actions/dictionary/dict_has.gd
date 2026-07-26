@tool
class_name HenActionDictHas extends HenScriptMacroBase


# branches on whether Dictionary holds Key.


func get_id() -> StringName:
	return &'dict_has'


func get_description() -> String:
	return 'Checks whether a dictionary holds a given key and branches on the result.'


func get_display_name() -> String:
	return 'Dictionary Has'


func get_icon() -> String:
	return 'key-round'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Dictionary',
			type = 'Dictionary',
			id = &'dict',
			doc = 'The dictionary to search.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Key',
			type = 'String',
			id = &'key',
			doc = 'The key to look for.',
			default_value = ''
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true', doc = 'Where to go when the key is found.'},
		{name = 'False', id = &'false', doc = 'Where to go when the key is missing.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func _body() -> String:
	return 'if {{dict}}.has({{key}}):\n\t{{true}}\nelse:\n\t{{false}}'
