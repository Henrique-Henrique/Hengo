@tool
class_name HenStateViewerEdgesOverlay
extends Node2D
# node2d on purpose: a control's own draw commands are culled by its rect,
# so arrows/pulses vanished whenever the graph origin left the screen

var graph_root: HenStateViewerGraphTypes.DirectedGraphNode

var _line_pool: Array[Line2D] = []
var _label_pool: Array[HenStateEdgePill] = []

var _hovered_edge: HenStateViewerGraphTypes.DirectedGraphEdge = null
var _edge_views: Array[Dictionary] = []
var _flashed_edges: Dictionary = {}

# keeps line/arrow width constant on screen: >1 when zoomed out so 2px lines
# don't shrink to sub-pixel and vanish
var _screen_scale: float = 1.0

# false once every line reached its target color and width
var _animating: bool = true
var _last_mouse_pos: Vector2 = Vector2.INF
var _last_hover_zoom: float = -1.0
var _last_view: Rect2 = Rect2()
var _applied_scale: float = 1.0
var _detail: int = Detail.FULL
var _lines_hidden: bool = false

enum Detail {FULL, COMPACT}

const FORWARD_COLOR: Color = Color(0.64, 0.66, 0.72, 1.0)
const BACK_COLOR: Color = Color('#c9a35e')
const CROSS_COLOR: Color = Color('#c368ed')
const FLASH_COLOR: Color = Color('#63ff92')
const TRANSITION_COLOR: Color = Color('#f97316')
const CONDITION_COLOR: Color = Color('#38bdf8')
const CROSS_SCRIPT_COLOR: Color = Color('#c368ed')
const DIM_ALPHA: float = 0.2
# routes are chrome, not content: at full strength they read louder than the states
const CANVAS_BG: Color = Color('#0f1116')
const LINE_MUTE: float = 0.42
const HOVER_SCREEN_PX: float = 15.0
const VIEW_MARGIN: float = 256.0
# segments per round joint and cap; the default 8 is a lot at 1400 lines
const ROUND_PRECISION: int = 3
const LABEL_CLEARANCE: float = 4.0
const SLIDE_STEP: float = 18.0
const SLIDE_TRIES: int = 8
const END_PAD: float = 24.0
const NORMAL_WIDTH: float = 2.0
const GLOW_WIDTH: float = 3.5
const FLASH_WIDTH: float = 4.5
# how much of the line's thickening the arrow head follows
const ARROW_GROWTH: float = 0.25
# lines need the full 1/zoom, an arrow at that rate becomes a huge triangle at min_zoom
const ARROW_ZOOM_DAMP: float = 0.5
const EDGE_CHAMFER: float = 14.0
const FLASH_TRAVEL_MS: float = 450.0
const FLASH_TOTAL_MS: float = 800.0
const PULSE_LEN: float = 90.0


func _ready() -> void:
	# ensure process is running for hover detection
	set_process(is_visible_in_tree())


# the other canvas tab hides this one, and hover kept running behind it
func _notification(what: int) -> void:
	if what != NOTIFICATION_VISIBILITY_CHANGED:
		return

	set_process(is_visible_in_tree())

	if not is_visible_in_tree() and _hovered_edge != null:
		_hovered_edge = null
		_animating = true
		queue_redraw()


func get_hovered_edge() -> HenStateViewerGraphTypes.DirectedGraphEdge:
	return _hovered_edge


# at compact zoom a pill is unreadable and an arrow head is a few pixels, so
# neither is worth drawing
func set_detail(_level: int) -> void:
	if _detail == _level:
		return

	_detail = _level
	_animating = true
	queue_redraw()


# far enough out the routes read as noise over the state names, and they are the
# heaviest thing left on screen
func set_lines_hidden(_hidden: bool) -> void:
	if _lines_hidden == _hidden:
		return

	_lines_hidden = _hidden

	if _hidden:
		_hovered_edge = null

		for view in _edge_views:
			(view.line as Line2D).visible = false

			if view.label != null:
				(view.label as HenStateEdgePill).visible = false

	_animating = true
	_last_view = Rect2()
	queue_redraw()


