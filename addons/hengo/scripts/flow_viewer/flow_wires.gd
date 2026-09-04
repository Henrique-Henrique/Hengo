@tool
class_name HenFlowWires
extends Node2D

# every wire of one state, in a single canvas item. the routes only change when
# the layout does, so the command list is built once and cached; hover dimming
# rides modulate and never rebuilds geometry

const CHAMFER: float = 9.0
const STUB: float = 14.0
const LANE_STEP: float = 10.0
const TRUNK_GAP: float = 18.0
const DETOUR: float = 40.0
const WIDTH: float = 2.0
const CASING_WIDTH: float = 5.0
const CASING_COLOR: Color = Color('#080b0a')
const EXEC_COLOR: Color = Color('#e6ebf2')
const SOLDER_RADIUS: float = 3.4
const ARROW: float = 6.0
const SCALE_STEP: float = 0.25
# past this the casing is fatter than the chamfer it turns on
const MAX_SCREEN_SCALE: float = 2.5

var _wires: Array[Dictionary] = []
var _solders: Array[Dictionary] = []
var _arrows: Array[Dictionary] = []
var _lanes: Array[Dictionary] = []
var _bands: PackedFloat32Array = PackedFloat32Array()
var _screen_scale: float = 1.0


# below 100% the colour pass falls under a pixel while the casing is still wide,
# and the wire reads as black. the widths are applied at draw time, so holding
# them constant on screen only costs a redraw, never a reroute
func set_screen_scale(_scale: float) -> void:
	# quantised so a zoom sweep redraws a handful of times instead of every frame
	var stepped: float = clampf(snappedf(_scale, SCALE_STEP), 1.0, MAX_SCREEN_SCALE)

	if is_equal_approx(stepped, _screen_scale):
		return

	_screen_scale = stepped

	queue_redraw()


func build(_graph: HenFlowGraphTypes.FlowGraph) -> void:
	_wires.clear()
	_solders.clear()
	_arrows.clear()
	_lanes.clear()
	_bands.clear()

	if _graph:
		_lanes.assign(_graph.lanes)
		_bands = _graph.bands
		_route_data(_graph)
		_route_exec(_graph)

	queue_redraw()


func wire_count() -> int:
	return _wires.size()


func solder_count() -> int:
	return _solders.size()


# a pin rect is local to its node, so the anchor is the node origin plus its centre
static func anchor(_node: HenFlowGraphTypes.FlowNode, _pin: HenFlowGraphTypes.FlowPin) -> Vector2:
	return _node.position + _pin.rect.get_center()


func _route_exec(_graph: HenFlowGraphTypes.FlowGraph) -> void:
	var routed: Array[Dictionary] = []
	var by_node: Dictionary = {}

	for edge: HenFlowGraphTypes.FlowEdge in _graph.edges_of(&'exec'):
		var from: HenFlowGraphTypes.FlowPin = edge.from_node.pin(edge.from_pin)
		var to: HenFlowGraphTypes.FlowPin = edge.to_node.pin(edge.to_pin)

		if not from or not to:
			continue

		var entry: Dictionary = {
			edge = edge,
			a = anchor(edge.from_node, from),
			b = anchor(edge.to_node, to),
			order = routed.size(),
			slot = 0
		}

		routed.append(entry)

		if not by_node.has(edge.from_node):
			by_node[edge.from_node] = []

		(by_node[edge.from_node] as Array).append(entry)

	for group: Array in by_node.values():
		_assign_slots(group)

	for entry: Dictionary in routed:
		var edge: HenFlowGraphTypes.FlowEdge = entry.edge
		var color: Color = _exec_color(edge)

		_wires.append({
			points = chamfer(_exec_path(entry.a, entry.b, entry.slot)),
			color = color,
			from = edge.from_node,
			to = edge.to_node
		})
		_arrows.append({at = entry.b, color = color})


# siblings leaving one node share the strip under it, so each gets its own depth:
# the farthest target turns first and the runs nest instead of overlapping
static func _assign_slots(_group: Array) -> void:
	if _group.size() < 2:
		return

	# sort_custom is unstable, and two branches can sit at the same distance
	_group.sort_custom(func(_x: Dictionary, _y: Dictionary) -> bool:
		var dist_x: float = absf((_x.b as Vector2).x - (_x.a as Vector2).x)
		var dist_y: float = absf((_y.b as Vector2).x - (_y.a as Vector2).x)

		return dist_x > dist_y if not is_equal_approx(dist_x, dist_y) else _x.order < _y.order
	)

	for i: int in range(_group.size()):
		_group[i].slot = i


