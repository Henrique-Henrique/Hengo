@tool
class_name HenStateViewerLayoutEngine
extends RefCounted

const LAYER_GAP: float = 96.0
const NODE_GAP: float = 64.0
const COMPOUND_PAD_TOP: float = 128.0
const COMPOUND_PAD_SIDE: float = 96.0
const COMPOUND_PAD_BOTTOM: float = 64.0


var _incoming_map: Dictionary = {}
var _outgoing_map: Dictionary = {}

# phase 1: layout all positions bottom-up, phase 2: route edges after positions are final
func execute_layout(root: HenStateViewerGraphTypes.DirectedGraphNode) -> void:
	_layout_recursive(root)
	
	_incoming_map.clear()
	_outgoing_map.clear()
	var all_edges: Array = []
	_get_all_descendant_edges(root, all_edges)
	
	for e in all_edges:
		if not _incoming_map.has(e.target.id):
			_incoming_map[e.target.id] = []
		_incoming_map[e.target.id].append(e)
		
		if not _outgoing_map.has(e.source.id):
			_outgoing_map[e.source.id] = []
		_outgoing_map[e.source.id].append(e)
		
		# Sort connections visually left-to-right to prevent crossing
	for tgt_id in _incoming_map:
		_incoming_map[tgt_id].sort_custom(func(a, b):
			var ax = _get_edge_aim_x(a, false)
			var bx = _get_edge_aim_x(b, false)
			if ax == bx:
				return a.id < b.id
			return ax < bx
		)
		
	for src_id in _outgoing_map:
		_outgoing_map[src_id].sort_custom(func(a, b):
			var ax = _get_edge_aim_x(a, true)
			var bx = _get_edge_aim_x(b, true)
			if ax == bx:
				return a.id < b.id
			return ax < bx
		)
		
	_route_recursive(root)


# bottom-up recursive layout: children first, then parent wraps them
func _layout_recursive(node: HenStateViewerGraphTypes.DirectedGraphNode) -> void:
	for child in node.children:
		_layout_recursive(child)

	if not node.children.is_empty():
		_layout_children(node)


# route edges only after all positions in the tree are finalized
func _route_recursive(node: HenStateViewerGraphTypes.DirectedGraphNode) -> void:
	for edge in node.edges:
		_route_edge(edge)


	for child in node.children:
		_route_recursive(child)


# positions direct children top-to-bottom by layer, then resizes parent to contain them
func _layout_children(parent: HenStateViewerGraphTypes.DirectedGraphNode) -> void:
	var children: Array = parent.children
	var layers: Dictionary = group_by_depth(children)
	var depth_keys: Array = layers.keys()
	depth_keys.sort()

	var current_y: float = COMPOUND_PAD_TOP
	
	# pre-calculate max width of any individual layer (the parent's inner content width)
	var max_layer_w: float = 0.0
	for depth in depth_keys:
		var w: float = 0.0
		for node in layers[depth]:
			w += node.layout.width
		w += max(0, layers[depth].size() - 1) * NODE_GAP
		max_layer_w = max(max_layer_w, w)

	for depth in depth_keys:
		var nodes_in_layer: Array = layers[depth]
		var layer_total_w: float = 0.0
		for node in nodes_in_layer:
			layer_total_w += node.layout.width
		layer_total_w += max(0, nodes_in_layer.size() - 1) * NODE_GAP

		# center the layer horizontally within the parent's content area
		var current_x: float = COMPOUND_PAD_SIDE + (max_layer_w - layer_total_w) * 0.5
		var max_h: float = 0.0

		for node in nodes_in_layer:
			node.layout.x = current_x
			node.layout.y = current_y
			
			current_x += node.layout.width + NODE_GAP
			max_h = max(max_h, node.layout.height)

		current_y += max_h + LAYER_GAP

	# resize parent to tightly wrap children
	var max_right: float = 0.0
	var max_bottom: float = 0.0
	for node in children:
		max_right = max(max_right, node.layout.x + node.layout.width)
		max_bottom = max(max_bottom, node.layout.y + node.layout.height)
	parent.layout.width = max(parent.layout.width, max_right + COMPOUND_PAD_SIDE)
	parent.layout.height = max(parent.layout.height, max_bottom + COMPOUND_PAD_BOTTOM)