# matches by owning script, source state and event so same-named states across scripts never collide
func flash_edge(script_name: String, source: String, event: String) -> void:
	var target_edge: HenStateViewerGraphTypes.DirectedGraphEdge = null
	for view in _edge_views:
		var edge: HenStateViewerGraphTypes.DirectedGraphEdge = view.edge
		var id: String = edge.source.id
		var slices: int = id.get_slice_count('.')
		var source_short: String = id.get_slice('.', slices - 1)
		# edge.source.id is "collection.<script_name>.<state>..."
		var source_script: String = id.get_slice('.', 1) if slices > 1 else ''
		if source_script == script_name and source_short == source and edge.label.text == event:
			target_edge = edge
			break

	if target_edge:
		_flashed_edges[target_edge] = Time.get_ticks_msec()
		_animating = true
		queue_redraw()



# stores edges and triggers redraw
func update_edges(root: HenStateViewerGraphTypes.DirectedGraphNode) -> void:
	graph_root = root
	_build_edge_views()
	_animating = true
	_last_mouse_pos = Vector2.INF
	queue_redraw()


func _kind_color(edge: HenStateViewerGraphTypes.DirectedGraphEdge) -> Color:
	return _base_color(edge).lerp(CANVAS_BG, LINE_MUTE)


func _base_color(edge: HenStateViewerGraphTypes.DirectedGraphEdge) -> Color:
	var action_color: String = str(edge.meta.get('color', ''))

	if action_color.is_valid_html_color():
		return Color(action_color)

	match StringName(str(edge.meta.get('kind', ''))):
		&'cross_script':
			return CROSS_SCRIPT_COLOR
		&'condition':
			return CONDITION_COLOR
		&'transition':
			return TRANSITION_COLOR

	match edge.kind:
		&'cross':
			return CROSS_COLOR
		&'back':
			return BACK_COLOR
		_:
			return FORWARD_COLOR


# resets pooled lines fully so no width or color leaks between graph rebuilds. no
# material and no texture: every line shares one render state, which is what lets
# the renderer batch them, and hover reads from the color and the width alone
func _setup_line(line: Line2D, edge: HenStateViewerGraphTypes.DirectedGraphEdge) -> void:
	# lines render behind the overlay's own drawing so arrows and pulses stay on top
	line.show_behind_parent = true
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	# the fringe geometry it adds roughly doubles the vertices of every line
	line.antialiased = false
	line.round_precision = ROUND_PRECISION
	line.width = NORMAL_WIDTH
	line.default_color = _kind_color(edge)