# a wire wears the colour its cell label already wears: phase colours on the
# entry, verdict colours on true and false; the rest of a chain keeps the phase
func _exec_color(_edge: HenFlowGraphTypes.FlowEdge) -> Color:
	if _edge.from_node.kind == &'state_entry':
		return HenActionVisuals.phase_color(_edge.from_pin)

	var pin: HenFlowGraphTypes.FlowPin = _edge.from_node.pin(_edge.from_pin)
	var carried: Color = _phase_tint(_edge.from_node.phase)

	return HenActionVisuals.branch_color(pin.id, pin.label, carried) if pin else carried


# phase_color answers an unknown phase with the update colour
static func _phase_tint(_phase: StringName) -> Color:
	if HenActionVisuals.PHASE_COLORS.has(str(_phase)):
		return HenActionVisuals.phase_color(_phase)

	return EXEC_COLOR


# execution leaves downward and arrives downward, so a target that sits above has
# to be reached around the side instead of straight up through the node
func _exec_path(_a: Vector2, _b: Vector2, _slot: int = 0) -> PackedVector2Array:
	if absf(_a.x - _b.x) < 0.5:
		return PackedVector2Array([_a, _b])

	if _b.y > _a.y + STUB * 2.0:
		# turning right at a fixed stub cuts through whatever the step it leaves
		# hangs beside its action, a branch transition above all
		var mid: float = _band_between(_a.y, _b.y, _slot)

		return PackedVector2Array([_a, Vector2(_a.x, mid), Vector2(_b.x, mid), _b])

	# a target barely below is reached through the middle of its own gap: the side
	# detour would overshoot it and fold back over its top edge
	if _b.y > _a.y:
		var mid: float = (_a.y + _b.y) * 0.5

		return PackedVector2Array([_a, Vector2(_a.x, mid), Vector2(_b.x, mid), _b])

	var lane: Dictionary = _lane_between(_a.x, _b.x)

	# guessing the midpoint puts the run wherever the two nodes happen to sit, and
	# a step centred in its column moves that guess onto its neighbour
	if not lane.is_empty():
		return PackedVector2Array([
			_a,
			Vector2(_a.x, lane.exit_y),
			Vector2(lane.x, lane.exit_y),
			Vector2(lane.x, lane.entry_y),
			Vector2(_b.x, lane.entry_y),
			_b
		])

	var side: float = maxf(_a.x, _b.x) + DETOUR

	return PackedVector2Array([
		_a,
		Vector2(_a.x, _a.y + STUB),
		Vector2(side, _a.y + STUB),
		Vector2(side, _b.y - STUB),
		Vector2(_b.x, _b.y - STUB),
		_b
	])


# the free strip under the step the wire leaves, or the plain stub when the run
# is not part of a chain the formatter measured
func _band_between(_from: float, _to: float, _slot: int = 0) -> float:
	# the last strip before the target, not the first after the source: turning
	# early leaves the wire alongside whatever the source step still occupies
	for i: int in range(_bands.size() - 1, -1, -1):
		if _bands[i] > _from and _bands[i] < _to:
			# siblings sharing one band sink a step into its strip; deeper than
			# that would touch the step below or overshoot a close target
			var sunk: float = _bands[i] + LANE_STEP * minf(float(_slot), 1.0)

			return sunk if sunk < _to - STUB else _bands[i]

	return clampf(_from + STUB + LANE_STEP * float(_slot), _from + STUB, _to - STUB)


# the lane the two ends actually straddle, nearest to where the wire leaves
func _lane_between(_from: float, _to: float) -> Dictionary:
	var low: float = minf(_from, _to)
	var high: float = maxf(_from, _to)
	var best: Dictionary = {}
	var closest: float = INF

	for lane: Dictionary in _lanes:
		if lane.x <= low or lane.x >= high:
			continue

		if absf(lane.x - _from) < closest:
			closest = absf(lane.x - _from)
			best = lane

	return best