# longest-path layering with edge hoisting and cycle detection
static func group_by_depth(nodes: Array) -> Dictionary:
	var node_map: Dictionary = {}
	for n in nodes:
		node_map[n.id] = n

	# hoist edges: collect all edges from each node's subtree that target another node in this layer
	var adj: Dictionary = {}
	for n in nodes:
		adj[n.id] = []
		var edges_out: Array = []
		_get_all_descendant_edges(n, edges_out)
		for edge in edges_out:
			var mapped_tgt: HenStateViewerGraphTypes.DirectedGraphNode = _find_ancestor_in_map(edge.target, node_map)
			if mapped_tgt != null and mapped_tgt.id != n.id:
				adj[n.id].append({edge = edge, target_id = mapped_tgt.id})

	# dfs coloring to detect back-edges (cycles)
	var visited: Dictionary = {}
	var on_stack: Dictionary = {}
	var back_edge_ids: Dictionary = {}
	for n in nodes:
		visited[n.id] = false
		on_stack[n.id] = false

	for n in nodes:
		if not visited[n.id]:
			_find_back_edges_hoisted(n.id, adj, visited, on_stack, back_edge_ids)

	# longest-path: only forward/cross edges push targets to higher layers
	var node_layers: Dictionary = {}
	for n in nodes:
		node_layers[n.id] = 0

	var changed: bool = true
	var limit: int = 0
	while changed and limit < nodes.size():
		changed = false
		limit += 1
		for n in nodes:
			for item in adj[n.id]:
				var tgt_id: String = item.target_id
				var edge: HenStateViewerGraphTypes.DirectedGraphEdge = item.edge
				if not back_edge_ids.has(edge.id):
					if node_layers[tgt_id] <= node_layers[n.id]:
						node_layers[tgt_id] = node_layers[n.id] + 1
						changed = true

	var dict: Dictionary = {}
	for n in nodes:
		var l: int = node_layers[n.id]
		if not dict.has(l):
			dict[l] = []
		dict[l].append(n)
	return dict


static func _get_all_descendant_edges(node: HenStateViewerGraphTypes.DirectedGraphNode, arr: Array) -> void:
	arr.append_array(node.edges)
	for child in node.children:
		_get_all_descendant_edges(child, arr)


static func _find_ancestor_in_map(target_node: HenStateViewerGraphTypes.DirectedGraphNode, node_map: Dictionary) -> HenStateViewerGraphTypes.DirectedGraphNode:
	var current: HenStateViewerGraphTypes.DirectedGraphNode = target_node
	while current != null:
		if node_map.has(current.id):
			return current
		current = current.parent
	return null


# marks edges to nodes currently being visited on the dfs stack as back-edges
static func _find_back_edges_hoisted(
	node_id: String,
	adj: Dictionary,
	visited: Dictionary,
	on_stack: Dictionary,
	back_edge_ids: Dictionary
) -> void:
	visited[node_id] = true
	on_stack[node_id] = true

	for item in adj[node_id]:
		var tgt_id: String = item.target_id
		var edge: HenStateViewerGraphTypes.DirectedGraphEdge = item.edge
		if on_stack[tgt_id]:
			back_edge_ids[edge.id] = true
		elif not visited[tgt_id]:
			_find_back_edges_hoisted(tgt_id, adj, visited, on_stack, back_edge_ids)

	on_stack[node_id] = false


