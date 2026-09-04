@tool
class_name HenFlowFormatter
extends RefCounted

# port of HenFormatter onto the derived flow graph. same shape: execution goes
# down, a fan of outputs opens to both sides of the parent, and data producers
# stack to the left of whoever consumes them.
# the original stays untouched for the cnode canvas

const Y_GAP: float = 36.0
const FIRST_LEVEL_Y_GAP: float = 64.0
const INPUT_X_GAP: float = 32.0
const INPUT_Y_GAP: float = 12.0
const MIDDLE_X_GAP: float = 90.0
# the run carries on below the branch row of the fan, not beside it
const MIDDLE_Y_GAP: float = 25.0
# breathing room around a loop's nested chain, drawn as a frame inside the node
const BODY_PAD: float = 16.0

# a run shorter than this reads fine as one column
const WRAP_MIN_STEPS: int = 4
const MAX_COLUMNS: int = 5
const COLUMN_GAP: float = 60.0
const WRAP_ASPECT: float = 16.0 / 9.0
# a wider split only wins by a margin, so one more action never reshuffles the state
const WRAP_EPSILON: float = 0.08


class NodeFormat extends RefCounted:
	var moved: bool = false
	var input_owner: StringName = &''
	var tree_children: Array[HenFlowGraphTypes.FlowNode] = []


class FormatData extends RefCounted:
	var y_limit: float = 0.0
	var map: Dictionary = {}
	# "<node id>|<pin>" -> target node
	var exec_to: Dictionary = {}
	var data_from: Dictionary = {}
	# node id -> the nodes it feeds
	var consumers: Dictionary = {}


	func format_of(_id: StringName) -> NodeFormat:
		if not map.has(_id):
			map[_id] = NodeFormat.new()

		return map[_id]


static func _key(_id: StringName, _pin: StringName) -> String:
	return str(_id) + '|' + str(_pin)


# positions every node of the graph and returns the bounding it occupies. node
# sizes must already be measured: layout never asks the renderer anything
static func format(_graph: HenFlowGraphTypes.FlowGraph) -> Rect2:
	if not _graph or not _graph.entry:
		return Rect2()

	_layout_bodies(_graph)

	var data: FormatData = _index(_graph)
	var entry_format: NodeFormat = data.format_of(_graph.entry.id)

	entry_format.moved = true
	_graph.entry.position = Vector2.ZERO

	_start_format(_graph.entry, data)

	_place_bodies(_graph)

	if wrap_enabled():
		_wrap_chains(_graph, data)

	return _bounding_of(_graph.nodes)


# a long run is cut into columns to keep the state readable; turning it off drops
# the run straight down, which is what a reader following the sequence expects
static func wrap_enabled() -> bool:
	return bool(ProjectSettings.get_setting(HenSettings.FLOW_WRAP_PATH, true))


# --- chain wrapping ---

# a run of actions goes straight down, which turns a state into a ribbon: eight
# in a row measured 220 x 1703. this cuts the run into columns after the fact, so
# the recursive pass above keeps its own guarantees and only whole steps move
static func _wrap_chains(_graph: HenFlowGraphTypes.FlowGraph, _data: FormatData) -> void:
	var chains: Array = []
	var claimed: Dictionary = {_graph.entry.id: true}

	for pin: HenFlowGraphTypes.FlowPin in _graph.entry.pins_of(&'exec_out'):
		var chain: Array = _chain_from(_graph.entry, pin.id, _data)
		var steps: Array = []

		for node: HenFlowGraphTypes.FlowNode in chain:
			var owned: Array[HenFlowGraphTypes.FlowNode] = _step_closure(_graph, _data, node)

			for member: HenFlowGraphTypes.FlowNode in owned:
				# a node moved by two steps would be dragged twice
				if claimed.has(member.id):
					return

				claimed[member.id] = true

			steps.append({card = node, nodes = owned, box = _bounding_of(owned)})

		if not steps.is_empty():
			chains.append(steps)

	# a node nobody claimed would stay behind while its neighbours move, so the
	# whole thing is left alone rather than half applied
	if claimed.size() != _graph.nodes.size() or chains.is_empty():
		return

	var lanes: Array = []

	for steps: Array in chains:
		lanes.append(_wrap_chain(steps) if steps.size() >= WRAP_MIN_STEPS else [])

	_spread_chains(chains, lanes)

	for chain_lanes: Array in lanes:
		_graph.lanes.append_array(chain_lanes)

	# measured after everything settled, so a moved chain carries its own strips
	for steps: Array in chains:
		for step: Dictionary in steps:
			var box: Rect2 = _bounding_of(step.nodes)

			_graph.bands.append(box.position.y + box.size.y + Y_GAP * 0.5)

	_graph.bands.sort()

	_center_entry(_graph, chains)


