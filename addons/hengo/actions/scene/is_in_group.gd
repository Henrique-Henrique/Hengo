@tool
class_name HenActionIsInGroup extends HenScriptMacroBase


# branches on whether the owner carries a group tag.


func get_id() -> StringName:
	return &'is_in_group'


func get_description() -> String:
	return 'Answers whether a node belongs to a group. It can branch on the answer or hand it to a field that takes a yes or no.'


func get_display_name() -> String:
	return 'Is In Group'


func get_icon() -> String:
	return 'users'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node to check. Leave it empty to check this node.'),
		{
			name = 'Group',
			type = 'StringName',
			id = &'group',
			picker = 'group',
			doc = 'The group name to check for.',
			default_value = 'enemies'
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Yes', type = 'bool', id = &'result', doc = 'Where to store whether the node is in the group.'}
	]


func get_output_result() -> String:
	return '{{ref}}.is_in_group({{group}})'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true', optional = true, doc = 'Where to go when the node is in the group.'},
		{name = 'False', id = &'false', optional = true, doc = 'Where to go when the node is not in the group.'}
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
		+ 'if {{ref}}.is_in_group({{group}}):\n' \
		+ '\t{{true}}\n' \
		+ 'else:\n' \
		+ '\t{{false}}'
