@tool
class_name HenActionFilterNodes extends HenScriptMacroBase


func get_id() -> StringName:
	return &'filter_nodes'


func get_description() -> String:
	return 'Collects the nodes of a group whose property passes a comparison and stores them as an array. Pair it with For Each to act only on the ones that matched.'


func get_display_name() -> String:
	return 'Get Nodes Where'


func get_icon() -> String:
	return 'list-filter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Group',
			type = 'StringName',
			id = &'group',
			picker = 'group',
			doc = 'The group whose nodes are looked at.',
			default_value = 'enemies'
		},
		{
			name = 'Property',
			type = 'String',
			id = &'property',
			doc = 'The property read on each node, such as visible or health.',
			default_value = 'visible'
		},
		{
			name = 'Operator',
			type = 'String',
			id = &'op',
			doc = 'How the property is compared to the value.',
			raw = true,
			options = ['==', '!=', '>', '>=', '<', '<='],
			default_value = '=='
		},
		{
			name = 'Value',
			type = 'Variant',
			id = &'value',
			doc = 'The value the property is compared against.',
			default_value = 0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Array', id = &'result', doc = 'Where to store the array of nodes that matched.'}
	]


func get_output_result() -> String:
	if any_flow_connected():
		return 'kept_{{VCNODE_ID}}'

	return _filter_expr()


func _filter_expr() -> String:
	return '_ref.get_tree().get_nodes_in_group({{group}}).filter(func(n): return n.get({{property}}) {{op}} {{value}})'


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
			doc = 'Where to go when at least one node passed the comparison.'
		},
		{
			name = 'None',
			id = &'none',
			optional = true,
			doc = 'Where to go when no node passed, which is when an empty array is stored.'
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

	return 'var kept_{{VCNODE_ID}} = ' + _filter_expr() + '\n' \
		+ '{{out:result}}\n' \
		+ 'if not kept_{{VCNODE_ID}}.is_empty():\n' \
		+ '\t{{any}}\n' \
		+ 'else:\n' \
		+ '\t{{none}}'