# the chains were spread after the fan placed them around the entry, so the entry
# follows to sit over the span of the heads it feeds
static func _center_entry(_graph: HenFlowGraphTypes.FlowGraph, _chains: Array) -> void:
	var low: float = INF
	var high: float = -INF

	for steps: Array in _chains:
		var centre: float = _card_centre(steps[0])

		low = minf(low, centre)
		high = maxf(high, centre)

	if low > high:
		return

	_graph.entry.position.x = (low + high) * 0.5 - _graph.entry.size.x * 0.5


# one phase growing sideways would walk into the next one, so after the columns
# are chosen the chains are laid out side by side again
static func _spread_chains(_chains: Array, _lanes: Array) -> void:
	var boxes: Array[Rect2] = []
	var x: float = INF

	for steps: Array in _chains:
		var box: Rect2 = _bounding_of(_chain_nodes(steps))

		boxes.append(box)
		x = minf(x, box.position.x)

	for i: int in range(_chains.size()):
		var offset: float = x - boxes[i].position.x

		if not is_zero_approx(offset):
			for node: HenFlowGraphTypes.FlowNode in _chain_nodes(_chains[i]):
				node.position.x += offset

			for lane: Dictionary in _lanes[i]:
				lane.x += offset

		x += boxes[i].size.x + MIDDLE_X_GAP


static func _chain_nodes(_steps: Array) -> Array:
	var out: Array = []

	for step: Dictionary in _steps:
		out.append_array(step.nodes)

	return out


# returns the lane between each pair of columns: the wire that jumps from the foot
# of one to the head of the next has no other way through
static func _wrap_chain(_steps: Array) -> Array:
	var origin: Vector2 = (_steps[0].box as Rect2).position
	var columns: Array = _choose_columns(_steps)
	var lanes: Array = []
	var x: float = origin.x

	for index: int in range(columns.size()):
		var column: Vector2i = columns[index]
		var left: float = 0.0
		var right: float = 0.0
		var y: float = origin.y

		for i: int in range(column.x, column.y):
			var box: Rect2 = _steps[i].box
			var centre: float = _card_centre(_steps[i])

			left = maxf(left, centre - box.position.x)
			right = maxf(right, box.position.x + box.size.x - centre)

		for i: int in range(column.x, column.y):
			var box: Rect2 = _steps[i].box
			# aligned on the card centre, not the box centre: the satellites hang
			# wider on one side and a box-centred step bends the exec spine
			var offset: Vector2 = Vector2(x + left - _card_centre(_steps[i]), y - box.position.y)

			for node: HenFlowGraphTypes.FlowNode in _steps[i].nodes:
				node.position += offset

			y += box.size.y + Y_GAP

		if index < columns.size() - 1:
			lanes.append({
				x = x + left + right + COLUMN_GAP * 0.5,
				# clear of the column it leaves, and clear of the one it enters
				exit_y = y - Y_GAP * 0.5,
				entry_y = origin.y - Y_GAP * 0.5
			})

		x += left + right + COLUMN_GAP

	return lanes


static func _card_centre(_step: Dictionary) -> float:
	var card: HenFlowGraphTypes.FlowNode = _step.card

	return card.position.x + card.size.x * 0.5