func _build_edge_views() -> void:
	if graph_root == null:
		return

	var edges: Array[HenStateViewerGraphTypes.DirectedGraphEdge] = _get_all_edges(graph_root)

	var line_idx: int = 0
	var label_idx: int = 0
	var label_items: Array = []
	_edge_views.clear()

	for edge in edges:
		if edge.sections.is_empty():
			continue

		var section: Dictionary = edge.sections[0]
		# same 45 degree cut the node wires use, so both drawings read as one style
		var points: PackedVector2Array = HenFlowWires.chamfer(_sharp_points(section), EDGE_CHAMFER)

		var line: Line2D
		if line_idx < _line_pool.size():
			line = _line_pool[line_idx]
		else:
			line = Line2D.new()
			add_child(line)
			_line_pool.append(line)

		_setup_line(line, edge)
		line.points = points
		line_idx += 1

		# store everything needed for fast lookup and drawing
		var arrow_end: Vector2 = points[points.size() - 1] if points.size() >= 2 else Vector2.ZERO
		var arrow_prev: Vector2 = points[points.size() - 2] if points.size() >= 2 else Vector2.ZERO
		var has_arrow: bool = points.size() >= 2

		var lengths: PackedFloat32Array = PackedFloat32Array()
		lengths.resize(points.size())
		var total_len: float = 0.0
		for i in range(1, points.size()):
			total_len += points[i - 1].distance_to(points[i])
			lengths[i] = total_len

		# pill anchored at the route's ideal label point: transition type icon + name, tinted by the type
		var label_text: String = edge.display_label()
		var lbl: HenStateEdgePill = null
		if not label_text.is_empty():
			var label_pos: Vector2 = section.label_pos if section.has('label_pos') \
				else (section.start_point + section.end_point) * 0.5

			var icon_name: String = str(edge.meta.get('icon', ''))
			var icon: Texture2D = HenActionVisuals.icon_texture(icon_name) if not icon_name.is_empty() else null
			var pill_size: Vector2 = HenStateEdgePill.measure(label_text, icon != null)
			var pill_rect: Rect2 = Rect2(label_pos - pill_size * 0.5, pill_size)

			if label_idx < _label_pool.size():
				lbl = _label_pool[label_idx]
			else:
				lbl = HenStateEdgePill.new()
				add_child(lbl)
				_label_pool.append(lbl)

			lbl.setup(label_text, icon, _kind_color(edge))
			lbl.size = pill_rect.size
			label_idx += 1
			label_items.append({
				label = lbl,
				rect = pill_rect,
				points = points,
				lengths = lengths,
				total_len = total_len,
				idx = label_idx
			})

		_edge_views.append({
			edge = edge,
			points = points,
			line = line,
			label = lbl,
			has_arrow = has_arrow,
			arrow_end = arrow_end,
			arrow_prev = arrow_prev,
			lengths = lengths,
			total_len = total_len,
			state_width = NORMAL_WIDTH,
			alpha = 1.0,
			# the chamfered route is already a handful of points, and it is what is drawn
			hover_points = points,
			bounds = _bounds_of(points),
			# fixed per edge, and resolving it parses an html string
			color = _kind_color(edge)
		})

	while _line_pool.size() > line_idx:
		var unused_line: Line2D = _line_pool.pop_back()
		unused_line.queue_free()

	while _label_pool.size() > label_idx:
		var unused_lbl: HenStateEdgePill = _label_pool.pop_back()
		unused_lbl.queue_free()

	# drop flash entries whose edges no longer exist after a rebuild
	var valid_edges: Dictionary = {}
	for view in _edge_views:
		valid_edges[view.edge] = true
	for key in _flashed_edges.keys():
		if not valid_edges.has(key):
			_flashed_edges.erase(key)

	_resolve_label_overlaps(label_items, _state_rects(graph_root))


# the unrounded route, which the hover test uses: 4 to 8 points instead of the
# hundreds the bake produces, and it never strays more than a quarter of the
# corner radius from the drawn curve
func _sharp_points(section: Dictionary) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array([section.start_point])

	for bend: Vector2 in section.bend_points:
		pts.append(bend)

	pts.append(section.end_point)

	return pts


