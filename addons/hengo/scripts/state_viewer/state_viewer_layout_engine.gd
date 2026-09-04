@tool
class_name HenStateViewerLayoutEngine
extends RefCounted

const LAYER_GAP: float = 96.0
const NODE_GAP: float = 64.0
const COMPOUND_PAD_TOP: float = 128.0
const COMPOUND_PAD_SIDE: float = 96.0
const COMPOUND_PAD_BOTTOM: float = 64.0
const COMPOUND_HEADER_GAP: float = COMPOUND_PAD_BOTTOM
const HIGHWAY_MARGIN: float = 20.0
const HIGHWAY_TRACK_STEP: float = 16.0
const HIGHWAY_STUB: float = 24.0
const COMPLEX_FORWARD_THRESHOLD: float = LAYER_GAP * 1.5 + 30.0
const CHANNEL_MARGIN: float = 32.0
const ROW_TOL: float = 6.0
const COL_TOL: float = 2.0
const ROW_STEP: float = 14.0
const MIN_STUB: float = 8.0
const TRACK_CLEAR: float = 12.0
const MAX_ROW_SHIFT: float = ROW_STEP * 3.0
const TARGET_ASPECT: float = 16.0 / 9.0
# a wider band count only wins if it beats the current one by more than this, so
# one extra state never reshuffles a whole machine
const ASPECT_EPSILON: float = 0.08
const BAND_GAP: float = 128.0
const GUTTER_MARGIN: float = 24.0
const GUTTER_TRACK_STEP: float = 16.0
# wider than LAYER_GAP: the cross-machine channel of the next row lives in here
const ROOT_ROW_GAP: float = 160.0


var _incoming_map: Dictionary = {}
var _outgoing_map: Dictionary = {}
var _highway_tracks: Dictionary = {}
var _root: HenStateViewerGraphTypes.DirectedGraphNode = null
var _machine_order: Array = []
var _machine_index: Dictionary = {}
var _machine_row: Dictionary = {}
var _row_top: Array = []
var _corridor_demand: Array = []

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

	# the corridor route is kept only for what the router cannot see: an edge whose
	# ends live in different machines never has both of them in one scope
	var routed: Dictionary = {}
	var router: HenStateViewerEdgeRouter = HenStateViewerEdgeRouter.new()
	var groups: Dictionary = HenStateViewerEdgeRouter.routable(all_edges)

	for scope: Variant in groups:
		for edge: HenStateViewerGraphTypes.DirectedGraphEdge in router.route_scope(scope, groups[scope]):
			routed[edge] = true

	var remaining: Array = []

	for edge in all_edges:
		if not routed.has(edge):
			remaining.append(edge)

	_separate_parallel_rows(remaining)


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
	if parent == _root:
		_layout_root_row(parent)
		return

	var children: Array = parent.children
	var plan: Dictionary = plan_bands(children)
	var top: float = float(parent.layout.get('top_pad', COMPOUND_PAD_TOP))
	var gutter_bases: Array[float] = []

	for index in range(plan.bands.size()):
		var band: Dictionary = plan.bands[index]
		var current_y: float = top

		for layer in range(band.from, band.to):
			var nodes_in_layer: Array = plan.layers[plan.keys[layer]]
			var layer_total_w: float = 0.0

			for node in nodes_in_layer:
				layer_total_w += node.layout.width

			layer_total_w += max(0, nodes_in_layer.size() - 1) * NODE_GAP

			# center the layer horizontally within its own band
			var current_x: float = COMPOUND_PAD_SIDE + band.x + (band.width - layer_total_w) * 0.5
			var max_h: float = 0.0

			for node in nodes_in_layer:
				node.layout.x = current_x
				node.layout.y = current_y
				node.layout.band = index

				current_x += node.layout.width + NODE_GAP
				max_h = max(max_h, node.layout.height)

			current_y += max_h + LAYER_GAP

		if index < plan.bands.size() - 1:
			gutter_bases.append(COMPOUND_PAD_SIDE + band.x + band.width + GUTTER_MARGIN)

	parent.layout.gutters = gutter_bases

	# resize parent to tightly wrap children
	var max_right: float = 0.0
	var max_bottom: float = 0.0
	for node in children:
		max_right = max(max_right, node.layout.x + node.layout.width)
		max_bottom = max(max_bottom, node.layout.y + node.layout.height)
	parent.layout.width = max(parent.layout.width, max_right + COMPOUND_PAD_SIDE)
	parent.layout.height = max(parent.layout.height, max_bottom + COMPOUND_PAD_BOTTOM)