static func _choose_columns(_steps: Array) -> Array:
	var heights: Array[float] = []
	var widths: Array[float] = []

	for step: Dictionary in _steps:
		heights.append((step.box as Rect2).size.y)
		widths.append((step.box as Rect2).size.x)

	var chosen: Array = [Vector2i(0, _steps.size())]
	var deviation: float = INF

	for count: int in range(1, mini(_steps.size(), MAX_COLUMNS) + 1):
		var split: Array = _split_runs(heights, count)
		var shape: Vector2 = _columns_shape(split, widths, heights)
		var candidate: float = absf(log(maxf(shape.x / maxf(shape.y, 1.0), 0.001) / WRAP_ASPECT))

		if candidate < deviation - WRAP_EPSILON:
			deviation = candidate
			chosen = split

	return chosen


static func _split_runs(_heights: Array[float], _count: int) -> Array:
	var total: float = 0.0

	for height: float in _heights:
		total += height + Y_GAP

	var target: float = total / float(_count)
	var out: Array = []
	var start: int = 0
	var accumulated: float = 0.0

	for i: int in range(_heights.size()):
		accumulated += _heights[i] + Y_GAP

		var left_items: int = _heights.size() - i - 1
		var left_runs: int = _count - out.size() - 1

		if out.size() < _count - 1 and accumulated >= target and left_items >= left_runs:
			out.append(Vector2i(start, i + 1))
			start = i + 1
			accumulated = 0.0

	out.append(Vector2i(start, _heights.size()))

	return out


static func _columns_shape(_split: Array, _widths: Array[float], _heights: Array[float]) -> Vector2:
	var width: float = 0.0
	var tallest: float = 0.0

	for column: Vector2i in _split:
		var column_w: float = 0.0
		var column_h: float = 0.0

		for i: int in range(column.x, column.y):
			column_w = maxf(column_w, _widths[i])
			column_h += _heights[i]

		width += column_w
		tallest = maxf(tallest, column_h + float(column.y - column.x - 1) * Y_GAP)

	return Vector2(width + float(_split.size() - 1) * COLUMN_GAP, tallest)


# the run of actions the sequence chains one after another, which is what stacks
static func _chain_from(
	_from: HenFlowGraphTypes.FlowNode,
	_pin: StringName,
	_data: FormatData
) -> Array:
	var out: Array = []
	var current: Variant = _data.exec_to.get(_key(_from.id, _pin))

	while current != null and not out.has(current):
		out.append(current)
		current = _data.exec_to.get(_key((current as HenFlowGraphTypes.FlowNode).id, HenFlowGraphTypes.THEN_PIN))

	return out


# one action plus everything that only exists because of it: the producers feeding
# it, the transitions leaving it and, for a loop, its whole body
static func _step_closure(
	_graph: HenFlowGraphTypes.FlowGraph,
	_data: FormatData,
	_node: HenFlowGraphTypes.FlowNode
) -> Array[HenFlowGraphTypes.FlowNode]:
	var out: Array[HenFlowGraphTypes.FlowNode] = [_node]

	_collect_inputs(_data, _node, out)

	for pin: HenFlowGraphTypes.FlowPin in _node.pins_of(&'exec_out'):
		var target: Variant = _data.exec_to.get(_key(_node.id, pin.id))

		if target and (target as HenFlowGraphTypes.FlowNode).kind == &'transition' and not out.has(target):
			out.append(target)
			_collect_inputs(_data, target, out)

	for member: HenFlowGraphTypes.FlowNode in body_closure(_graph, _node):
		if not out.has(member):
			out.append(member)

	return out


static func _collect_inputs(
	_data: FormatData,
	_node: HenFlowGraphTypes.FlowNode,
	_out: Array[HenFlowGraphTypes.FlowNode]
) -> void:
	for pin: HenFlowGraphTypes.FlowPin in _node.pins_of(&'data_in'):
		var from: Variant = _data.data_from.get(_key(_node.id, pin.id))

		if not from or _out.has(from):
			continue

		if _data.format_of((from as HenFlowGraphTypes.FlowNode).id).input_owner != _node.id:
			continue

		_out.append(from)
		_collect_inputs(_data, from, _out)


static func _bounding_of(_nodes: Array) -> Rect2:
	if _nodes.is_empty():
		return Rect2()

	var out: Rect2 = Rect2((_nodes[0] as HenFlowGraphTypes.FlowNode).position, (_nodes[0] as HenFlowGraphTypes.FlowNode).size)

	for node: HenFlowGraphTypes.FlowNode in _nodes:
		out = out.merge(Rect2(node.position, node.size))

	return out


