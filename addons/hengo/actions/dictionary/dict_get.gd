@tool
class_name HenActionDictGet extends HenScriptMacroBase


# writes the value at Key into Result. uses .get so a missing key returns null
# instead of breaking at runtime.


func get_id() -> StringName:
	return &'dict_get'


func get_description() -> String:
	return 'Reads the value stored under a given key in a dictionary. A missing key returns null.'


func get_display_name() -> String:
	return 'Dictionary Get'


func get_icon() -> String:
	return 'key'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Dictionary',
			type = 'Dictionary',
			id = &'dict',
			doc = 'The dictionary to read from.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Key',
			type = 'String',
			id = &'key',
			doc = 'The key to look up.',
			default_value = ''
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Variant', id = &'result', doc = 'Where to store the value found at the key, or null when missing.'}
	]


func get_output_result() -> String:
	return '{{dict}}.get({{key}})'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_exit() -> String:
	return _body()


func _body() -> String:
	return '{{out:result}}'
