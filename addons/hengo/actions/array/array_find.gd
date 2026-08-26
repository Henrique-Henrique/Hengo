@tool
class_name HenActionArrayFind extends HenScriptMacroBase


# writes the position of the first Value in Array into Store, or -1 when it is
# not there.


func get_id() -> StringName:
	return &'array_find'


func get_description() -> String:
	return 'Finds the position of the first matching item in an array and stores it. Stores -1 when the item is not present.'


func get_display_name() -> String:
	return 'Array Find'


func get_icon() -> String:
	return 'search'


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
			doc = 'The item to look for.',
			default_value = 0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Index', type = 'int', id = &'result', doc = 'The position of the item, or -1 when not found.'}
	]


func get_output_result() -> String:
	if any_flow_connected():
		return 'idx_{{VCNODE_ID}}'

	return _find_expr()


func _find_expr() -> String:
	return '{{array}}.find({{value}})'


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
			doc = 'Where to go when the item is in the array.'
		},
		{
			name = 'Not Found',
			id = &'not_found',
			optional = true,
			doc = 'Where to go when the item is missing, which is when -1 is stored.'
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


func _body() -> String:
	if not any_flow_connected():
		return '{{out:result}}'

	return 'var idx_{{VCNODE_ID}} = ' + _find_expr() + '\n' \
		+ '{{out:result}}\n' \
		+ 'if idx_{{VCNODE_ID}} != -1:\n' \
		+ '\t{{found}}\n' \
		+ 'else:\n' \
		+ '\t{{not_found}}'
