@tool
class_name HenActionHasNode extends HenScriptMacroBase


# branches on whether a child exists at Path, relative to the owner. use it
# before reading a node that may have been freed or never spawned.


func get_id() -> StringName:
	return &'has_node'


func get_description() -> String:
	return 'Answers whether a node sits at the given path. It can branch on the answer or hand it to a field that takes a yes or no.'


func get_display_name() -> String:
	return 'Has Node'


func get_icon() -> String:
	return 'git-branch'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node the path starts from. Leave it empty to start from this node.', 'From'),
		{
			name = 'Path',
			type = 'String',
			id = &'path',
			doc = 'The node path to check, relative to this node.',
			default_value = ''
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Yes', type = 'bool', id = &'result', doc = 'Where to store whether the node is there.'}
	]


func get_output_result() -> String:
	return '{{ref}}.has_node({{path}})'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true', optional = true, doc = 'Where to go when the node exists.'},
		{name = 'False', id = &'false', optional = true, doc = 'Where to go when the node is missing.'}
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
		+ 'if {{ref}}.has_node({{path}}):\n' \
		+ '\t{{true}}\n' \
		+ 'else:\n' \
		+ '\t{{false}}'
