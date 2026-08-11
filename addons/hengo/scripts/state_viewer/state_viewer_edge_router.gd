@tool
class_name HenStateViewerEdgeRouter
extends RefCounted

# orthogonal routing over the lanes left free between the boxes of one scope. the
# layout is never touched: this only picks where a line leaves a box, where it
# enters the next one and which free lanes it takes in between

const MARGIN: float = 20.0
# a bend costs this much length, which is what keeps a route from zig-zagging
const TURN_COST: float = 90.0
# ports keep off the rounded corners, and off each other
const SIDE_INSET: float = 18.0
const PORT_GAP: float = 26.0
const MERGE_TOL: float = 1.5
const LANE_STEP: float = 13.0
const LANE_TOL: float = 8.0
const CROSSBAR_TRIES: int = 10
# a route nobody can draw cheaply keeps the corridor one instead of stalling a rebuild
const EXPANSION_BUDGET: int = 12000

enum Side {TOP, RIGHT, BOTTOM, LEFT}

const OUTWARD: Array[Vector2] = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]

var _cost: PackedFloat32Array = PackedFloat32Array()
var _heap_priority: PackedFloat32Array = PackedFloat32Array()
var _heap_state: PackedInt32Array = PackedInt32Array()
var _came: PackedInt32Array = PackedInt32Array()


# the lattice of the boxes in one scope, plus which cells they fill
class Field extends RefCounted:
	var xs: PackedFloat32Array = PackedFloat32Array()
	var ys: PackedFloat32Array = PackedFloat32Array()
	var blocked: PackedByteArray = PackedByteArray()
	# one byte per lattice vertex: bit 0 right, 1 left, 2 down, 3 up
	var moves: PackedByteArray = PackedByteArray()
	var rects: Array[Rect2] = []


	# a run may graze a box's margin, which is the lane the margin exists for, so
	# the boxes are shrunk before the test instead of the run being inflated
	func clear(_a: Vector2, _b: Vector2, _ignore: Array[Rect2] = []) -> bool:
		var run: Rect2 = Rect2(_a.min(_b), (_b - _a).abs().max(Vector2(0.01, 0.01)))

		for rect: Rect2 in rects:
			if _ignore.has(rect):
				continue

			if run.intersects(rect.grow(-1.0)):
				return false

		return true


	func columns() -> int:
		return xs.size() - 1


	func rows() -> int:
		return ys.size() - 1


	func cell(_i: int, _j: int) -> bool:
		if _i < 0 or _j < 0 or _i >= columns() or _j >= rows():
			return true

		return blocked[_j * columns() + _i] == 1


	# a run along a lattice line only counts as blocked when it is buried on both
	# sides: hugging one box is exactly the lane the margin was left for
	func free_h(_i: int, _j: int) -> bool:
		return not cell(_i, _j - 1) or not cell(_i, _j)


	func free_v(_i: int, _j: int) -> bool:
		return not cell(_i - 1, _j) or not cell(_i, _j)


	func nearest_x(_value: float) -> int:
		return _nearest(xs, _value)


	func nearest_y(_value: float) -> int:
		return _nearest(ys, _value)


	static func _nearest(_values: PackedFloat32Array, _value: float) -> int:
		var best: int = 0

		for i: int in range(_values.size()):
			if absf(_values[i] - _value) < absf(_values[best] - _value):
				best = i

		return best


# every edge whose endpoints are both direct children of the same node, grouped by
# that node. anything else keeps the route it already has
static func routable(edges: Array) -> Dictionary:
	var groups: Dictionary = {}

	for edge: HenStateViewerGraphTypes.DirectedGraphEdge in edges:
		var scope: HenStateViewerGraphTypes.DirectedGraphNode = edge.source.parent

		if scope == null or edge.target.parent != scope or edge.source == edge.target:
			continue

		if not groups.has(scope):
			groups[scope] = []

		(groups[scope] as Array).append(edge)

	return groups


