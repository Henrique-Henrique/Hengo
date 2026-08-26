@tool
class_name HenActionGetNode extends HenScriptMacroBase


func get_id() -> StringName:
	return &'get_node'


func get_description() -> String:
	return 'Looks up a node by its path and stores it so later actions can use it. Stores null when nothing is found at that path. It answers what sits at the path right now, so When It Changes is the one that fires only on the frame that answer becomes something else.'


func get_display_name() -> String:
	return 'Get Node'


func get_icon() -> String:
	return 'list-tree'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node the path starts from. Leave it empty to start from this node.', 'From'),
		{
			name = 'Path',
			type = 'String',
			id = &'path',
			doc = 'The path to the node, relative to From.',
			default_value = 'Sprite2D'
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Node', type = 'Variant', id = &'result', doc = 'Where to store the node that was found.'}
	]


# with a branch the lookup lives in a local, so the rhs reads it instead of running twice
func get_output_result() -> String:
	if any_flow_connected():
		return 'node_{{VCNODE_ID}}'

	return '{{ref}}.get_node_or_null({{path}})'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{
			name = 'Found',
			id = &'found',
			optional = true,
			doc = 'Where to go when the path resolved to a node.'
		},
		{
			name = 'Missing',
			id = &'missing',
			optional = true,
			doc = 'Where to go when nothing sits at that path, which is when null is stored.'
		}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	if not any_flow_connected():
		return '{{out:result}}'

	return 'var node_{{VCNODE_ID}} = {{ref}}.get_node_or_null({{path}})\n' \
		+ '{{out:result}}\n' \
		+ 'if node_{{VCNODE_ID}} != null:\n' \
		+ '\t{{found}}\n' \
		+ 'else:\n' \
		+ '\t{{missing}}'
