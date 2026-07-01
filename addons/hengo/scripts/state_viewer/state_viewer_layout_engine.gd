@tool
class_name HenStateViewerLayoutEngine
extends RefCounted

const LAYER_GAP: float = 96.0
const NODE_GAP: float = 64.0
const COMPOUND_PAD_TOP: float = 128.0
const COMPOUND_PAD_SIDE: float = 96.0
const COMPOUND_PAD_BOTTOM: float = 64.0
const HIGHWAY_MARGIN: float = 20.0
const HIGHWAY_TRACK_STEP: float = 16.0
const HIGHWAY_STUB: float = 24.0
const COMPLEX_FORWARD_THRESHOLD: float = LAYER_GAP * 1.5 + 30.0


var _incoming_map: Dictionary = {}
var _outgoing_map: Dictionary = {}
var _highway_tracks: Dictionary = {}
var _root: HenStateViewerGraphTypes.DirectedGraphNode = null

# phase 1: layout all positions bottom-up, phase 2: route edges after positions are final
func execute_layout(root: HenStateViewerGraphTypes.DirectedGraphNode) -> void:
	_root = root
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

	_allocate_highway_tracks(all_edges)
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


# orthogonal routing: forward edges use s-curve, backward/complex edges route on allocated highway tracks
func _route_edge(edge: HenStateViewerGraphTypes.DirectedGraphEdge) -> void:
	var info: Dictionary = _classify_edge(edge)

	# apply parallel-edge spread (horizontal) to the source/target anchors
	var src_offset: float = _spread_offset(_outgoing_map[edge.source.id], edge, edge.source.layout.width)
	var tgt_offset: float = _spread_offset(_incoming_map[edge.target.id], edge, edge.target.layout.width)

	var start_pt: Vector2 = Vector2(info.start.x + src_offset, info.start.y)
	var end_pt: Vector2 = Vector2(info.end.x + tgt_offset, info.end.y)

	if info.is_highway:
		var track: Dictionary = _highway_tracks.get(edge.id, {index = 0, count = 1})
		var route_x: float = info.route_base + info.track_dir * float(track.index) * HIGHWAY_TRACK_STEP

		var seg_top: float = start_pt.y + HIGHWAY_STUB
		var seg_bottom: float = end_pt.y - HIGHWAY_STUB
		if not info.is_backward and seg_bottom < seg_top:
			seg_bottom = seg_top + 8.0

		edge.sections = [ {
			start_point = start_pt,
			bend_points = [
				Vector2(start_pt.x, seg_top),
				Vector2(route_x, seg_top),
				Vector2(route_x, seg_bottom),
				Vector2(end_pt.x, seg_bottom)
			],
			end_point = end_pt,
			label_pos = Vector2(route_x, _track_label_y(seg_top, seg_bottom, track))
		}]
	else:
		# simple forward edge: route via the horizontal gap immediately after the node
		var stub_y: float = start_pt.y + LAYER_GAP * 0.5
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


# edge ordering uses the same classification as routing, so sort and render never diverge
func _get_edge_aim_x(edge: HenStateViewerGraphTypes.DirectedGraphEdge, is_out: bool) -> float:
	var info: Dictionary = _classify_edge(edge)
	if info.is_highway:
		return info.route_base
	return info.end.x if is_out else info.start.x