# returns the edges it actually took over; anything it fails on keeps its old route
func route_scope(scope: HenStateViewerGraphTypes.DirectedGraphNode, edges: Array) -> Array:
	var routed: Array = []

	if scope.children.is_empty() or edges.is_empty():
		return routed

	var rects: Dictionary = {}

	for child: HenStateViewerGraphTypes.DirectedGraphNode in scope.children:
		rects[child] = Rect2(child.get_absolute(), Vector2(child.layout.width, child.layout.height))

	var field: Field = _build_field(rects.values())
	var ports: Dictionary = _assign_ports(edges, rects)
	var routes: Array = []

	for edge: HenStateViewerGraphTypes.DirectedGraphEdge in edges:
		var points: PackedVector2Array = _route(field, ports[edge])

		if points.size() < 2:
			continue

		routes.append({
			edge = edge,
			points = points,
			# the runs leaving a port necessarily touch the margin of their own box
			own = ([rects[edge.source].grow(MARGIN), rects[edge.target].grow(MARGIN)] as Array[Rect2])
		})
		routed.append(edge)

	_separate(field, routes)

	for route: Dictionary in routes:
		(route.edge as HenStateViewerGraphTypes.DirectedGraphEdge).sections = [_section(route.points)]

	return routed


# --- lane separation ---

# two routes that end up on the same lane draw one over the other. only the runs
# between two bends move, and only where the box the lane hugs stays clear
func _separate(_field: Field, _routes: Array) -> void:
	var runs: Array = []

	for index: int in range(_routes.size()):
		var points: PackedVector2Array = _routes[index].points

		for i: int in range(points.size() - 1):
			var a: Vector2 = points[i]
			var b: Vector2 = points[i + 1]
			var horizontal: bool = absf(a.y - b.y) < 0.5

			if horizontal == (absf(a.x - b.x) < 0.5):
				continue

			runs.append({
				route = index,
				at = i,
				horizontal = horizontal,
				# the runs touching a port are anchored to it, they only take a track
				fixed = i == 0 or i >= points.size() - 2,
				position = a.y if horizontal else a.x,
				from = minf(a.x, b.x) if horizontal else minf(a.y, b.y),
				to = maxf(a.x, b.x) if horizontal else maxf(a.y, b.y)
			})

	# an anchored sweep, not rounded buckets: two runs a hair apart would land on
	# opposite sides of a bucket edge and never be compared
	runs.sort_custom(func(a, b):
		if a.horizontal != b.horizontal:
			return a.horizontal

		return a.position < b.position
	)

	var lane: Array = []
	var anchor: float = 0.0
	var horizontal: bool = false

	for run: Dictionary in runs:
		if lane.is_empty() or run.horizontal != horizontal or run.position - anchor > LANE_TOL:
			_fan(_field, _routes, lane)
			lane = [run]
			anchor = run.position
			horizontal = run.horizontal
			continue

		lane.append(run)

	_fan(_field, _routes, lane)


func _fan(_field: Field, _routes: Array, _lane: Array) -> void:
	if _lane.size() < 2:
		return

	# anchored runs are coloured first so they take the tracks nobody can leave
	_lane.sort_custom(func(a, b):
		if a.fixed != b.fixed:
			return a.fixed

		if a.from != b.from:
			return a.from < b.from

		return a.route < b.route
	)

	# greedy colouring: a run only needs its own track while another one overlaps it
	var track_ends: Array[float] = []

	for run: Dictionary in _lane:
		var assigned: int = -1

		for t: int in range(track_ends.size()):
			if track_ends[t] <= run.from:
				assigned = t
				break

		if assigned == -1:
			assigned = track_ends.size()
			track_ends.append(run.to)
		else:
			track_ends[assigned] = run.to

		run.track = assigned

	if track_ends.size() < 2:
		return

	for run: Dictionary in _lane:
		if run.track == 0 or run.fixed:
			continue

		var step: float = float((run.track + 1) / 2) * LANE_STEP
		var sign: float = 1.0 if run.track % 2 == 1 else -1.0

		for attempt: float in [step * sign, step * -sign, (step + LANE_STEP) * sign, (step + LANE_STEP) * -sign]:
			if _shift(_field, _routes[run.route], run.at, run.horizontal, attempt):
				break


