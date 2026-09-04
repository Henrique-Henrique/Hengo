@tool
class_name HenActionArrayContains extends HenScriptMacroBase


# branches on whether Array holds Value.


func get_id() -> StringName:
	return &'array_contains'


func get_description() -> String:
	return 'Answers whether an array holds a given value. It can branch on the answer or hand it to a field that takes a yes or no.'


func get_display_name() -> String:
	return 'Array Contains'


func get_icon() -> String:
	return 'list-checks'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Array',
			type = 'Array',
			id = &'array',
				doc = 'The array to search.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Value',
			type = 'Variant',
			id = &'value',
				doc = 'The value to look for.',
			default_value = 0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Yes', type = 'bool', id = &'result', doc = 'Where to store whether the value is in the array.'}
	]


func get_output_result() -> String:
	return '{{value}} in {{array}}'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true', optional = true, doc = 'Where to go when the value is found.'},
		{name = 'False', id = &'false', optional = true, doc = 'Where to go when the value is missing.'}
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
		+ 'if {{value}} in {{array}}:\n' \
		+ '\t{{true}}\n' \
		+ 'else:\n' \
		+ '\t{{false}}'
