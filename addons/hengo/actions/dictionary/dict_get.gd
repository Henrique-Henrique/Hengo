@tool
class_name HenActionDictGet extends HenScriptMacroBase


# writes the value at Key into Result. uses .get so a missing key returns Default
# instead of breaking at runtime.


func get_id() -> StringName:
	return &'dict_get'


func get_description() -> String:
	return 'Reads the value stored under a given key in a dictionary. A missing key returns the default value.'


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
		},
		{
			name = 'Default',
			type = 'Variant',
			id = &'default',
			doc = 'The value returned when the key is not in the dictionary.',
			optional = true,
			default_value = null
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Variant', id = &'result', doc = 'Where to store the value found at the key, or the default when missing.'}
	]


func get_output_result() -> String:
	return '{{dict}}.get({{key}}, {{default}})'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{
			name = 'Found',
			id = &'found',
			optional = true,
			doc = 'Where to go when the key is in the dictionary.'
		},
		{
			name = 'Missing',
			id = &'missing',
			optional = true,
			doc = 'Where to go when the key is absent, which is when the default is stored.'
		}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func get_flow_exit() -> String:
	return _body()


# has() and not the stored value: a missing key gives back Default, which can be anything
func _body() -> String:
	if not any_flow_connected():
		return '{{out:result}}'

	return '{{out:result}}\n' \
		+ 'if {{dict}}.has({{key}}):\n' \
		+ '\t{{found}}\n' \
		+ 'else:\n' \
		+ '\t{{missing}}'