# a loop's chain is laid out on its own and folded into the owner's size, so the
# outer pass sees a loop as one box
# a loop grows to fit its body, so a loop nested in another has to be measured
# first: sized in graph order, the outer one is inflated around a body that has
# not grown yet and the inner one ends up larger than the card holding it
static func _bodies_deepest_first(_graph: HenFlowGraphTypes.FlowGraph) -> Array:
	var owner_of: Dictionary = {}
	var ranked: Array = []

	for node: HenFlowGraphTypes.FlowNode in _graph.nodes:
		for member: HenFlowGraphTypes.FlowNode in node.body:
			owner_of[member] = node

	for node: HenFlowGraphTypes.FlowNode in _graph.nodes:
		if node.body.is_empty():
			continue

		var depth: int = 0
		var current: Variant = owner_of.get(node)

		while current != null and depth < _graph.nodes.size():
			depth += 1
			current = owner_of.get(current)

		ranked.append({node = node, depth = depth})

	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.depth) > int(b.depth))

	return ranked.map(func(entry: Dictionary) -> HenFlowGraphTypes.FlowNode: return entry.node)


static func _layout_bodies(_graph: HenFlowGraphTypes.FlowGraph) -> void:
	for node: HenFlowGraphTypes.FlowNode in _bodies_deepest_first(_graph):
		if node.body.is_empty():
			continue

		var inner: HenFlowGraphTypes.FlowGraph = HenFlowGraphTypes.FlowGraph.new()
		var owned: Array[HenFlowGraphTypes.FlowNode] = _direct_members(_graph, node)

		inner.entry = node.body[0]
		inner.nodes.assign(owned)

		for edge: HenFlowGraphTypes.FlowEdge in _graph.edges:
			if owned.has(edge.from_node) and owned.has(edge.to_node):
				inner.edges.append(edge)

		var inner_data: FormatData = _index(inner)

		inner.entry.position = Vector2.ZERO
		inner_data.format_of(inner.entry.id).moved = true

		var box: Rect2 = _start_format(inner.entry, inner_data)

		# normalize to the origin so the owner can place the whole block at once
		for child: HenFlowGraphTypes.FlowNode in owned:
			child.position -= box.position

		node.size = Vector2(
			maxf(node.size.x, box.size.x + BODY_PAD * 2.0),
			node.size.y + box.size.y + BODY_PAD * 2.0
		)


# the body was laid out in its own space, so it follows the owner once the outer
# pass settled
static func _place_bodies(_graph: HenFlowGraphTypes.FlowGraph) -> void:
	# shallowest first: a member is placed against an owner that already settled,
	# and its own body follows in a later round
	var owners: Array = _bodies_deepest_first(_graph)

	owners.reverse()

	for node: HenFlowGraphTypes.FlowNode in owners:
		var owned: Array[HenFlowGraphTypes.FlowNode] = _direct_members(_graph, node)
		# above the branch row: an action with a body AND branches keeps that row at
		# the bottom of the card, and the body would land on top of it
		var origin: Vector2 = node.position + Vector2(
			BODY_PAD, node.size.y - node.flow_row_h - _body_height(owned)
		)

		for child: HenFlowGraphTypes.FlowNode in owned:
			child.position += origin


# what a body places itself: its own closure minus everything a nested body owns.
# a loop inside a loop keeps its members in ITS space, so they are moved once, by
# the loop holding them, instead of once per ancestor
static func _direct_members(_graph: HenFlowGraphTypes.FlowGraph, _node: HenFlowGraphTypes.FlowNode) -> Array[HenFlowGraphTypes.FlowNode]:
	var owned: Array[HenFlowGraphTypes.FlowNode] = body_closure(_graph, _node)

	for member: HenFlowGraphTypes.FlowNode in _node.body:
		if member.body.is_empty():
			continue

		for nested: HenFlowGraphTypes.FlowNode in body_closure(_graph, member):
			owned.erase(nested)

	return owned


