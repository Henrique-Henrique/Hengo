@tool
class_name HenActionArrayPop extends HenScriptMacroBase


# removes and writes the last or first item of Array into Store. an empty
# array returns null, so check the length first when the size matters.


func get_id() -> StringName:
	return &'array_pop'


func get_description() -> String:
	return 'Removes and returns the last or first item of an array. An empty array returns null.'


func get_display_name() -> String:
	return 'Array Pop'


func get_icon() -> String:
	return 'list-x'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Array',
			type = 'Array',
			id = &'array',
			doc = 'The array to pop from. Must be bound to a variable or property.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'End',
			type = 'String',
			id = &'end',
			doc = 'Which end of the array the item is removed from.',
			raw = true,
			options = ['back', 'front'],
			default_value = 'back'
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Variant', id = &'result', doc = 'Where to store the removed item.'}
	]


func get_output_result() -> String:
	if any_flow_connected():
		return 'item_{{VCNODE_ID}}'

	return _pop_expr()


func _pop_expr() -> String:
	return '{{array}}.pop_{{end}}()'


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
			name = 'Got One',
			id = &'got_one',
			optional = true,
			doc = 'Where to go when an item came out of the array.'
		},
		{
			name = 'Empty',
			id = &'empty',
			optional = true,
			doc = 'Where to go when the array had nothing left, which is when null is stored.'
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

	return 'var item_{{VCNODE_ID}} = ' + _pop_expr() + '\n' \
		+ '{{out:result}}\n' \
		+ 'if item_{{VCNODE_ID}} != null:\n' \
		+ '\t{{got_one}}\n' \
		+ 'else:\n' \
		+ '\t{{empty}}'