# lays out top-level machines in a single row, corridors between them sized by cross-edge demand
func _layout_root_row(root: HenStateViewerGraphTypes.DirectedGraphNode) -> void:
	_machine_order.clear()
	_machine_index.clear()
	_corridor_demand.clear()

	var machines: Array = root.children
	if machines.is_empty():
		return

	var machine_map: Dictionary = {}
	var weights: Dictionary = {}
	for m in machines:
		machine_map[m.id] = m
		weights[m.id] = {}

	var cross_pairs: Array = []
	for m in machines:
		var edges_out: Array = []
		_get_all_descendant_edges(m, edges_out)
		for edge in edges_out:
			var tgt_machine: HenStateViewerGraphTypes.DirectedGraphNode = _find_ancestor_in_map(edge.target, machine_map)
			if tgt_machine != null and tgt_machine.id != m.id:
				weights[m.id][tgt_machine.id] = int(weights[m.id].get(tgt_machine.id, 0)) + 1
				weights[tgt_machine.id][m.id] = int(weights[tgt_machine.id].get(m.id, 0)) + 1
				cross_pairs.append({source_id = m.id, target_id = tgt_machine.id})

	# greedy chain: append the unplaced machine most connected to the placed set, ties keep base order
	var placed: Dictionary = {}
	while _machine_order.size() < machines.size():
		var best: HenStateViewerGraphTypes.DirectedGraphNode = null
		var best_w: int = 0
		for m in machines:
			if placed.has(m.id):
				continue
			var w: int = 0
			for other_id in weights[m.id]:
				if placed.has(other_id):
					w += weights[m.id][other_id]
			if best == null or w > best_w:
				best = m
				best_w = w
		placed[best.id] = true
		_machine_order.append(best)

	for i in range(_machine_order.size()):
		_machine_index[_machine_order[i].id] = i

	var rows: Array = _split_machine_rows(weights)

	_machine_row.clear()
	_row_top.clear()

	for r in range(rows.size()):
		for i in range(rows[r].x, rows[r].y):
			_machine_row[_machine_order[i].id] = r

	# a pair split across rows takes the machine-side route, so it books no corridor
	_corridor_demand.resize(maxi(0, machines.size() - 1))
	_corridor_demand.fill(0)
	for pair in cross_pairs:
		var s: int = _machine_index[pair.source_id]
		var t: int = _machine_index[pair.target_id]
		if int(_machine_row.get(pair.source_id, 0)) != int(_machine_row.get(pair.target_id, 0)):
			continue
		if absi(s - t) == 1:
			_corridor_demand[mini(s, t)] += 1
		else:
			_corridor_demand[s if t > s else s - 1] += 1
			_corridor_demand[t - 1 if t > s else t] += 1

	var y: float = COMPOUND_PAD_TOP
	var widest: float = 0.0

	for r in range(rows.size()):
		var x: float = COMPOUND_PAD_SIDE
		var row_h: float = 0.0

		_row_top.append(y)

		for i in range(rows[r].x, rows[r].y):
			var m: HenStateViewerGraphTypes.DirectedGraphNode = _machine_order[i]
			m.layout.x = x
			m.layout.y = y
			row_h = max(row_h, m.layout.height)
			x += m.layout.width
			if i < rows[r].y - 1:
				x += max(NODE_GAP, HIGHWAY_MARGIN * 2.0 + float(_corridor_demand[i]) * HIGHWAY_TRACK_STEP)

		widest = max(widest, x)
		y += row_h + ROOT_ROW_GAP

	root.layout.width = widest + COMPOUND_PAD_SIDE
	root.layout.height = y - ROOT_ROW_GAP + COMPOUND_PAD_BOTTOM