func _bounds_of(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()

	var rect: Rect2 = Rect2(points[0], Vector2.ZERO)

	for i: int in range(1, points.size()):
		rect = rect.expand(points[i])

	return rect


# places each pill on the nearest free slot along its own edge so labels never cover each other
func _resolve_label_overlaps(items: Array, obstacles: Array) -> void:
	items.sort_custom(func(a, b):
		if a.rect.position.y != b.rect.position.y:
			return a.rect.position.y < b.rect.position.y
		if a.rect.position.x != b.rect.position.x:
			return a.rect.position.x < b.rect.position.x
		return a.idx < b.idx
	)

	# a whole-collection graph has thousands of both, so neither is scanned linearly
	var blocked: RectGrid = RectGrid.new()

	for obs: Rect2 in obstacles:
		blocked.add(obs)

	for it in items:
		var final_rect: Rect2 = it.rect
		if it.total_len >= END_PAD * 2.0:
			final_rect = _find_slot_on_edge(it, blocked)

		# fallback: still covered, push off the boxes and already-placed pills
		if blocked.overlap_area(final_rect) > 0.0:
			var push_item: Dictionary = {rect = final_rect}
			for _i in range(4):
				if not _push_off_obstacles(push_item, blocked):
					break
			final_rect = push_item.rect

		it.label.position = final_rect.position
		blocked.add(final_rect)


# slides along the edge polyline from the ideal anchor outward until a clear spot appears
func _find_slot_on_edge(item: Dictionary, blocked: RectGrid) -> Rect2:
	var rect: Rect2 = item.rect
	var s0: float = _closest_arc_length(item.points, item.lengths, rect.get_center())
	var best_rect: Rect2 = rect
	var best_score: float = INF

	for j in range(SLIDE_TRIES + 1):
		for k in ([0] if j == 0 else [j, -j]):
			var s: float = clampf(s0 + float(k) * SLIDE_STEP, END_PAD, item.total_len - END_PAD)
			var center: Vector2 = _point_at_length(item.points, item.lengths, s)
			var cand: Rect2 = Rect2(center - rect.size * 0.5, rect.size)
			var score: float = blocked.overlap_area(cand)
			if score <= 0.0:
				return cand
			if score < best_score:
				best_score = score
				best_rect = cand

	return best_rect


# uniform bucket grid: a label only ever measures itself against what shares a cell
class RectGrid extends RefCounted:
	const CELL: float = 256.0

	var _rects: Array[Rect2] = []
	var _cells: Dictionary = {}


	func add(rect: Rect2) -> void:
		var index: int = _rects.size()
		_rects.append(rect)

		for key: Vector2i in _keys(rect):
			# array, not a packed one: packed arrays copy on read and the append
			# would land on a temporary
			if not _cells.has(key):
				_cells[key] = ([] as Array[int])

			(_cells[key] as Array[int]).append(index)


	func overlap_area(rect: Rect2) -> float:
		var total: float = 0.0

		for i: int in _candidates(rect):
			var clip: Rect2 = rect.intersection(_rects[i])
			total += clip.size.x * clip.size.y

		return total


	func intersecting(rect: Rect2) -> Array[Rect2]:
		var out: Array[Rect2] = []

		for i: int in _candidates(rect):
			if rect.intersects(_rects[i]):
				out.append(_rects[i])

		return out


	# a rect spanning several cells shows up once per cell, so hits are deduped
	func _candidates(rect: Rect2) -> Array[int]:
		var seen: Dictionary = {}
		var out: Array[int] = []

		for key: Vector2i in _keys(rect):
			for i: int in (_cells.get(key, []) as Array):
				if seen.has(i):
					continue

				seen[i] = true
				out.append(i)

		return out


	static func _keys(rect: Rect2) -> Array[Vector2i]:
		var out: Array[Vector2i] = []
		var from: Vector2i = Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
		var to: Vector2i = Vector2i(
			floori((rect.position.x + rect.size.x) / CELL),
			floori((rect.position.y + rect.size.y) / CELL)
		)

		for x: int in range(from.x, to.x + 1):
			for y: int in range(from.y, to.y + 1):
				out.append(Vector2i(x, y))

		return out


# arc length along the polyline of the point closest to p
func _closest_arc_length(points: PackedVector2Array, lengths: PackedFloat32Array, p: Vector2) -> float:
	var best_len: float = 0.0
	var best_dist: float = INF
	for i in range(points.size() - 1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var l2: float = a.distance_squared_to(b)
		var t: float = 0.0
		if l2 > 0.0:
			t = clampf((p - a).dot(b - a) / l2, 0.0, 1.0)
		var d: float = p.distance_squared_to(a.lerp(b, t))
		if d < best_dist:
			best_dist = d
			best_len = lengths[i] + sqrt(l2) * t
	return best_len


# slides a pill off the state boxes; every exit is scored against all of them, so a
# pill sandwiched between two boxes leaves sideways instead of bouncing between them
func _push_off_obstacles(item: Dictionary, blocked: RectGrid) -> bool:
	var rect: Rect2 = item.rect
	var best: Rect2 = rect
	var best_overlap: float = blocked.overlap_area(rect)
	var best_dist: float = 0.0

	if best_overlap <= 0.0:
		return false

	for obs: Rect2 in blocked.intersecting(rect):
		for candidate: Rect2 in _escape_rects(rect, obs):
			var overlap: float = blocked.overlap_area(candidate)
			var dist: float = candidate.position.distance_squared_to(rect.position)

			if overlap < best_overlap or (overlap == best_overlap and dist < best_dist):
				best = candidate
				best_overlap = overlap
				best_dist = dist

	if best.position == rect.position:
		return false

	item.rect = best

	return true


# the four ways out of a box, each clearing it by LABEL_CLEARANCE
func _escape_rects(rect: Rect2, obs: Rect2) -> Array:
	return [
		Rect2(Vector2(rect.position.x, obs.position.y - rect.size.y - LABEL_CLEARANCE), rect.size),
		Rect2(Vector2(rect.position.x, obs.position.y + obs.size.y + LABEL_CLEARANCE), rect.size),
		Rect2(Vector2(obs.position.x - rect.size.x - LABEL_CLEARANCE, rect.position.y), rect.size),
		Rect2(Vector2(obs.position.x + obs.size.x + LABEL_CLEARANCE, rect.position.y), rect.size)
	]


# only leaf states block labels: edges between sub-states run inside their compound box
func _state_rects(node: HenStateViewerGraphTypes.DirectedGraphNode, result: Array = []) -> Array:
	if node.children.is_empty():
		result.append(Rect2(node.get_absolute(), Vector2(node.layout.width, node.layout.height)))
	else:
		for child in node.children:
			_state_rects(child, result)

	return result


# only a hovered route lights anything: a route is a question about two states
func _is_edge_dimmed(edge: HenStateViewerGraphTypes.DirectedGraphEdge) -> bool:
	return _hovered_edge != null and edge != _hovered_edge



# fades from full strength to zero after the pulse finishes traveling
func _flash_strength(elapsed: float) -> float:
	if elapsed >= FLASH_TOTAL_MS:
		return 0.0
	if elapsed <= FLASH_TRAVEL_MS:
		return 1.0
	var t: float = (elapsed - FLASH_TRAVEL_MS) / (FLASH_TOTAL_MS - FLASH_TRAVEL_MS)
	return 1.0 - t * t


func _process(_delta: float) -> void:
	if _edge_views.is_empty():
		return

	var cam: Node2D = get_parent() as Node2D
	var zoom: float = maxf(cam.transform.x.x, 0.001) if cam else 1.0
	var mouse_pos: Vector2 = get_local_mouse_position()
	var needs_redraw: bool = false

	# panning moves the local mouse too, so this covers cam movement as well
	if not _lines_hidden and (mouse_pos != _last_mouse_pos or not is_equal_approx(zoom, _last_hover_zoom)):
		_last_mouse_pos = mouse_pos
		_last_hover_zoom = zoom

		var hovered: HenStateViewerGraphTypes.DirectedGraphEdge = _pick_edge(mouse_pos, zoom)

		if _hovered_edge != hovered:
			_hovered_edge = hovered
			_animating = true
			needs_redraw = true

	# only boost below 100%: keeps arrows/pulses (own _draw) constant on screen and
	# forces a redraw while zooming since they don't self-redraw like the Line2Ds
	var screen_scale: float = maxf(1.0, 1.0 / zoom)
	var scale_settled: bool = is_equal_approx(screen_scale, _screen_scale)

	if not scale_settled:
		_screen_scale = screen_scale
		_animating = true
		needs_redraw = true

	# the zoom stopped moving, so the line widths can take the new factor now
	if scale_settled and not is_equal_approx(_applied_scale, screen_scale):
		_applied_scale = screen_scale
		_animating = true

	# an edge that scrolls in was skipped while offscreen, so it still has to catch up
	var current_view: Rect2 = _visible_rect()
	if current_view != _last_view:
		_last_view = current_view
		_animating = true
		needs_redraw = true

	# nothing on screen to animate, and the lines already went invisible in one pass
	if _lines_hidden:
		_animating = false
		return

	if not _animating:
		return

	# lerp weights above 1 overshoot the target and ring instead of settling, which
	# is what a heavy frame does to a rate written for 60fps
	var alpha_step: float = minf(1.0, 15.0 * _delta)

	var settled: bool = true
	var current_time: int = Time.get_ticks_msec()
	var view_rect: Rect2 = _visible_rect()

	for view in _edge_views:
		var line: Line2D = view.line

		if not view_rect.intersects(view.bounds):
			if line.visible:
				line.visible = false

				if view.label != null:
					(view.label as HenStateEdgePill).visible = false

			continue

		if not line.visible:
			line.visible = true

		if view.label != null:
			(view.label as HenStateEdgePill).visible = _detail == Detail.FULL

		var is_dimmed: bool = _is_edge_dimmed(view.edge)

		var flash_strength: float = 0.0
		if _flashed_edges.has(view.edge):
			var elapsed: float = float(current_time - _flashed_edges[view.edge])
			flash_strength = _flash_strength(elapsed)
			if flash_strength <= 0.0:
				_flashed_edges.erase(view.edge)

		if flash_strength > 0.0:
			is_dimmed = false

		var is_glowing: bool = (view.edge == _hovered_edge) and not is_dimmed

		var target_alpha: float = DIM_ALPHA if is_dimmed else 1.0
		var alpha: float = lerpf(view.alpha, target_alpha, alpha_step)

		if abs(alpha - target_alpha) < 0.01:
			alpha = target_alpha
		else:
			needs_redraw = true
			settled = false

		view.alpha = alpha

		# alpha rides modulate, which is a shader-side tint: writing it into
		# default_color would retessellate the line every single frame
		if not is_equal_approx(line.modulate.a, alpha):
			line.modulate.a = alpha
			needs_redraw = true

		var kc: Color = view.color
		var base_color: Color = kc.lightened(0.35) if is_glowing else kc
		var line_color: Color = base_color.lerp(FLASH_COLOR, flash_strength)
		line_color.a = 1.0

		if line.default_color != line_color:
			line.default_color = line_color
			needs_redraw = true

		var base_width: float = GLOW_WIDTH if is_glowing else NORMAL_WIDTH
		var target_width: float = lerpf(base_width, FLASH_WIDTH, flash_strength)
		var new_state_width: float = lerpf(view.state_width, target_width, alpha_step)

		if abs(new_state_width - target_width) < 0.01:
			new_state_width = target_width
		else:
			needs_redraw = true
			settled = false

		view.state_width = new_state_width

		# width does retessellate, so the zoom factor is only folded in once the cam
		# settles: mid-animation every visible line would rebuild its mesh per frame
		var scaled_width: float = new_state_width * _applied_scale
		if line.width != scaled_width:
			line.width = scaled_width

		if view.label != null and view.label.modulate.a != alpha:
			view.label.modulate.a = alpha

	if not _flashed_edges.is_empty():
		needs_redraw = true
		settled = false

	_animating = not settled

	if needs_redraw:
		queue_redraw()


func _draw() -> void:
	if _lines_hidden:
		return

	if _detail == Detail.COMPACT and _flashed_edges.is_empty():
		return

	var current_time: int = Time.get_ticks_msec()
	var view_rect: Rect2 = _visible_rect()

	for view in _edge_views:
		if not view.has_arrow or not view_rect.intersects(view.bounds):
			continue

		var is_dimmed: bool = _is_edge_dimmed(view.edge)
		var is_glowing: bool = (view.edge == _hovered_edge) and not is_dimmed

		var flash_strength: float = 0.0
		var flash_elapsed: float = 0.0
		if _flashed_edges.has(view.edge):
			flash_elapsed = float(current_time - _flashed_edges[view.edge])
			flash_strength = _flash_strength(flash_elapsed)

		var kc: Color = view.color
		var color: Color = (kc.lightened(0.35) if is_glowing else kc).lerp(FLASH_COLOR, flash_strength)
		color.a = view.alpha

		var growth: float = 1.0 - ARROW_GROWTH + ARROW_GROWTH * (view.state_width / NORMAL_WIDTH)
		var s: float = growth * pow(_screen_scale, ARROW_ZOOM_DAMP)
		var end_pt: Vector2 = view.arrow_end
		var prev_pt: Vector2 = view.arrow_prev
		var dir: Vector2 = (end_pt - prev_pt).normalized()
		var arrow_base: Vector2 = end_pt - dir * (9.0 * s)
		var perp: Vector2 = Vector2(-dir.y, dir.x) * (5.0 * s)

		draw_polygon(PackedVector2Array([end_pt, arrow_base + perp, arrow_base - perp]),
			PackedColorArray([color]))

		if flash_strength > 0.0:
			_draw_pulse(view, flash_elapsed, flash_strength)


# what the cam shows, in this node's space; a whole collection has far more edges
# offscreen than on, and none of them need animating or drawing
func _visible_rect() -> Rect2:
	var cam: HenCam = get_parent() as HenCam

	if not cam:
		return Rect2(Vector2(-1e9, -1e9), Vector2(2e9, 2e9))

	return cam.get_rect().grow(VIEW_MARGIN)


# threshold in screen pixels, so zooming in doesn't make edges grab the mouse
func _pick_edge(mouse_pos: Vector2, zoom: float) -> HenStateViewerGraphTypes.DirectedGraphEdge:
	var threshold: float = HOVER_SCREEN_PX / zoom
	var closest_dist: float = threshold
	var closest: HenStateViewerGraphTypes.DirectedGraphEdge = null

	for view in _edge_views:
		if not (view.bounds as Rect2).grow(threshold).has_point(mouse_pos):
			continue

		var dist: float = _point_to_polyline_dist(mouse_pos, view.hover_points)

		if dist < closest_dist:
			closest_dist = dist
			closest = view.edge

	return closest


# draws a bright segment traveling along the edge during a debug flash
func _draw_pulse(view: Dictionary, elapsed: float, strength: float) -> void:
	var total_len: float = view.total_len
	if total_len <= 0.0:
		return

	var t: float = clampf(elapsed / FLASH_TRAVEL_MS, 0.0, 1.0)
	t = 1.0 - (1.0 - t) * (1.0 - t)

	var head: float = t * total_len
	var tail: float = maxf(head - PULSE_LEN, 0.0)
	var sub_pts: PackedVector2Array = _sub_polyline(view.points, view.lengths, tail, head)
	if sub_pts.size() < 2:
		return

	var pulse_color: Color = FLASH_COLOR.lightened(0.3)
	pulse_color.a = strength
	var pulse_w: float = view.line.width + 2.5 * _screen_scale

	draw_polyline(sub_pts, pulse_color, pulse_w, true)
	draw_circle(sub_pts[sub_pts.size() - 1], pulse_w * 0.6, pulse_color)


# extracts the polyline slice between two arc-length offsets
func _sub_polyline(points: PackedVector2Array, lengths: PackedFloat32Array, from_len: float, to_len: float) -> PackedVector2Array:
	var result: PackedVector2Array = PackedVector2Array()
	if points.size() < 2 or to_len <= from_len:
		return result

	result.append(_point_at_length(points, lengths, from_len))
	for i in range(points.size()):
		if lengths[i] > from_len and lengths[i] < to_len:
			result.append(points[i])
	result.append(_point_at_length(points, lengths, to_len))
	return result


# interpolates the polyline point at a given arc length
func _point_at_length(points: PackedVector2Array, lengths: PackedFloat32Array, at: float) -> Vector2:
	if at <= 0.0:
		return points[0]
	for i in range(1, points.size()):
		if lengths[i] >= at:
			var seg_len: float = lengths[i] - lengths[i - 1]
			if seg_len <= 0.0:
				return points[i]
			var t: float = (at - lengths[i - 1]) / seg_len
			return points[i - 1].lerp(points[i], t)
	return points[points.size() - 1]


# collects all edges recursively from tree
func _get_all_edges(node: HenStateViewerGraphTypes.DirectedGraphNode, result: Array[HenStateViewerGraphTypes.DirectedGraphEdge] = []) -> Array[HenStateViewerGraphTypes.DirectedGraphEdge]:
	result.append_array(node.edges)
	for child in node.children:
		_get_all_edges(child, result)
	return result


# finds distance from p to polyline
func _point_to_polyline_dist(p: Vector2, poly: PackedVector2Array) -> float:
	var min_dist: float = INF
	for i in range(poly.size() - 1):
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[i + 1]
		var seg_dist: float = _dist_to_segment(p, a, b)
		if seg_dist < min_dist:
			min_dist = seg_dist
	return min_dist


# generic pt-segment distance
func _dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var l2: float = a.distance_squared_to(b)
	if l2 == 0.0:
		return p.distance_to(a)
	var t: float = max(0.0, min(1.0, (p - a).dot(b - a) / l2))
	var projection: Vector2 = a + t * (b - a)
	return p.distance_to(projection)