# the chain of a body plus the satellites it owns: the producers feeding it and
# the transitions leaving it. leaving them out strands them at the origin
static func body_closure(_graph: HenFlowGraphTypes.FlowGraph, _node: HenFlowGraphTypes.FlowNode) -> Array[HenFlowGraphTypes.FlowNode]:
	var owned: Array[HenFlowGraphTypes.FlowNode] = []
	var pending: Array[HenFlowGraphTypes.FlowNode] = []

	pending.assign(_node.body)

	while not pending.is_empty():
		var current: HenFlowGraphTypes.FlowNode = pending.pop_back()

		if owned.has(current):
			continue

		owned.append(current)

		for edge: HenFlowGraphTypes.FlowEdge in _graph.edges:
			if edge.kind == &'data' and edge.to_node == current:
				pending.append(edge.from_node)
			elif edge.kind == &'exec' and edge.from_node == current:
				# every exec port of a member: the transition card it leaves through
				# and the steps a branch of it runs, which would strand at the origin.
				# nothing leaves a body this way, so the walk stays inside it
				pending.append(edge.to_node)

		for nested: HenFlowGraphTypes.FlowNode in current.body:
			pending.append(nested)

	return owned


static func _body_height(_owned: Array[HenFlowGraphTypes.FlowNode]) -> float:
	var bottom: float = 0.0

	for child: HenFlowGraphTypes.FlowNode in _owned:
		bottom = maxf(bottom, child.position.y + child.size.y)

	return bottom + BODY_PAD


static func _index(_graph: HenFlowGraphTypes.FlowGraph) -> FormatData:
	var data: FormatData = FormatData.new()

	for edge: HenFlowGraphTypes.FlowEdge in _graph.edges:
		if edge.kind == &'exec':
			data.exec_to[_key(edge.from_node.id, edge.from_pin)] = edge.to_node
			continue

		# a wire reads a step that is laid out on its own, so it pulls nothing here
		if edge.kind != &'data':
			continue

		data.data_from[_key(edge.to_node.id, edge.to_pin)] = edge.from_node

		if not data.consumers.has(edge.from_node.id):
			data.consumers[edge.from_node.id] = []

		(data.consumers[edge.from_node.id] as Array).append(edge.to_node)

	return data


# the connected flow outputs, left to right by pin anchor, so a subtree lands on
# the side its cell sits on; compute_size stamps the anchors before format runs
static func _flow_targets(_node: HenFlowGraphTypes.FlowNode, _data: FormatData) -> Array:
	var found: Array = []

	for pin: HenFlowGraphTypes.FlowPin in _node.pins_of(&'exec_out'):
		if pin.id == HenFlowGraphTypes.BODY_PIN:
			continue

		var target: Variant = _data.exec_to.get(_key(_node.id, pin.id))

		if target:
			found.append({x = _anchor_x(_node, pin), order = found.size(), pin = pin, target = target})

	# sort_custom is unstable, and `then` shares its x with the middle cell
	found.sort_custom(func(_a: Dictionary, _b: Dictionary) -> bool:
		return _a.x < _b.x if not is_equal_approx(_a.x, _b.x) else _a.order < _b.order
	)

	return found


# a loop is inflated after the anchors were stamped, so `then` re-derives its centre
static func _anchor_x(_node: HenFlowGraphTypes.FlowNode, _pin: HenFlowGraphTypes.FlowPin) -> float:
	if _pin.id == HenFlowGraphTypes.THEN_PIN:
		return _node.position.x + _node.size.x * 0.5

	return _node.position.x + _pin.rect.get_center().x


static func _start_format(_node: HenFlowGraphTypes.FlowNode, _data: FormatData) -> Rect2:
	var input_rect: Rect2 = _map_inputs(_node, _data)
	var min_pos: Vector2 = _node.position.min(input_rect.position)
	var max_pos: Vector2 = (_node.position + _node.size).max(input_rect.position + input_rect.size)

	var targets: Array = _flow_targets(_node, _data)
	var base_y: float = maxf(_node.position.y + _node.size.y, _data.y_limit)
	var format: NodeFormat = _data.format_of(_node.id)

	if targets.size() == 1:
		var child: Rect2 = _place_single(_node, targets[0], _data, format, base_y)
		min_pos = min_pos.min(child.position)
		max_pos = max_pos.max(child.position + child.size)
	elif targets.size() > 1:
		var fan: Rect2 = _place_fan(_node, targets, _data, format, base_y)
		min_pos = min_pos.min(fan.position)
		max_pos = max_pos.max(fan.position + fan.size)

	return Rect2(min_pos, max_pos - min_pos)