# one output feeding several inputs shares a trunk: the overlapping runs coincide,
# and the junction gets the solder dot that says connected instead of crossing
func _route_data(_graph: HenFlowGraphTypes.FlowGraph) -> void:
	var groups: Dictionary = {}

	for edge: HenFlowGraphTypes.FlowEdge in _graph.edges_of(&'data'):
		var key: String = str(edge.from_node.id) + '|' + str(edge.from_pin)

		if not groups.has(key):
			groups[key] = []

		(groups[key] as Array).append(edge)

	for key: Variant in groups:
		var edges: Array = groups[key]
		var first: HenFlowGraphTypes.FlowEdge = edges[0]
		var out_pin: HenFlowGraphTypes.FlowPin = first.from_node.pin(first.from_pin)

		if not out_pin:
			continue

		var a: Vector2 = anchor(first.from_node, out_pin)
		var color: Color = _data_color(first)
		var targets: Array[Vector2] = []

		for edge: HenFlowGraphTypes.FlowEdge in edges:
			var in_pin: HenFlowGraphTypes.FlowPin = edge.to_node.pin(edge.to_pin)

			if in_pin:
				targets.append(anchor(edge.to_node, in_pin))

		if targets.is_empty():
			continue

		var trunk: float = _trunk_x(first.from_node, edges, a.x)

		for index: int in range(targets.size()):
			var point: Vector2 = targets[index]

			_wires.append({
				points = chamfer(PackedVector2Array([a, Vector2(trunk, a.y), Vector2(trunk, point.y), point])),
				color = color,
				from = first.from_node,
				to = (edges[index] as HenFlowGraphTypes.FlowEdge).to_node
			})

			if targets.size() > 1:
				_solders.append({at = Vector2(trunk, point.y), color = color})


# the middle of the gap the formatter leaves between a producer and what it feeds.
# aiming at the consumer's slot instead lands on the card, because a slot is drawn
# inside it now, and can even put the trunk right of the producer and fold the
# wire back on itself
func _trunk_x(_from: HenFlowGraphTypes.FlowNode, _edges: Array, _out_x: float) -> float:
	var producer_right: float = _from.position.x + _from.size.x
	var consumer_left: float = INF

	for edge: HenFlowGraphTypes.FlowEdge in _edges:
		consumer_left = minf(consumer_left, edge.to_node.position.x)

	if producer_right < consumer_left:
		return (producer_right + consumer_left) * 0.5

	# the layout put them the other way around, so the wire only clears the producer
	return maxf(_out_x + STUB, consumer_left - TRUNK_GAP)


func _data_color(_edge: HenFlowGraphTypes.FlowEdge) -> Color:
	var accent: String = _edge.from_node.accent

	return Color(accent) if accent.is_valid_html_color() else Color(HenActionVisuals.FALLBACK_COLOR)


# every corner is cut back by half the shorter neighbour, capped at the radius.
# one radius across every wire is what makes the drawing read as one piece
static func chamfer(_points: PackedVector2Array, _radius: float = CHAMFER) -> PackedVector2Array:
	if _points.size() < 3:
		return _points

	var out: PackedVector2Array = PackedVector2Array([_points[0]])

	for i: int in range(1, _points.size() - 1):
		var previous: Vector2 = _points[i - 1]
		var current: Vector2 = _points[i]
		var next: Vector2 = _points[i + 1]
		var back: float = previous.distance_to(current)
		var ahead: float = current.distance_to(next)

		if back <= 0.0 or ahead <= 0.0:
			continue

		var cut: float = minf(_radius, minf(back * 0.5, ahead * 0.5))

		out.append(current + (previous - current).normalized() * cut)
		out.append(current + (next - current).normalized() * cut)

	out.append(_points[_points.size() - 1])

	return out


# casings first, then colours: a casing drawn later would cut a hole in the colour
# of a wire drawn earlier, and the gap would land on whichever crossed first
func _draw() -> void:
	for wire: Dictionary in _wires:
		if (wire.points as PackedVector2Array).size() >= 2:
			draw_polyline(wire.points, CASING_COLOR, CASING_WIDTH * _screen_scale)

	for wire: Dictionary in _wires:
		if (wire.points as PackedVector2Array).size() >= 2:
			draw_polyline(wire.points, wire.color, WIDTH * _screen_scale)

	for solder: Dictionary in _solders:
		draw_circle(solder.at, SOLDER_RADIUS * _screen_scale, solder.color)

	# damped: at the full rate the head becomes a huge triangle at minimum zoom
	var head: float = ARROW * pow(_screen_scale, 0.5)

	for arrow: Dictionary in _arrows:
		var at: Vector2 = arrow.at

		draw_polygon(
			PackedVector2Array([
				at,
				at + Vector2(-head * 0.7, -head),
				at + Vector2(head * 0.7, -head)
			]),
			PackedColorArray([arrow.color])
		)