func _shift(_field: Field, _route: Dictionary, _at: int, _horizontal: bool, _offset: float) -> bool:
	var points: PackedVector2Array = _route.points
	var delta: Vector2 = Vector2(0.0, _offset) if _horizontal else Vector2(_offset, 0.0)
	var moved: PackedVector2Array = points.duplicate()

	moved[_at] += delta
	moved[_at + 1] += delta

	for i: int in range(_at - 1, _at + 2):
		if not _field.clear(moved[i], moved[i + 1], _route.own):
			return false

	points[_at] = moved[_at]
	points[_at + 1] = moved[_at + 1]
	_route.points = points

	return true


func _section(_points: PackedVector2Array) -> Dictionary:
	var bends: Array = []

	for i: int in range(1, _points.size() - 1):
		bends.append(_points[i])

	return {
		start_point = _points[0],
		bend_points = bends,
		end_point = _points[_points.size() - 1],
		label_pos = _longest_midpoint(_points)
	}


# the pill sits on the run with the most room, which is rarely the geometric middle
func _longest_midpoint(_points: PackedVector2Array) -> Vector2:
	var best: Vector2 = (_points[0] + _points[_points.size() - 1]) * 0.5
	var longest: float = 0.0

	for i: int in range(_points.size() - 1):
		var length: float = _points[i].distance_to(_points[i + 1])

		if length > longest:
			longest = length
			best = (_points[i] + _points[i + 1]) * 0.5

	return best


# --- lattice ---

func _build_field(_rects: Array) -> Field:
	var field: Field = Field.new()
	var xs: Array[float] = []
	var ys: Array[float] = []

	for rect: Rect2 in _rects:
		var grown: Rect2 = rect.grow(MARGIN)

		xs.append(grown.position.x)
		xs.append(grown.position.x + grown.size.x)
		ys.append(grown.position.y)
		ys.append(grown.position.y + grown.size.y)

	# a ring outside every box, or a route that has to come around the outside finds
	# the lattice ending at the boxes and no way past them
	var span: Rect2 = _bounding(_rects).grow(MARGIN * 3.0)

	xs.append(span.position.x)
	xs.append(span.position.x + span.size.x)
	ys.append(span.position.y)
	ys.append(span.position.y + span.size.y)

	field.xs = _merge(xs)
	field.ys = _merge(ys)
	field.blocked = PackedByteArray()
	field.blocked.resize(maxi(0, field.columns() * field.rows()))

	for rect: Rect2 in _rects:
		var grown: Rect2 = rect.grow(MARGIN)

		field.rects.append(grown)
		_mark(field, grown)

	_bake_moves(field)

	return field


# which of the four steps each lattice vertex allows, as one byte. asking the cell
# grid inside the search costs a dozen calls per vertex, and that was the search
func _bake_moves(_field: Field) -> void:
	var width: int = _field.xs.size()
	var height: int = _field.ys.size()
	var columns: int = _field.columns()
	var rows: int = _field.rows()
	var padded_w: int = columns + 2
	var padded: PackedByteArray = PackedByteArray()

	padded.resize(padded_w * (rows + 2))
	padded.fill(1)

	for j: int in range(rows):
		for i: int in range(columns):
			padded[(j + 1) * padded_w + i + 1] = _field.blocked[j * columns + i]

	_field.moves = PackedByteArray()
	_field.moves.resize(width * height)

	for j: int in range(height):
		for i: int in range(width):
			var mask: int = 0
			var horizontal: bool = padded[j * padded_w + i + 1] == 0 or padded[(j + 1) * padded_w + i + 1] == 0
			var vertical: bool = padded[(j + 1) * padded_w + i] == 0 or padded[(j + 1) * padded_w + i + 1] == 0

			if i + 1 < width and horizontal:
				mask |= 1

			if i > 0 and (padded[j * padded_w + i] == 0 or padded[(j + 1) * padded_w + i] == 0):
				mask |= 2

			if j + 1 < height and vertical:
				mask |= 4

			if j > 0 and (padded[j * padded_w + i] == 0 or padded[j * padded_w + i + 1] == 0):
				mask |= 8

			_field.moves[j * width + i] = mask


static func _bounding(_rects: Array) -> Rect2:
	var out: Rect2 = _rects[0]

	for rect: Rect2 in _rects:
		out = out.merge(rect)

	return out


