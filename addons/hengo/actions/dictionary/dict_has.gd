@tool
class_name HenActionDictHas extends HenScriptMacroBase


# branches on whether Dictionary holds Key.


func get_id() -> StringName:
	return &'dict_has'


func get_description() -> String:
	return 'Answers whether a dictionary holds a given key. It can branch on the answer or hand it to a field that takes a yes or no.'


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


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Yes', type = 'bool', id = &'result', doc = 'Where to store whether the key is in the dictionary.'}
	]


func get_output_result() -> String:
	return '{{dict}}.has({{key}})'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true', optional = true, doc = 'Where to go when the key is found.'},
		{name = 'False', id = &'false', optional = true, doc = 'Where to go when the key is missing.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# with no branch wired it is only the answer, which is what lets it be read
# from inside another action's field
func _body() -> String:
	if not any_flow_connected():
		return '{{out:result}}'

	return '{{out:result}}\n' \
		+ 'if {{dict}}.has({{key}}):\n' \
		+ '\t{{true}}\n' \
		+ 'else:\n' \
		+ '\t{{false}}'
