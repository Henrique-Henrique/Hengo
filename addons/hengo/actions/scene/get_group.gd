@tool
class_name HenActionGetGroup extends HenScriptMacroBase


# writes every node of Group into Store as an array. pair it with For Each to act
# on all of them; Get Nearest already handles the closest-one case.


func get_id() -> StringName:
	return &'get_group'


func get_description() -> String:
	return 'Collects every node in a group and stores it as an array. Pair it with For Each to act on all of them at once.'


func get_display_name() -> String:
	return 'Get Group'


func get_icon() -> String:
	return 'group'


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Group',
			type = 'StringName',
			id = &'group',
			picker = 'group',
			doc = 'The group whose nodes are collected.',
			default_value = 'enemies'
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Members', type = 'Array', id = &'members', doc = 'Where to store the array of nodes in the group.'}
	]


func get_output_members() -> String:
	if any_flow_connected():
		return 'members_{{VCNODE_ID}}'

	return _group_expr()


func _group_expr() -> String:
	return '_ref.get_tree().get_nodes_in_group({{group}})'


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
			doc = 'Where to go when the group has at least one node.'
		},
		{
			name = 'None',
			id = &'none',
			optional = true,
			doc = 'Where to go when the group is empty, which is when an empty array is stored.'
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
		return '{{out:members}}'

	return 'var members_{{VCNODE_ID}} = ' + _group_expr() + '\n' \
		+ '{{out:members}}\n' \
		+ 'if not members_{{VCNODE_ID}}.is_empty():\n' \
		+ '\t{{any}}\n' \
		+ 'else:\n' \
		+ '\t{{none}}'