static func _merge(_values: Array[float]) -> PackedFloat32Array:
	_values.sort()

	var out: PackedFloat32Array = PackedFloat32Array()

	for value: float in _values:
		if out.is_empty() or value - out[out.size() - 1] > MERGE_TOL:
			out.append(value)

	return out


func _mark(_field: Field, _rect: Rect2) -> void:
	var columns: int = _field.columns()

	for i: int in range(columns):
		if _field.xs[i + 1] <= _rect.position.x + MERGE_TOL:
			continue

		if _field.xs[i] >= _rect.position.x + _rect.size.x - MERGE_TOL:
			break

		for j: int in range(_field.rows()):
			if _field.ys[j + 1] <= _rect.position.y + MERGE_TOL:
				continue

			if _field.ys[j] >= _rect.position.y + _rect.size.y - MERGE_TOL:
				break

			_field.blocked[j * columns + i] = 1


# --- ports ---

# each end asks for the spot on its side that lines the route up straight, and the
# ends sharing a side are pushed apart only as far as they have to be. asking for
# the middle of the side instead is what turns a run that could be one line into
# a staircase
func _assign_ports(_edges: Array, _rects: Dictionary) -> Dictionary:
	var lanes: Dictionary = {}
	var ports: Dictionary = {}

	for edge: HenStateViewerGraphTypes.DirectedGraphEdge in _edges:
		var from: Rect2 = _rects[edge.source]
		var to: Rect2 = _rects[edge.target]
		var sides: Vector2i = _sides(from, to)
		var wanted: Vector2 = _desired(from, to, sides)

		ports[edge] = {}

		_push_lane(lanes, edge.source, sides.x, edge, true, wanted.x)
		_push_lane(lanes, edge.target, sides.y, edge, false, wanted.y)

	for key: Variant in lanes:
		var lane: Array = lanes[key]

		lane.sort_custom(func(a, b):
			if a.wanted != b.wanted:
				return a.wanted < b.wanted

			return a.edge.id < b.edge.id
		)

		var first: Dictionary = lane[0]
		var span: Vector2 = _side_span(_rects[first.node], first.side)

		var placed: Array[float] = _spread(lane, span)

		for index: int in range(lane.size()):
			var entry: Dictionary = lane[index]
			var point: Vector2 = _port_point(_rects[entry.node], entry.side, placed[index])

			if entry.is_source:
				ports[entry.edge].start = point
				ports[entry.edge].start_out = OUTWARD[entry.side]
			else:
				ports[entry.edge].end = point
				ports[entry.edge].end_out = OUTWARD[entry.side]

	return ports


# monotone projection: keep the asked-for order, honour the minimum gap, stay in
# the span. the ends that do not compete land exactly where they asked
func _spread(_lane: Array, _span: Vector2) -> Array[float]:
	var count: int = _lane.size()
	var gap: float = minf(PORT_GAP, (_span.y - _span.x) / maxf(1.0, float(count - 1)))
	var out: Array[float] = []

	out.resize(count)

	for index: int in range(count):
		var floor_at: float = _span.x if index == 0 else out[index - 1] + gap
		var ceil_at: float = _span.y - gap * float(count - 1 - index)

		out[index] = clampf(_lane[index].wanted, floor_at, maxf(floor_at, ceil_at))

	return out


func _push_lane(
	_lanes: Dictionary,
	_node: HenStateViewerGraphTypes.DirectedGraphNode,
	_side: int,
	_edge: HenStateViewerGraphTypes.DirectedGraphEdge,
	_is_source: bool,
	_wanted: float
) -> void:
	var key: String = _node.id + '|' + str(_side)

	if not _lanes.has(key):
		_lanes[key] = []

	(_lanes[key] as Array).append({
		node = _node,
		side = _side,
		edge = _edge,
		is_source = _is_source,
		wanted = _wanted
	})