# the machine chain wrapped into rows, same aspect rule the bands inside use. the
# corridor router works along one row, so a row is only cut where no transition
# crosses: the greedy chain leaves each connected group contiguous
func _split_machine_rows(weights: Dictionary) -> Array:
	var widths: Array[float] = []
	var heights: Array[float] = []

	for m in _machine_order:
		widths.append(m.layout.width)
		heights.append(m.layout.height)

	var groups: Array[int] = _connected_groups(weights)
	var allowed_cuts: Dictionary = {}

	for i in range(_machine_order.size() - 1):
		if groups[i] != groups[i + 1]:
			allowed_cuts[i] = true

	var chosen: Array = [Vector2i(0, _machine_order.size())]
	var chosen_deviation: float = INF

	for count in range(1, _machine_order.size() + 1):
		var split: Array = _split_runs(widths, count, NODE_GAP, allowed_cuts)
		var deviation: float = _aspect_deviation(_rows_shape(split, widths, heights))

		if deviation < chosen_deviation - ASPECT_EPSILON:
			chosen_deviation = deviation
			chosen = split

	return chosen


# the connected component of each machine, indexed by its place in _machine_order
func _connected_groups(weights: Dictionary) -> Array[int]:
	var groups: Array[int] = []

	groups.resize(_machine_order.size())
	groups.fill(-1)

	var next_group: int = 0

	for i in range(_machine_order.size()):
		if groups[i] != -1:
			continue

		var pending: Array = [i]
		groups[i] = next_group

		while not pending.is_empty():
			var current: int = pending.pop_back()

			for other_id in weights.get(_machine_order[current].id, {}):
				var index: int = int(_machine_index.get(other_id, -1))

				if index >= 0 and groups[index] == -1:
					groups[index] = next_group
					pending.append(index)

		next_group += 1

	return groups


static func _rows_shape(split: Array, widths: Array[float], heights: Array[float]) -> Vector2:
	var widest: float = 0.0
	var total_h: float = 0.0

	for row in split:
		var row_w: float = 0.0
		var row_h: float = 0.0

		for i in range(row.x, row.y):
			row_w += widths[i]
			row_h = max(row_h, heights[i])

		widest = max(widest, row_w + float(row.y - row.x - 1) * NODE_GAP)
		total_h += row_h

	return Vector2(widest, total_h + float(split.size() - 1) * ROOT_ROW_GAP)


# corridor i sits between machines i and i+1; base x clears the left machine by the margin
func _corridor_base_x(corridor: int) -> float:
	if corridor < 0 or corridor >= _machine_order.size():
		return 0.0
	var m: HenStateViewerGraphTypes.DirectedGraphNode = _machine_order[corridor]
	return m.get_absolute().x + m.layout.width + HIGHWAY_MARGIN