# under the anchor of the pin it leaves, so a lone branch keeps its cell's side
static func _place_single(
	_node: HenFlowGraphTypes.FlowNode,
	_item: Dictionary,
	_data: FormatData,
	_format: NodeFormat,
	_base_y: float
) -> Rect2:
	var to: HenFlowGraphTypes.FlowNode = _item.target
	var to_format: NodeFormat = _data.format_of(to.id)

	if to_format.moved:
		return Rect2(_node.position, Vector2.ZERO)

	to_format.moved = true
	_format.tree_children.append(to)

	to.position = Vector2(float(_item.x) - to.size.x * 0.5, _base_y + Y_GAP)

	_start_format(to, _data)

	return _tree_bounding(to, _data)


# the sequence continues straight under the card and the branch targets open to
# the sides of it, each side pushed out until its subtree stops overlapping
static func _place_fan(
	_node: HenFlowGraphTypes.FlowNode,
	_items: Array,
	_data: FormatData,
	_format: NodeFormat,
	_base_y: float
) -> Rect2:
	var centre: float = _node.position.x + _node.size.x * 0.5
	var middle: Variant = null
	var left: Array = []
	var right: Array = []

	for item: Dictionary in _items:
		if (item.pin as HenFlowGraphTypes.FlowPin).id == HenFlowGraphTypes.THEN_PIN:
			middle = item
		elif float(item.x) < centre:
			left.append(item)
		else:
			right.append(item)

	# the branch cards themselves, not what hangs off them: a long run on a side
	# would sink the middle by its whole height
	var side_bottom: float = _base_y
	var placed_left: Array[HenFlowGraphTypes.FlowNode] = []
	var placed_right: Array[HenFlowGraphTypes.FlowNode] = []

	left.reverse()

	var limit: float = centre - MIDDLE_X_GAP
	var idx: int = -left.size()

	for item: Dictionary in left:
		var box: Rect2 = _place_side(_node, item.target, _data, _format, _base_y, idx, limit, true)
		idx += 1
		if box.size == Vector2.ZERO:
			continue
		limit = minf(limit, box.position.x - MIDDLE_X_GAP)
		side_bottom = maxf(side_bottom, _card_bottom(item.target))
		placed_left.append(item.target)

	limit = centre + MIDDLE_X_GAP
	idx = -right.size()

	for item: Dictionary in right:
		var box: Rect2 = _place_side(_node, item.target, _data, _format, _base_y, idx, limit, false)
		idx += 1
		if box.size == Vector2.ZERO:
			continue
		limit = maxf(limit, box.position.x + box.size.x + MIDDLE_X_GAP)
		side_bottom = maxf(side_bottom, _card_bottom(item.target))
		placed_right.append(item.target)

	# last, and under the branch row: the run reads as what happens after the
	# branches without waiting for the runs they carry
	var middle_node: Variant = null

	if middle != null and _place_single(
		_node, middle, _data, _format, side_bottom + MIDDLE_Y_GAP - Y_GAP
	).size != Vector2.ZERO:
		middle_node = middle.target

		var column: Array[HenFlowGraphTypes.FlowNode] = _tree_nodes(middle_node, _data)

		_clear_column(placed_left, column, _data, true, centre - MIDDLE_X_GAP)
		_clear_column(placed_right, column, _data, false, centre + MIDDLE_X_GAP)

	if middle_node != null:
		placed_right.append(middle_node)

	var min_pos: Vector2 = _node.position
	var max_pos: Vector2 = _node.position + _node.size

	# measured after the pushes, so a side that moved carries its own subtree
	for group: Array in [placed_left, placed_right]:
		for target: HenFlowGraphTypes.FlowNode in group:
			var box: Rect2 = _tree_bounding(target, _data)

			min_pos = min_pos.min(box.position)
			max_pos = max_pos.max(box.position + box.size)

	return Rect2(min_pos, max_pos - min_pos)