# shared routing geometry computed from pure node centers (independent of spread and track index)
func _classify_edge(edge: HenStateViewerGraphTypes.DirectedGraphEdge) -> Dictionary:
	var src_abs: Vector2 = edge.source.get_absolute()
	var tgt_abs: Vector2 = edge.target.get_absolute()
	var start_x: float = src_abs.x + edge.source.layout.width * 0.5
	var end_x: float = tgt_abs.x + edge.target.layout.width * 0.5
	var start_y: float = src_abs.y + edge.source.layout.height
	var end_y: float = tgt_abs.y

	var is_backward: bool = start_y >= end_y
	var is_complex_forward: bool = (not is_backward) and (end_y - start_y) > COMPLEX_FORWARD_THRESHOLD

	var info: Dictionary = {
		start = Vector2(start_x, start_y),
		end = Vector2(end_x, end_y),
		is_highway = is_backward or is_complex_forward,
		is_backward = is_backward,
		route_base = 0.0,
		track_dir = 1.0,
		group_key = ''
	}

	if not info.is_highway:
		return info

	var ancestor: HenStateViewerGraphTypes.DirectedGraphNode = _find_common_ancestor(edge.source, edge.target)
	var is_cross: bool = ancestor == null or ancestor == _root

	if is_cross:
		# cross-machine: route just outside the source machine, on the side facing the target
		var src_machine: HenStateViewerGraphTypes.DirectedGraphNode = _top_level_machine(edge.source)
		var ref_abs: Vector2 = src_machine.get_absolute() if src_machine != null else src_abs
		var ref_w: float = src_machine.layout.width if src_machine != null else edge.source.layout.width
		var machine_id: String = src_machine.id if src_machine != null else edge.source.id

		var tgt_machine: HenStateViewerGraphTypes.DirectedGraphNode = _top_level_machine(edge.target)
		var tgt_center: float = end_x
		if tgt_machine != null:
			tgt_center = tgt_machine.get_absolute().x + tgt_machine.layout.width * 0.5

		if tgt_center >= ref_abs.x + ref_w * 0.5:
			info.route_base = ref_abs.x + ref_w + HIGHWAY_MARGIN
			info.track_dir = 1.0
			info.group_key = 'x:' + machine_id + ':R'
		else:
			info.route_base = ref_abs.x - HIGHWAY_MARGIN
			info.track_dir = -1.0
			info.group_key = 'x:' + machine_id + ':L'
	else:
		# same-machine highway: route inside the common ancestor's padding, on the nearest side
		var anc_abs: Vector2 = ancestor.get_absolute()
		var anc_w: float = ancestor.layout.width
		var left_base: float = anc_abs.x + HIGHWAY_MARGIN
		var right_base: float = anc_abs.x + anc_w - HIGHWAY_MARGIN
		if abs(start_x - left_base) < abs(right_base - start_x):
			info.route_base = left_base
			info.track_dir = 1.0
			info.group_key = ancestor.id + ':L'
		else:
			info.route_base = right_base
			info.track_dir = -1.0
			info.group_key = ancestor.id + ':R'

	return info


# walks up to the ancestor whose parent is the root (the top-level machine containing node)
func _top_level_machine(node: HenStateViewerGraphTypes.DirectedGraphNode) -> HenStateViewerGraphTypes.DirectedGraphNode:
	var current: HenStateViewerGraphTypes.DirectedGraphNode = node
	while current != null and current.parent != null and current.parent != _root:
		current = current.parent
	return current


# groups highway edges by (ancestor/machine, side) and assigns each a distinct, spatially-ordered track
func _allocate_highway_tracks(all_edges: Array) -> void:
	_highway_tracks.clear()
	var groups: Dictionary = {}
	for e in all_edges:
		var info: Dictionary = _classify_edge(e)
		if not info.is_highway:
			continue
		if not groups.has(info.group_key):
			groups[info.group_key] = []
		groups[info.group_key].append({edge = e, sort_x = info.start.x})

	for key in groups:
		var arr: Array = groups[key]
		arr.sort_custom(func(a, b):
			if a.sort_x == b.sort_x:
				return a.edge.id < b.edge.id
			return a.sort_x < b.sort_x
		)
		var count: int = arr.size()
		for i in range(count):
			_highway_tracks[arr[i].edge.id] = {index = i, count = count}


# symmetric horizontal offset so parallel edges fan out across 70% of the node width
func _spread_offset(edges: Array, edge: HenStateViewerGraphTypes.DirectedGraphEdge, node_w: float) -> float:
	var count: int = edges.size()
	if count <= 1:
		return 0.0
	var idx: int = edges.find(edge)
	var spread: float = node_w * 0.7
	var step: float = spread / max(1, count - 1)
	return (idx * step) - (spread * 0.5)


# distributes labels along the vertical run so tracks in the same group don't stack at one height
func _track_label_y(seg_top: float, seg_bottom: float, track: Dictionary) -> float:
	var t: float = float(track.index + 1) / float(track.count + 1)
	return lerpf(seg_top, seg_bottom, t)
