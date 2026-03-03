@tool
class_name HenStateViewerDataParser
extends RefCounted

# parses the dictionary and builds the node tree (pass 1)
func parse_machine(dict: Dictionary, id_prefix: String = '') -> HenStateViewerGraphTypes.DirectedGraphNode:
	var node_id: String = dict.id if dict.has('id') else 'machine'
	var full_id: String = id_prefix + '.' + node_id if id_prefix != '' else node_id

	var children: Array[HenStateViewerGraphTypes.DirectedGraphNode] = []
	var states: Dictionary = dict.states if dict.has('states') else {}

	for state_key in states.keys():
		var state_data: Dictionary = states[state_key]
		if not state_data.has('id'):
			state_data.id = state_key
		children.append(parse_machine(state_data, full_id))

	var node: HenStateViewerGraphTypes.DirectedGraphNode = HenStateViewerGraphTypes.DirectedGraphNode.new({
		id = full_id,
		state_node = dict,
		children = children
	})

	return node


# iterates through the built tree to connect all edges (pass 2)
func resolve_edges(root: HenStateViewerGraphTypes.DirectedGraphNode) -> void:
	_resolve_node_edges(root, root)


# internal recursive edge resolver
func _resolve_node_edges(node: HenStateViewerGraphTypes.DirectedGraphNode, root: HenStateViewerGraphTypes.DirectedGraphNode) -> void:
	_extract_edges(node, node.data, root)
	
	for child in node.children:
		_resolve_node_edges(child, root)


# reads 'on' transitions and creates directed graph edges
func _extract_edges(source: HenStateViewerGraphTypes.DirectedGraphNode, dict: Dictionary, root: HenStateViewerGraphTypes.DirectedGraphNode) -> void:
	if not dict.has('on'):
		return

	var transitions: Dictionary = dict.on
	var transition_index: int = 0

	# iterates transition keys to find target nodes
	for event_name in transitions.keys():
		var target_key: String = transitions[event_name]
		var target_node: HenStateViewerGraphTypes.DirectedGraphNode = _find_node_by_id(root, target_key)

		if target_node != null:
			var edge: HenStateViewerGraphTypes.DirectedGraphEdge = HenStateViewerGraphTypes.DirectedGraphEdge.new({
				id = source.id + ':' + str(transition_index) + ':' + target_node.id,
				source = source,
				target = target_node,
				transition = {event = event_name},
				label_text = event_name
			})
			source.edges.append(edge)

		transition_index += 1


# finds a node by its string id across the entire tree
func _find_node_by_id(current: HenStateViewerGraphTypes.DirectedGraphNode, target_id: String) -> HenStateViewerGraphTypes.DirectedGraphNode:
	if current.id == target_id or current.id.ends_with("." + target_id):
		return current

	for child in current.children:
		var found: HenStateViewerGraphTypes.DirectedGraphNode = _find_node_by_id(child, target_id)
		if found != null:
			return found

	return null