static func _card_bottom(_node: HenFlowGraphTypes.FlowNode) -> float:
	return _node.position.y + _node.size.y


# the run shares the fan's rows now, so a side is pushed off the part of the run
# that actually sits beside it, and the sides further out follow
static func _clear_column(
	_placed: Array[HenFlowGraphTypes.FlowNode],
	_column: Array[HenFlowGraphTypes.FlowNode],
	_data: FormatData,
	_is_left: bool,
	_start: float
) -> void:
	var limit: float = _start

	for target: HenFlowGraphTypes.FlowNode in _placed:
		var box: Rect2 = _tree_bounding(target, _data)
		var wall: float = _column_wall(_column, box, _is_left)
		var edge: float = minf(limit, wall) if _is_left else maxf(limit, wall)

		if _is_left and box.position.x + box.size.x > edge:
			_move_tree(target, Vector2(edge - box.position.x - box.size.x, 0.0), _data)
			box = _tree_bounding(target, _data)
		elif not _is_left and box.position.x < edge:
			_move_tree(target, Vector2(edge - box.position.x, 0.0), _data)
			box = _tree_bounding(target, _data)

		limit = minf(limit, box.position.x - MIDDLE_X_GAP) if _is_left 			else maxf(limit, box.position.x + box.size.x + MIDDLE_X_GAP)


# INF when nothing of the run shares the rows the box occupies, which leaves the
# caller on its own limit
static func _column_wall(
	_column: Array[HenFlowGraphTypes.FlowNode],
	_box: Rect2,
	_is_left: bool
) -> float:
	var wall: float = INF if _is_left else -INF

	for node: HenFlowGraphTypes.FlowNode in _column:
		if node.position.y + node.size.y <= _box.position.y:
			continue

		if node.position.y >= _box.position.y + _box.size.y:
			continue

		if _is_left:
			wall = minf(wall, node.position.x - MIDDLE_X_GAP)
		else:
			wall = maxf(wall, node.position.x + node.size.x + MIDDLE_X_GAP)

	return wall


static func _tree_nodes(
	_node: HenFlowGraphTypes.FlowNode,
	_data: FormatData
) -> Array[HenFlowGraphTypes.FlowNode]:
	var out: Array[HenFlowGraphTypes.FlowNode] = [_node]

	for pin: HenFlowGraphTypes.FlowPin in _node.pins_of(&'data_in'):
		var from: Variant = _data.data_from.get(_key(_node.id, pin.id))

		if from and _data.format_of((from as HenFlowGraphTypes.FlowNode).id).input_owner == _node.id:
			out.append_array(_tree_nodes(from, _data))

	for child: HenFlowGraphTypes.FlowNode in _data.format_of(_node.id).tree_children:
		out.append_array(_tree_nodes(child, _data))

	return out


static func _place_side(
	_node: HenFlowGraphTypes.FlowNode,
	_to: HenFlowGraphTypes.FlowNode,
	_data: FormatData,
	_format: NodeFormat,
	_base_y: float,
	_idx: int,
	_limit: float,
	_is_left: bool
) -> Rect2:
	var to_format: NodeFormat = _data.format_of(_to.id)

	if to_format.moved:
		return Rect2()

	to_format.moved = true
	_format.tree_children.append(_to)

	var x: float = _limit - _to.size.x if _is_left else _limit

	_to.position = Vector2(x, _base_y + FIRST_LEVEL_Y_GAP * float(-_idx))

	_start_format(_to, _data)

	var box: Rect2 = _tree_bounding(_to, _data)

	# the subtree may be wider than its root, so push the whole thing off the limit
	if _is_left and box.position.x + box.size.x > _limit:
		_move_tree(_to, Vector2(_limit - (box.position.x + box.size.x), 0), _data)
		box = _tree_bounding(_to, _data)
	elif not _is_left and box.position.x < _limit:
		_move_tree(_to, Vector2(_limit - box.position.x, 0), _data)
		box = _tree_bounding(_to, _data)

	return box