# boxes that share a column or a row face each other; anything diagonal is joined
# with a single bend, leaving along the axis that separates them more
func _sides(_from: Rect2, _to: Rect2) -> Vector2i:
	var overlap_x: bool = _from.position.x < _to.position.x + _to.size.x \
		and _to.position.x < _from.position.x + _from.size.x
	var overlap_y: bool = _from.position.y < _to.position.y + _to.size.y \
		and _to.position.y < _from.position.y + _from.size.y
	var below: bool = _to.get_center().y >= _from.get_center().y
	var right: bool = _to.get_center().x >= _from.get_center().x

	if overlap_x and not overlap_y:
		return Vector2i(Side.BOTTOM, Side.TOP) if below else Vector2i(Side.TOP, Side.BOTTOM)

	if overlap_y and not overlap_x:
		return Vector2i(Side.RIGHT, Side.LEFT) if right else Vector2i(Side.LEFT, Side.RIGHT)

	var gap_x: float = maxf(
		_from.position.x - (_to.position.x + _to.size.x),
		_to.position.x - (_from.position.x + _from.size.x)
	)
	var gap_y: float = maxf(
		_from.position.y - (_to.position.y + _to.size.y),
		_to.position.y - (_from.position.y + _from.size.y)
	)

	if overlap_x and overlap_y:
		if gap_y >= gap_x:
			return Vector2i(Side.BOTTOM, Side.TOP) if below else Vector2i(Side.TOP, Side.BOTTOM)

		return Vector2i(Side.RIGHT, Side.LEFT) if right else Vector2i(Side.LEFT, Side.RIGHT)

	if gap_y >= gap_x:
		return Vector2i(
			Side.BOTTOM if below else Side.TOP,
			Side.LEFT if right else Side.RIGHT
		)

	return Vector2i(
		Side.RIGHT if right else Side.LEFT,
		Side.TOP if below else Side.BOTTOM
	)


# where each end would sit for the shortest route: facing sides share one line, a
# single bend aims each end at the corner between the two boxes
func _desired(_from: Rect2, _to: Rect2, _pair: Vector2i) -> Vector2:
	var from_vertical: bool = _pair.x == Side.TOP or _pair.x == Side.BOTTOM
	var to_vertical: bool = _pair.y == Side.TOP or _pair.y == Side.BOTTOM

	if from_vertical and to_vertical:
		var shared: float = _overlap_centre(
			_from.position.x, _from.position.x + _from.size.x,
			_to.position.x, _to.position.x + _to.size.x
		)

		return Vector2(shared, shared)

	if not from_vertical and not to_vertical:
		var shared: float = _overlap_centre(
			_from.position.y, _from.position.y + _from.size.y,
			_to.position.y, _to.position.y + _to.size.y
		)

		return Vector2(shared, shared)

	if from_vertical:
		return Vector2(
			_to.position.x - MARGIN if _pair.y == Side.LEFT else _to.position.x + _to.size.x + MARGIN,
			_from.position.y + _from.size.y + MARGIN if _pair.x == Side.BOTTOM else _from.position.y - MARGIN
		)

	return Vector2(
		_to.position.y - MARGIN if _pair.y == Side.TOP else _to.position.y + _to.size.y + MARGIN,
		_from.position.x + _from.size.x + MARGIN if _pair.x == Side.RIGHT else _from.position.x - MARGIN
	)


static func _overlap_centre(_a0: float, _a1: float, _b0: float, _b1: float) -> float:
	var low: float = maxf(_a0, _b0)
	var high: float = minf(_a1, _b1)

	if low < high:
		return (low + high) * 0.5

	return ((_a0 + _a1) + (_b0 + _b1)) * 0.25


# the stretch of a side a port may use, in world coordinates along that side
func _side_span(_rect: Rect2, _side: int) -> Vector2:
	if _side == Side.LEFT or _side == Side.RIGHT:
		var inset_y: float = minf(SIDE_INSET, _rect.size.y * 0.25)

		return Vector2(_rect.position.y + inset_y, _rect.position.y + _rect.size.y - inset_y)

	var inset_x: float = minf(SIDE_INSET, _rect.size.x * 0.25)

	return Vector2(_rect.position.x + inset_x, _rect.position.x + _rect.size.x - inset_x)


func _port_point(_rect: Rect2, _side: int, _at: float) -> Vector2:
	match _side:
		Side.TOP:
			return Vector2(_at, _rect.position.y)
		Side.BOTTOM:
			return Vector2(_at, _rect.position.y + _rect.size.y)
		Side.LEFT:
			return Vector2(_rect.position.x, _at)
		_:
			return Vector2(_rect.position.x + _rect.size.x, _at)


# --- search ---