# orthogonal routing: forward edges use s-curve, backward/complex edges route cleanly inside ancestor padding bounds
func _route_edge(edge: HenStateViewerGraphTypes.DirectedGraphEdge) -> void:
	var src_abs: Vector2 = edge.source.get_absolute()
	var tgt_abs: Vector2 = edge.target.get_absolute()

	var src_edges: Array = _outgoing_map[edge.source.id]
	var tgt_edges: Array = _incoming_map[edge.target.id]
	
	var src_idx: int = src_edges.find(edge)
	var out_count: int = src_edges.size()
	var src_offset: float = 0.0
	if out_count > 1:
		var spread: float = edge.source.layout.width * 0.7
		var step: float = spread / max(1, out_count - 1)
		src_offset = (src_idx * step) - (spread * 0.5)

	var tgt_idx: int = tgt_edges.find(edge)
	var in_count: int = tgt_edges.size()
	var tgt_offset: float = 0.0
	if in_count > 1:
		var spread: float = edge.target.layout.width * 0.7
		var step: float = spread / max(1, in_count - 1)
		tgt_offset = (tgt_idx * step) - (spread * 0.5)

	var start_pt: Vector2 = Vector2(
		src_abs.x + edge.source.layout.width * 0.5 + src_offset,
		src_abs.y + edge.source.layout.height
	)
	var end_pt: Vector2 = Vector2(
		tgt_abs.x + edge.target.layout.width * 0.5 + tgt_offset,
		tgt_abs.y
	)

	var ancestor: HenStateViewerGraphTypes.DirectedGraphNode = _find_common_ancestor(edge.source, edge.target)
	var is_backward: bool = start_pt.y >= end_pt.y
	var is_complex_forward: bool = false
	
	if not is_backward:
		# if the physical y-gap is larger than ~1.5 layer gaps, it crosses over intermediate siblings!
		var gap_dist: float = end_pt.y - start_pt.y
		if gap_dist > (LAYER_GAP * 1.5 + 30.0):
			is_complex_forward = true

	if is_backward or is_complex_forward:
		# highway routing: use the common ancestor's internal padding to safely route around nodes
		var anc_abs: Vector2 = ancestor.get_absolute() if ancestor != null else Vector2.ZERO
		var anc_w: float = ancestor.layout.width if ancestor != null else 500.0
		
		# stagger overlapping edges with distinct highway tracks
		var h_hash = edge.id.hash()
		if h_hash < 0: h_hash = - h_hash
		var offset: float = (h_hash % 4) * 12.0
		
		# route inside the padding area using allocated tracks
		var left_x: float = anc_abs.x + 20.0 + offset
		var right_x: float = anc_abs.x + anc_w - 20.0 - offset
		
		if ancestor == null:
			left_x = min(src_abs.x, tgt_abs.x) - 20.0 - offset
			right_x = max(src_abs.x + edge.source.layout.width, tgt_abs.x + edge.target.layout.width) + 20.0 + offset

		var route_x: float
		var pure_start_x: float = src_abs.x + edge.source.layout.width * 0.5
		if abs(pure_start_x - left_x) < abs(right_x - pure_start_x):
			route_x = left_x
		else:
			route_x = right_x

		if is_backward:
			var stub: float = 24.0
			edge.sections = [ {
				start_point = start_pt,
				bend_points = [
					Vector2(start_pt.x, start_pt.y + stub),
					Vector2(route_x, start_pt.y + stub),
					Vector2(route_x, end_pt.y - stub),
					Vector2(end_pt.x, end_pt.y - stub)
				],
				end_point = end_pt,
				label_pos = Vector2(route_x, (start_pt.y + end_pt.y) * 0.5)
			}]
		else:
			# forward highway
			var stub_y: float = start_pt.y + 24.0
			var stub_end_y: float = end_pt.y - 24.0
			if stub_end_y < stub_y:
				stub_end_y = stub_y + 8.0
				
			edge.sections = [ {
				start_point = start_pt,
				bend_points = [
					Vector2(start_pt.x, stub_y),
					Vector2(route_x, stub_y),
					Vector2(route_x, stub_end_y),
					Vector2(end_pt.x, stub_end_y)
				],
				end_point = end_pt,
				label_pos = Vector2(route_x, (stub_y + stub_end_y) * 0.5)
			}]
	else:
		# simple forward edge: route via the horizontal gap immediately after the node
		var stub_y: float = start_pt.y + LAYER_GAP * 0.5
		
		# to maintain spacing, bend points should stay straight up/down with the stagger
		edge.sections = [ {
			start_point = start_pt,
			bend_points = [Vector2(start_pt.x, stub_y), Vector2(end_pt.x, stub_y)],
			end_point = end_pt,
			label_pos = Vector2((start_pt.x + end_pt.x) * 0.5, stub_y)
		}]


# walks up both ancestors to find the first common node
static func _find_common_ancestor(
	a: HenStateViewerGraphTypes.DirectedGraphNode,
	b: HenStateViewerGraphTypes.DirectedGraphNode
) -> HenStateViewerGraphTypes.DirectedGraphNode:
	var ancestors: Dictionary = {}
	var current: HenStateViewerGraphTypes.DirectedGraphNode = a
	while current != null:
		ancestors[current.id] = current
		current = current.parent
	current = b
	while current != null:
		if ancestors.has(current.id):
			return current
		current = current.parent
	return null


static func _get_edge_aim_x(edge: HenStateViewerGraphTypes.DirectedGraphEdge, is_out: bool) -> float:
	var src_abs: Vector2 = edge.source.get_absolute()
	var tgt_abs: Vector2 = edge.target.get_absolute()
	var start_x: float = src_abs.x + edge.source.layout.width * 0.5
	var end_x: float = tgt_abs.x + edge.target.layout.width * 0.5
	var start_y: float = src_abs.y + edge.source.layout.height
	var end_y: float = tgt_abs.y

	var is_backward: bool = start_y >= end_y
	var is_complex_forward: bool = false
	if not is_backward:
		var gap_dist: float = end_y - start_y
		if gap_dist > (LAYER_GAP * 1.5 + 30.0):
			is_complex_forward = true

	if is_backward or is_complex_forward:
		var ancestor = _find_common_ancestor(edge.source, edge.target)
		var anc_abs: Vector2 = ancestor.get_absolute() if ancestor != null else Vector2.ZERO
		var anc_w: float = ancestor.layout.width if ancestor != null else 500.0
		
		var h_hash = edge.id.hash()
		if h_hash < 0: h_hash = - h_hash
		var offset: float = (h_hash % 4) * 12.0
		
		var left_x: float = anc_abs.x + 20.0 + offset
		var right_x: float = anc_abs.x + anc_w - 20.0 - offset
		if ancestor == null:
			left_x = min(src_abs.x, tgt_abs.x) - 20.0 - offset
			right_x = max(src_abs.x + edge.source.layout.width, tgt_abs.x + edge.target.layout.width) + 20.0 + offset
			
		if abs(start_x - left_x) < abs(right_x - start_x):
			return left_x
		else:
			return right_x
	else:
		return end_x if is_out else start_x