# the layer sequence cut into contiguous bands laid side by side. a machine that
# is one long chain fills the width instead of stretching down, and one band is
# the old single-column layout. the measurer and the layout engine both call this,
# so it stays a pure function of children that are already sized
static func plan_bands(children: Array) -> Dictionary:
	var layers: Dictionary = group_by_depth(children)
	var keys: Array = layers.keys()
	keys.sort()

	var widths: Array[float] = []
	var heights: Array[float] = []

	for key: Variant in keys:
		var nodes: Array = layers[key]
		var width: float = 0.0
		var height: float = 0.0

		for node in nodes:
			width += node.layout.width
			height = max(height, node.layout.height)

		widths.append(width + float(nodes.size() - 1) * NODE_GAP)
		heights.append(height)

	var chosen: Array = [Vector2i(0, keys.size())]
	var chosen_deviation: float = INF

	for count in range(1, keys.size() + 1):
		var split: Array = _split_runs(heights, count, LAYER_GAP)
		var deviation: float = _aspect_deviation(_bands_shape(split, widths, heights))

		if deviation < chosen_deviation - ASPECT_EPSILON:
			chosen_deviation = deviation
			chosen = split

	var band_of: Dictionary = {}

	for index in range(chosen.size()):
		for layer in range(chosen[index].x, chosen[index].y):
			band_of[keys[layer]] = index

	var gutters: Array[float] = _gutter_widths(children, layers, band_of, chosen.size())
	var bands: Array = []
	var x: float = 0.0
	var tallest: float = 0.0

	for index in range(chosen.size()):
		var band_w: float = 0.0
		var band_h: float = 0.0

		for layer in range(chosen[index].x, chosen[index].y):
			band_w = max(band_w, widths[layer])
			band_h += heights[layer]

		band_h += float(chosen[index].y - chosen[index].x - 1) * LAYER_GAP
		bands.append({from = chosen[index].x, to = chosen[index].y, x = x, width = band_w, height = band_h})
		tallest = max(tallest, band_h)
		x += band_w

		if index < chosen.size() - 1:
			x += gutters[index]

	return {
		layers = layers,
		keys = keys,
		bands = bands,
		band_of = band_of,
		gutters = gutters,
		content = Vector2(x, tallest)
	}


# contiguous runs of roughly equal extent, so no run ends up carrying the machine
static func _split_runs(values: Array[float], count: int, gap: float, allowed_cuts: Variant = null) -> Array:
	var total: float = 0.0

	for value in values:
		total += value + gap

	var target: float = total / float(count)
	var out: Array = []
	var start: int = 0
	var accumulated: float = 0.0

	for i in range(values.size()):
		accumulated += values[i] + gap

		var left_items: int = values.size() - i - 1
		var left_runs: int = count - out.size() - 1
		var can_cut: bool = allowed_cuts == null or (allowed_cuts as Dictionary).has(i)

		if can_cut and out.size() < count - 1 and accumulated >= target and left_items >= left_runs:
			out.append(Vector2i(start, i + 1))
			start = i + 1
			accumulated = 0.0

	out.append(Vector2i(start, values.size()))

	return out


static func _bands_shape(split: Array, widths: Array[float], heights: Array[float]) -> Vector2:
	var width: float = 0.0
	var tallest: float = 0.0

	for band in split:
		var band_w: float = 0.0
		var band_h: float = 0.0

		for layer in range(band.x, band.y):
			band_w = max(band_w, widths[layer])
			band_h += heights[layer]

		width += band_w
		tallest = max(tallest, band_h + float(band.y - band.x - 1) * LAYER_GAP)

	return Vector2(width + float(split.size() - 1) * BAND_GAP, tallest)


static func _aspect_deviation(shape: Vector2) -> float:
	return absf(log(max(shape.x / max(shape.y, 1.0), 0.001) / TARGET_ASPECT))