func _route(_field: Field, _port: Dictionary) -> PackedVector2Array:
	var start: Vector2 = _port.start
	var end: Vector2 = _port.end
	var escape_a: Vector2 = start + (_port.start_out as Vector2) * MARGIN
	var escape_b: Vector2 = end + (_port.end_out as Vector2) * MARGIN

	var middle: PackedVector2Array = _shape(_field, escape_a, escape_b, _port.start_out, _port.end_out)

	if middle.is_empty():
		middle = _search(_field, escape_a, escape_b, _port.start_out, _port.end_out)

	if middle.is_empty():
		return PackedVector2Array()

	var out: PackedVector2Array = PackedVector2Array([start])

	for point: Vector2 in middle:
		out.append(point)

	out.append(end)

	return _simplify(out)


# the clean shapes, tried before the search: a straight run, a z between two
# facing sides, an l between a vertical side and a horizontal one. the search only
# gets what none of these can reach without cutting a box
func _shape(_field: Field, _a: Vector2, _b: Vector2, _a_dir: Vector2, _b_dir: Vector2) -> PackedVector2Array:
	var vertical_a: bool = absf(_a_dir.y) > 0.5
	var vertical_b: bool = absf(_b_dir.y) > 0.5

	if vertical_a != vertical_b:
		var elbow: PackedVector2Array = _elbow(_field, _a, _b, vertical_a)

		if not elbow.is_empty():
			return elbow
	elif vertical_a and absf(_a.x - _b.x) <= MERGE_TOL and _field.clear(_a, _b):
		return PackedVector2Array([_a, _b])
	elif not vertical_a and absf(_a.y - _b.y) <= MERGE_TOL and _field.clear(_a, _b):
		return PackedVector2Array([_a, _b])

	# the crossbar is tried on the port's own axis first, then across it: the second
	# one is the way around a target that sits behind the side the line left from
	var zigzag: PackedVector2Array = _zigzag(_field, _a, _b, vertical_a)

	if not zigzag.is_empty():
		return zigzag

	return _zigzag(_field, _a, _b, not vertical_a)


# the corner sits on the vertical side's coordinate, so each leg leaves its port
# along the port's own normal
func _elbow(_field: Field, _a: Vector2, _b: Vector2, _vertical_a: bool) -> PackedVector2Array:
	var corner: Vector2 = Vector2(_a.x, _b.y) if _vertical_a else Vector2(_b.x, _a.y)

	if not _field.clear(_a, corner) or not _field.clear(corner, _b):
		return PackedVector2Array()

	return PackedVector2Array([_a, corner, _b])


# the crossbar slides to the first free offset, starting from halfway
func _zigzag(_field: Field, _a: Vector2, _b: Vector2, _vertical: bool) -> PackedVector2Array:
	for value: float in _crossbars(_field, _a, _b, _vertical):
		var first: Vector2 = Vector2(_a.x, value) if _vertical else Vector2(value, _a.y)
		var second: Vector2 = Vector2(_b.x, value) if _vertical else Vector2(value, _b.y)

		if _field.clear(_a, first) and _field.clear(first, second) and _field.clear(second, _b):
			return PackedVector2Array([_a, first, second, _b])

	return PackedVector2Array()


# halfway first, then the lattice lines in between, nearest one first
func _crossbars(_field: Field, _a: Vector2, _b: Vector2, _vertical: bool) -> Array[float]:
	var from: float = _a.y if _vertical else _a.x
	var to: float = _b.y if _vertical else _b.x
	var middle: float = (from + to) * 0.5
	var lines: PackedFloat32Array = _field.ys if _vertical else _field.xs
	var low: float = minf(from, to)
	var high: float = maxf(from, to)
	var out: Array[float] = [middle]
	var inside: Array[float] = []
	# a target sitting behind the side the line left from is only reachable around
	# the outside, so the lanes past both boxes are candidates too
	var outside: Array[float] = []

	for line: float in lines:
		if line > low + MERGE_TOL and line < high - MERGE_TOL:
			inside.append(line)
		else:
			outside.append(line)

	inside.sort_custom(func(a, b): return absf(a - middle) < absf(b - middle))
	outside.sort_custom(func(a, b):
		return minf(absf(a - low), absf(a - high)) < minf(absf(b - low), absf(b - high))
	)

	out.append_array(inside.slice(0, CROSSBAR_TRIES))
	out.append_array(outside.slice(0, CROSSBAR_TRIES))

	return out