static func _move_tree(_node: HenFlowGraphTypes.FlowNode, _offset: Vector2, _data: FormatData) -> void:
	_node.position += _offset

	var format: NodeFormat = _data.format_of(_node.id)

	for pin: HenFlowGraphTypes.FlowPin in _node.pins_of(&'data_in'):
		var from: Variant = _data.data_from.get(_key(_node.id, pin.id))

		if from and _data.format_of((from as HenFlowGraphTypes.FlowNode).id).input_owner == _node.id:
			_move_tree(from, _offset, _data)

	for child: HenFlowGraphTypes.FlowNode in format.tree_children:
		_move_tree(child, _offset, _data)


static func _tree_bounding(_node: HenFlowGraphTypes.FlowNode, _data: FormatData) -> Rect2:
	var min_pos: Vector2 = _node.position
	var max_pos: Vector2 = _node.position + _node.size
	var format: NodeFormat = _data.format_of(_node.id)

	for pin: HenFlowGraphTypes.FlowPin in _node.pins_of(&'data_in'):
		var from: Variant = _data.data_from.get(_key(_node.id, pin.id))

		if from and _data.format_of((from as HenFlowGraphTypes.FlowNode).id).input_owner == _node.id:
			var box: Rect2 = _tree_bounding(from, _data)
			min_pos = min_pos.min(box.position)
			max_pos = max_pos.max(box.position + box.size)

	for child: HenFlowGraphTypes.FlowNode in format.tree_children:
		var child_box: Rect2 = _tree_bounding(child, _data)
		min_pos = min_pos.min(child_box.position)
		max_pos = max_pos.max(child_box.position + child_box.size)

	return Rect2(min_pos, max_pos - min_pos)


# producers stack to the left of the node they feed, each below the previous one
static func _map_inputs(_node: HenFlowGraphTypes.FlowNode, _data: FormatData) -> Rect2:
	_data.y_limit = _node.position.y

	var cursor: float = _node.position.y
	var flow_bottom: float = _node.position.y + _node.size.y
	var min_pos: Vector2 = _node.position
	var max_pos: Vector2 = _node.position + _node.size

	for pin: HenFlowGraphTypes.FlowPin in _node.pins_of(&'data_in'):
		var raw: Variant = _data.data_from.get(_key(_node.id, pin.id))

		if not raw:
			continue

		var from: HenFlowGraphTypes.FlowNode = raw
		var from_format: NodeFormat = _data.format_of(from.id)

		if from_format.moved:
			if from_format.input_owner == _node.id:
				var placed: Rect2 = _tree_bounding(from, _data)
				min_pos = min_pos.min(placed.position)
				max_pos = max_pos.max(placed.position + placed.size)

				var bottom: float = maxf(from.position.y + from.size.y, placed.position.y + placed.size.y)
				cursor = maxf(cursor, bottom + INPUT_Y_GAP)

				if bottom > _node.position.y:
					flow_bottom = maxf(flow_bottom, bottom)
			continue

		var best: Vector2 = Vector2(_node.position.x - from.size.x - INPUT_X_GAP, cursor)

		# a producer feeding more than one consumer sits left of, and above, all of them
		for consumer: HenFlowGraphTypes.FlowNode in _data.consumers.get(from.id, []):
			if not _data.format_of(consumer.id).moved:
				continue

			if consumer != _node and consumer.position.y < best.y:
				best.y = consumer.position.y

			best.x = minf(best.x, consumer.position.x - from.size.x - INPUT_X_GAP)

		from.position = best
		from_format.moved = true
		from_format.input_owner = _node.id

		var box: Rect2 = _map_inputs(from, _data)
		var branch_bottom: float = maxf(from.position.y + from.size.y, box.position.y + box.size.y)

		cursor = maxf(cursor, branch_bottom + INPUT_Y_GAP)

		if branch_bottom > _node.position.y:
			min_pos = min_pos.min(box.position)
			max_pos = max_pos.max(box.position + box.size)
			flow_bottom = maxf(flow_bottom, branch_bottom)

	_data.y_limit = maxf(_data.y_limit, flow_bottom)

	return Rect2(min_pos, max_pos - min_pos)