# only adjacent crossings ride a gutter, so only they reserve width in one
static func _gutter_widths(children: Array, layers: Dictionary, band_of: Dictionary, count: int) -> Array[float]:
	var out: Array[float] = []

	out.resize(maxi(0, count - 1))
	out.fill(BAND_GAP)

	if count < 2:
		return out

	var node_band: Dictionary = {}
	var node_map: Dictionary = {}

	for key in layers:
		for node in layers[key]:
			node_band[node.id] = int(band_of[key])
			node_map[node.id] = node

	var demand: Array[int] = []

	demand.resize(count - 1)
	demand.fill(0)

	for node in children:
		var edges_out: Array = []
		_get_all_descendant_edges(node, edges_out)

		for edge in edges_out:
			var target: HenStateViewerGraphTypes.DirectedGraphNode = _find_ancestor_in_map(edge.target, node_map)

			if target == null or target.id == node.id:
				continue

			var source_band: int = int(node_band.get(node.id, 0))
			var target_band: int = int(node_band.get(target.id, 0))

			if absi(source_band - target_band) != 1:
				continue

			demand[mini(source_band, target_band)] += 1

	for index in range(count - 1):
		out[index] = max(BAND_GAP, GUTTER_MARGIN * 2.0 + float(demand[index]) * GUTTER_TRACK_STEP)

	return out


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

	# stamp the visual kind so the overlay can color edges by type
	if info.is_cross:
		edge.kind = &'cross'
	elif info.get('band_forward', false):
		# the machine's own sequence, only bent because the band wrapped
		edge.kind = &'forward'
	elif info.is_backward:
		edge.kind = &'back'
	else:
		edge.kind = &'forward'

	# apply parallel-edge spread (horizontal) to the source/target anchors
	var src_offset: float = _spread_offset(_outgoing_map[edge.source.id], edge, edge.source.layout.width)
	var tgt_offset: float = _spread_offset(_incoming_map[edge.target.id], edge, edge.target.layout.width)

	var start_pt: Vector2 = Vector2(info.start.x + src_offset, info.start.y)
	var end_pt: Vector2 = Vector2(info.end.x + tgt_offset, info.end.y)

	if info.is_highway:
		if info.is_cross and info.has('exit_corridor'):
			_route_cross_edge(edge, info, start_pt, end_pt)
			return

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