# the escape points sit on a lattice line but at a free coordinate, so the search
# runs between lattice vertices and the escapes join it with one run each
func _search(
	_field: Field,
	_from: Vector2,
	_to: Vector2,
	_from_dir: Vector2,
	_to_dir: Vector2
) -> PackedVector2Array:
	if _field.xs.size() < 2 or _field.ys.size() < 2:
		return PackedVector2Array()

	var vertical_start: bool = absf(_from_dir.y) > 0.5
	var vertical_end: bool = absf(_to_dir.y) > 0.5

	var entries: Array[Vector2i] = []
	var exits: Array[Vector2i] = []

	for entry: Vector2i in _entries(_field, _from, vertical_start):
		if _field.clear(_from, Vector2(_field.xs[entry.x], _field.ys[entry.y])):
			entries.append(entry)

	for exit: Vector2i in _entries(_field, _to, vertical_end):
		if _field.clear(Vector2(_field.xs[exit.x], _field.ys[exit.y]), _to):
			exits.append(exit)

	if entries.is_empty() or exits.is_empty():
		return PackedVector2Array()

	# one search seeded with every entry and stopped at any exit: running it once
	# per pair would allocate the whole cost table two dozen times per edge
	var best: PackedVector2Array = _astar(_field, entries, exits, _from, _to)

	if best.is_empty():
		return PackedVector2Array()

	var out: PackedVector2Array = PackedVector2Array([_from])

	for point: Vector2 in best:
		out.append(point)

	out.append(_to)

	return out


# the lattice vertices flanking an escape point on its own line
func _entries(_field: Field, _point: Vector2, _vertical: bool) -> Array[Vector2i]:
	var out: Array[Vector2i] = []

	if _vertical:
		var j: int = _field.nearest_y(_point.y)
		var i: int = _field.nearest_x(_point.x)

		for candidate: int in [i, i - 1, i + 1, i - 2, i + 2]:
			if candidate >= 0 and candidate < _field.xs.size():
				out.append(Vector2i(candidate, j))

		return out

	var column: int = _field.nearest_x(_point.x)
	var row: int = _field.nearest_y(_point.y)

	for candidate: int in [row, row - 1, row + 1, row - 2, row + 2]:
		if candidate >= 0 and candidate < _field.ys.size():
			out.append(Vector2i(column, candidate))

	return out


func _astar(
	_field: Field,
	_entries: Array[Vector2i],
	_exits: Array[Vector2i],
	_from: Vector2,
	_to: Vector2
) -> PackedVector2Array:
	var width: int = _field.xs.size()
	var height: int = _field.ys.size()

	_reset(width * height * 4)

	var goals: Dictionary = {}

	_heap_clear()

	for exit: Vector2i in _exits:
		goals[exit.y * width + exit.x] = Vector2(_field.xs[exit.x], _field.ys[exit.y]).distance_to(_to)

	for entry: Vector2i in _entries:
		var node: int = entry.y * width + entry.x
		var lead: float = _from.distance_to(Vector2(_field.xs[entry.x], _field.ys[entry.y]))

		for direction: int in range(4):
			var state: int = node * 4 + direction

			if lead >= _cost[state]:
				continue

			_cost[state] = lead
			_heap_push(
				lead + _estimate(_field.xs[entry.x] - _to.x, _field.ys[entry.y] - _to.y),
				state
			)

	var budget: int = EXPANSION_BUDGET

	while not _heap_state.is_empty():
		budget -= 1

		if budget <= 0:
			return PackedVector2Array()

		var current: int = _heap_pop()
		var node: int = current / 4
		var direction: int = current % 4

		if goals.has(node):
			return _rebuild(_field, current, width)

		var i: int = node % width
		var j: int = node / width
		var mask: int = _field.moves[node]

		for next_dir: int in range(4):
			if mask & (1 << next_dir) == 0:
				continue

			var ni: int = i + (1 if next_dir == 0 else (-1 if next_dir == 1 else 0))
			var nj: int = j + (1 if next_dir == 2 else (-1 if next_dir == 3 else 0))
			var length: float = absf(_field.xs[ni] - _field.xs[i]) + absf(_field.ys[nj] - _field.ys[j])
			var turn: float = 0.0 if next_dir == direction else TURN_COST
			var next_state: int = (nj * width + ni) * 4 + next_dir
			var candidate: float = _cost[current] + length + turn

			if candidate >= _cost[next_state]:
				continue

			_cost[next_state] = candidate
			_came[next_state] = current
			_heap_push(
				candidate + _estimate(_field.xs[ni] - _to.x, _field.ys[nj] - _to.y),
				next_state
			)

	return PackedVector2Array()


