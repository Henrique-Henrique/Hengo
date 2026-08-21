@tool
class_name HenActionFilterList extends HenScriptMacroBase


func get_id() -> StringName:
	return &'filter_list'


func get_description() -> String:
	return 'Keeps only the items of a list that pass a test, and stores the shorter list. Chaining two of them is how a filter with two conditions is written.'


func get_display_name() -> String:
	return 'Filter List'


func get_icon() -> String:
	return 'list-filter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'List',
			type = 'Array',
			id = &'list',
			doc = 'The list to walk through.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Property',
			type = 'String',
			id = &'property',
			doc = 'The property tested on each item, with a colon to reach a part of it, as in position:y. Leave it empty to test the item itself.',
			optional = true,
			default_value = ''
		},
		{
			name = 'Operator',
			type = 'String',
			id = &'op',
			doc = 'How the value is compared.',
			raw = true,
			options = ['==', '!=', '>', '>=', '<', '<='],
			default_value = '=='
		},
		{
			name = 'Value',
			type = 'Variant',
			id = &'value',
			doc = 'What each item is compared against.',
			default_value = 0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Array', id = &'result', doc = 'The items that passed the test.'}
	]


func get_output_result() -> String:
	if any_flow_connected():
		return 'kept_{{VCNODE_ID}}'

	return _filter_expr()


# get_indexed and not get: it also reaches a part of a property, as in position:y
func _filter_expr() -> String:
	if _tests_property():
		return '{{list}}.filter(func(it): return it.get_indexed({{property}}) {{op}} {{value}})'

	return '{{list}}.filter(func(it): return it {{op}} {{value}})'


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
			name = 'Any',
			id = &'any',
			optional = true,
			doc = 'Where to go when at least one item passed the test.'
		},
		{
			name = 'None',
			id = &'none',
			optional = true,
			doc = 'Where to go when no item passed, which is when an empty list is stored.'
		}
	]


func _tests_property() -> bool:
	return is_bound(&'property') or not str(value_of(&'property', '')).is_empty()


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

	return 'var kept_{{VCNODE_ID}} = ' + _filter_expr() + '\n' \
		+ '{{out:result}}\n' \
		+ 'if not kept_{{VCNODE_ID}}.is_empty():\n' \
		+ '\t{{any}}\n' \
		+ 'else:\n' \
		+ '\t{{none}}'