# routes a cross-machine edge through corridor tracks, arcing over the top channel when machines are not adjacent
func _route_cross_edge(edge: HenStateViewerGraphTypes.DirectedGraphEdge, info: Dictionary, start_pt: Vector2, end_pt: Vector2) -> void:
	var exit_track: Dictionary = _highway_tracks.get(edge.id + ':exit', {index = 0, count = 1})
	var exit_x: float = info.route_base + float(exit_track.index) * HIGHWAY_TRACK_STEP
	var seg_top: float = start_pt.y + HIGHWAY_STUB
	var seg_bottom: float = end_pt.y - HIGHWAY_STUB

	if info.is_adjacent:
		edge.sections = [ {
			start_point = start_pt,
			bend_points = [
				Vector2(start_pt.x, seg_top),
				Vector2(exit_x, seg_top),
				Vector2(exit_x, seg_bottom),
				Vector2(end_pt.x, seg_bottom)
			],
			end_point = end_pt,
			label_pos = Vector2(exit_x, _track_label_y(seg_top, seg_bottom, exit_track))
		}]
		return

	var entry_track: Dictionary = _highway_tracks.get(edge.id + ':entry', {index = 0, count = 1})
	var chan_track: Dictionary = _highway_tracks.get(edge.id + ':chan', {index = 0, count = 1})
	var entry_x: float = info.entry_base + float(entry_track.index) * HIGHWAY_TRACK_STEP
	var row_top: float = float(info.get('row_top', COMPOUND_PAD_TOP))
	# the tracks compress instead of climbing into the row above
	var span: float = max(0.0, float(info.get('row_head', COMPOUND_PAD_TOP)) - CHANNEL_MARGIN - TRACK_CLEAR)
	var step: float = min(HIGHWAY_TRACK_STEP, span / max(1.0, float(chan_track.count)))
	var channel_y: float = row_top - CHANNEL_MARGIN - float(chan_track.index) * step

	edge.sections = [ {
		start_point = start_pt,
		bend_points = [
			Vector2(start_pt.x, seg_top),
			Vector2(exit_x, seg_top),
			Vector2(exit_x, channel_y),
			Vector2(entry_x, channel_y),
			Vector2(entry_x, seg_bottom),
			Vector2(end_pt.x, seg_bottom)
		],
		end_point = end_pt,
		label_pos = Vector2((exit_x + entry_x) * 0.5, channel_y)
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
		if info.is_cross and info.has('entry_base') and not is_out:
			return info.entry_base
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

	var ancestor: HenStateViewerGraphTypes.DirectedGraphNode = _find_common_ancestor(edge.source, edge.target)
	var is_cross: bool = ancestor == null or ancestor == _root
	var band: Dictionary = {} if is_cross else _band_crossing(ancestor, edge)

	var info: Dictionary = {
		start = Vector2(start_x, start_y),
		end = Vector2(end_x, end_y),
		is_highway = is_backward or is_complex_forward or is_cross or not band.is_empty(),
		is_backward = is_backward,
		is_cross = is_cross,
		is_band = not band.is_empty(),
		band_forward = bool(band.get('forward', false)),
		route_base = 0.0,
		track_dir = 1.0,
		group_key = ''
	}

	if not info.is_highway:
		return info

	if not band.is_empty():
		info.route_base = band.base
		info.track_dir = 1.0
		info.group_key = band.key
		return info

	if is_cross:
		var src_machine: HenStateViewerGraphTypes.DirectedGraphNode = _top_level_machine(edge.source)
		var tgt_machine: HenStateViewerGraphTypes.DirectedGraphNode = _top_level_machine(edge.target)
		var s_idx: int = int(_machine_index.get(src_machine.id, -1)) if src_machine != null else -1
		var t_idx: int = int(_machine_index.get(tgt_machine.id, -1)) if tgt_machine != null else -1

		var s_row: int = int(_machine_row.get(src_machine.id, 0)) if src_machine != null else 0
		var t_row: int = int(_machine_row.get(tgt_machine.id, 0)) if tgt_machine != null else 0

		if s_idx >= 0 and t_idx >= 0 and s_idx != t_idx and s_row == t_row:
			# corridor routing against the machine row built by _layout_root_row
			info.src_index = s_idx
			info.row_top = float(_row_top[s_row]) if s_row < _row_top.size() else COMPOUND_PAD_TOP
			info.row_head = COMPOUND_PAD_TOP if s_row == 0 else ROOT_ROW_GAP
			info.row = s_row
			info.is_adjacent = absi(s_idx - t_idx) == 1
			info.exit_corridor = s_idx if t_idx > s_idx else s_idx - 1
			info.entry_corridor = t_idx - 1 if t_idx > s_idx else t_idx
			info.route_base = _corridor_base_x(info.exit_corridor)
			info.entry_base = info.route_base if info.is_adjacent else _corridor_base_x(info.entry_corridor)
			info.track_dir = 1.0
			info.group_key = 'corridor:' + str(info.exit_corridor)
			return info

		# fallback: machine-side routing when the row has no index for these machines
		var ref_abs: Vector2 = src_machine.get_absolute() if src_machine != null else src_abs
		var ref_w: float = src_machine.layout.width if src_machine != null else edge.source.layout.width
		var machine_id: String = src_machine.id if src_machine != null else edge.source.id

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


# the gutter an edge between two neighbouring bands runs in. a jump over more than
# one band would have to cross a band to reach its gutter, so it keeps the old
# route around the outside of the machine
func _band_crossing(
	ancestor: HenStateViewerGraphTypes.DirectedGraphNode,
	edge: HenStateViewerGraphTypes.DirectedGraphEdge
) -> Dictionary:
	var gutters: Array = ancestor.layout.get('gutters', [])

	if gutters.is_empty():
		return {}

	var source: HenStateViewerGraphTypes.DirectedGraphNode = _child_of(ancestor, edge.source)
	var target: HenStateViewerGraphTypes.DirectedGraphNode = _child_of(ancestor, edge.target)

	if source == null or target == null:
		return {}

	var source_band: int = int(source.layout.get('band', 0))
	var target_band: int = int(target.layout.get('band', 0))

	if absi(source_band - target_band) != 1:
		return {}

	var index: int = mini(source_band, target_band)

	if index >= gutters.size():
		return {}

	return {
		base = ancestor.get_absolute().x + float(gutters[index]),
		key = 'gutter:' + ancestor.id + ':' + str(index),
		forward = target_band > source_band
	}


# walks up from node to the direct child of ancestor that contains it
static func _child_of(
	ancestor: HenStateViewerGraphTypes.DirectedGraphNode,
	node: HenStateViewerGraphTypes.DirectedGraphNode
) -> HenStateViewerGraphTypes.DirectedGraphNode:
	var current: HenStateViewerGraphTypes.DirectedGraphNode = node

	while current != null and current.parent != ancestor:
		current = current.parent

	return current


# walks up to the ancestor whose parent is the root (the top-level machine containing node)
func _top_level_machine(node: HenStateViewerGraphTypes.DirectedGraphNode) -> HenStateViewerGraphTypes.DirectedGraphNode:
	var current: HenStateViewerGraphTypes.DirectedGraphNode = node
	while current != null and current.parent != null and current.parent != _root:
		current = current.parent
	return current


# groups highway edges by machine side, corridor or channel and assigns each a distinct, spatially-ordered track
func _allocate_highway_tracks(all_edges: Array) -> void:
	_highway_tracks.clear()
	var groups: Dictionary = {}
	for e in all_edges:
		var info: Dictionary = _classify_edge(e)
		if not info.is_highway:
			continue

		var m_idx: int = int(info.get('src_index', -1))
		if info.is_cross and info.has('exit_corridor'):
			# cross edges hold one track per corridor they traverse, plus one in the top channel
			_push_track(groups, 'corridor:' + str(info.exit_corridor), e.id + ':exit', m_idx, info.start.x, e.id)
			if not info.is_adjacent:
				_push_track(groups, 'corridor:' + str(info.entry_corridor), e.id + ':entry', m_idx, info.start.x, e.id)
				_push_track(groups, 'channel:' + str(info.get('row', 0)), e.id + ':chan', m_idx, info.start.x, e.id)
		else:
			_push_track(groups, info.group_key, e.id, m_idx, info.start.x, e.id)

	for key in groups:
		var arr: Array = groups[key]
		arr.sort_custom(func(a, b):
			if a.machine != b.machine:
				return a.machine < b.machine
			if a.sort_x != b.sort_x:
				return a.sort_x < b.sort_x
			return a.edge_id < b.edge_id
		)
		var count: int = arr.size()
		for i in range(count):
			_highway_tracks[arr[i].key] = {index = i, count = count}


func _push_track(groups: Dictionary, group_key: String, track_key: String, machine: int, sort_x: float, edge_id: String) -> void:
	if not groups.has(group_key):
		groups[group_key] = []
	groups[group_key].append({key = track_key, machine = machine, sort_x = sort_x, edge_id = edge_id})


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


# phase 2.5: fans out coincident parallel runs so edges sharing a path never overlap
func _separate_parallel_rows(all_edges: Array) -> void:
	_separate_axis_runs(all_edges, 1, ROW_TOL)
	_separate_axis_runs(all_edges, 0, COL_TOL)


# pos_axis 1 separates horizontal rows (moves y), pos_axis 0 separates vertical columns (moves x)
func _separate_axis_runs(all_edges: Array, pos_axis: int, tol: float) -> void:
	var span_axis: int = 1 - pos_axis
	var segments: Array = []

	for edge in all_edges:
		for section in edge.sections:
			var pts: Array = [section.start_point]
			pts.append_array(section.bend_points)
			pts.append(section.end_point)

			# only interior segments move: both endpoints must be bend points
			for i in range(1, pts.size() - 2):
				var a: Vector2 = pts[i]
				var b: Vector2 = pts[i + 1]
				if absf(a[pos_axis] - b[pos_axis]) >= 0.01 or absf(a[span_axis] - b[span_axis]) <= 1.0:
					continue

				var pos: float = a[pos_axis]
				var lo: float = pos - MAX_ROW_SHIFT
				var hi: float = pos + MAX_ROW_SHIFT
				var prev: float = pts[i - 1][pos_axis]
				var next: float = pts[i + 2][pos_axis]
				if prev < pos - 0.01:
					lo = max(lo, prev + MIN_STUB)
				elif prev > pos + 0.01:
					hi = min(hi, prev - MIN_STUB)
				if next < pos - 0.01:
					lo = max(lo, next + MIN_STUB)
				elif next > pos + 0.01:
					hi = min(hi, next - MIN_STUB)

				segments.append({
					edge = edge,
					section = section,
					bend_a = i - 1,
					bend_b = i,
					pos = pos,
					s0 = minf(a[span_axis], b[span_axis]),
					s1 = maxf(a[span_axis], b[span_axis]),
					lo = lo,
					hi = hi
				})

	segments.sort_custom(func(a, b):
		if a.pos != b.pos:
			return a.pos < b.pos
		if a.s0 != b.s0:
			return a.s0 < b.s0
		return a.edge.id < b.edge.id
	)

	# anchor-based sweep so near-equal rows group without chain drift
	var band: Array = []
	var anchor: float = 0.0
	for seg in segments:
		if band.is_empty() or seg.pos - anchor <= tol:
			if band.is_empty():
				anchor = seg.pos
			band.append(seg)
		else:
			_fan_out_band(band, anchor, pos_axis)
			band = [seg]
			anchor = seg.pos
	if not band.is_empty():
		_fan_out_band(band, anchor, pos_axis)


# assigns overlapping segments of a band to distinct tracks and writes the fanned positions back
func _fan_out_band(band: Array, anchor: float, pos_axis: int) -> void:
	if band.size() < 2:
		return

	band.sort_custom(func(a, b):
		if a.s0 != b.s0:
			return a.s0 < b.s0
		return a.edge.id < b.edge.id
	)

	# greedy interval coloring: reuse the first track with enough clearance, else open a new one
	var track_ends: Array = []
	for seg in band:
		var assigned: int = -1
		for t in range(track_ends.size()):
			if track_ends[t] + TRACK_CLEAR <= seg.s0:
				assigned = t
				break
		if assigned == -1:
			assigned = track_ends.size()
			track_ends.append(seg.s1)
		else:
			track_ends[assigned] = seg.s1
		seg.track = assigned

	var track_count: int = track_ends.size()
	if track_count < 2:
		return

	var lo: float = -INF
	var hi: float = INF
	for seg in band:
		lo = max(lo, seg.lo)
		hi = min(hi, seg.hi)
	if lo > hi:
		return

	var step: float = ROW_STEP
	var span: float = float(track_count - 1) * step
	var base: float = anchor
	if span <= hi - lo:
		base = clampf(anchor - span * 0.5, lo, hi - span)
	else:
		base = lo
		step = (hi - lo) / float(track_count - 1)

	for seg in band:
		_shift_segment(seg, base + float(seg.track) * step, pos_axis)


# moves both bend points of the segment and drags a label riding it along
func _shift_segment(seg: Dictionary, new_pos: float, pos_axis: int) -> void:
	if absf(new_pos - seg.pos) < 0.01:
		return

	var section: Dictionary = seg.section
	var bends: Array = section.bend_points
	for b in [seg.bend_a, seg.bend_b]:
		var p: Vector2 = bends[b]
		p[pos_axis] = new_pos
		bends[b] = p

	if section.has('label_pos'):
		var label_pos: Vector2 = section.label_pos
		var on_run: bool = absf(label_pos[pos_axis] - seg.pos) < 0.5
		var in_span: bool = label_pos[1 - pos_axis] >= seg.s0 - 1.0 and label_pos[1 - pos_axis] <= seg.s1 + 1.0
		if on_run and in_span:
			label_pos[pos_axis] = new_pos
			section.label_pos = label_pos