# manhattan plus the bend that reaching a target off both axes always costs, which
# is what keeps the search from behaving like dijkstra once turns are this dear
func _estimate(_dx: float, _dy: float) -> float:
	var turn: float = TURN_COST if absf(_dx) > 0.5 and absf(_dy) > 0.5 else 0.0

	return absf(_dx) + absf(_dy) + turn


# grown once per scope and refilled per edge: the table is the whole lattice
func _reset(_count: int) -> void:
	if _cost.size() < _count:
		_cost.resize(_count)
		_came.resize(_count)

	_cost.fill(INF)
	_came.fill(-1)




func _rebuild(_field: Field, _state: int, _width: int) -> PackedVector2Array:
	var reversed: Array[Vector2] = []
	var current: int = _state

	while current >= 0:
		var node: int = current / 4
		reversed.append(Vector2(_field.xs[node % _width], _field.ys[node / _width]))
		current = _came[current]

	var out: PackedVector2Array = PackedVector2Array()

	for index: int in range(reversed.size() - 1, -1, -1):
		out.append(reversed[index])

	return out


# drops the points that sit on a straight run, which the search leaves behind at
# every lattice line it crossed
func _simplify(_points: PackedVector2Array) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()

	for point: Vector2 in _points:
		if out.size() >= 2:
			var a: Vector2 = out[out.size() - 2]
			var b: Vector2 = out[out.size() - 1]

			if _collinear(a, b, point):
				out[out.size() - 1] = point
				continue

		if not out.is_empty() and out[out.size() - 1].distance_squared_to(point) < 0.01:
			continue

		out.append(point)

	return out


static func _collinear(_a: Vector2, _b: Vector2, _c: Vector2) -> bool:
	if absf(_a.x - _b.x) <= 0.01 and absf(_b.x - _c.x) <= 0.01:
		return true

	return absf(_a.y - _b.y) <= 0.01 and absf(_b.y - _c.y) <= 0.01


# --- binary heap ---

# two packed arrays instead of one array of pairs: a pair would allocate on every
# push, and a search pushes tens of thousands of them
func _heap_clear() -> void:
	_heap_priority.clear()
	_heap_state.clear()


func _heap_push(_priority: float, _state: int) -> void:
	_heap_priority.append(_priority)
	_heap_state.append(_state)

	var index: int = _heap_state.size() - 1

	while index > 0:
		var parent: int = (index - 1) / 2

		if _heap_priority[parent] <= _heap_priority[index]:
			break

		_heap_swap(parent, index)
		index = parent


func _heap_pop() -> int:
	var top: int = _heap_state[0]
	var last: int = _heap_state.size() - 1

	_heap_priority[0] = _heap_priority[last]
	_heap_state[0] = _heap_state[last]
	_heap_priority.resize(last)
	_heap_state.resize(last)

	var index: int = 0
	var size: int = last

	while true:
		var left: int = index * 2 + 1
		var right: int = left + 1
		var smallest: int = index

		if left < size and _heap_priority[left] < _heap_priority[smallest]:
			smallest = left

		if right < size and _heap_priority[right] < _heap_priority[smallest]:
			smallest = right

		if smallest == index:
			break

		_heap_swap(smallest, index)
		index = smallest

	return top


func _heap_swap(_a: int, _b: int) -> void:
	var priority: float = _heap_priority[_a]
	var state: int = _heap_state[_a]

	_heap_priority[_a] = _heap_priority[_b]
	_heap_state[_a] = _heap_state[_b]
	_heap_priority[_b] = priority
	_heap_state[_b] = state
