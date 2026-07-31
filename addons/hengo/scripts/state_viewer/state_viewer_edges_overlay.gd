@tool
class_name HenStateViewerEdgesOverlay
extends Node2D
# node2d on purpose: a control's own draw commands are culled by its rect,
# so arrows/pulses vanished whenever the graph origin left the screen

var graph_root: HenStateViewerGraphTypes.DirectedGraphNode

var _line_pool: Array[Line2D] = []
var _label_pool: Array[HenStateEdgePill] = []

var _active_node: HenStateViewerGraphTypes.DirectedGraphNode = null
var _hovered_edge: HenStateViewerGraphTypes.DirectedGraphEdge = null
var _edge_views: Array[Dictionary] = []
var _flashed_edges: Dictionary = {}

# keeps line/arrow width constant on screen: >1 when zoomed out so 2px lines
# don't shrink to sub-pixel and vanish
var _screen_scale: float = 1.0

const FORWARD_COLOR: Color = Color(0.64, 0.66, 0.72, 1.0)
const BACK_COLOR: Color = Color('#c9a35e')
const CROSS_COLOR: Color = Color('#c368ed')
const FLASH_COLOR: Color = Color('#63ff92')
const TRANSITION_COLOR: Color = Color('#f97316')
const CONDITION_COLOR: Color = Color('#38bdf8')
const CROSS_SCRIPT_COLOR: Color = Color('#c368ed')
const DIM_ALPHA: float = 0.2
const LABEL_CLEARANCE: float = 4.0
const SLIDE_STEP: float = 18.0
const SLIDE_TRIES: int = 8
const END_PAD: float = 24.0
const NORMAL_WIDTH: float = 2.0
const GLOW_WIDTH: float = 3.5
const FLASH_WIDTH: float = 4.5
const EDGE_CORNER_RADIUS: float = 14.0
const FLASH_TRAVEL_MS: float = 450.0
const FLASH_TOTAL_MS: float = 800.0
const PULSE_LEN: float = 90.0
const DASH_TEXTURE: Texture2D = preload('res://addons/hengo/assets/images/line_dashed.png')
const DASH_SHADER: Shader = preload('res://addons/hengo/assets/shaders/state_dash.gdshader')
const PILL_SCENE: PackedScene = preload('res://addons/hengo/scenes/state_edge_pill.tscn')


func _ready() -> void:
	# ensure process is running for hover detection
	set_process(true)


func get_hovered_edge() -> HenStateViewerGraphTypes.DirectedGraphEdge:
	return _hovered_edge


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
		queue_redraw()


func set_active_node(node: HenStateViewerGraphTypes.DirectedGraphNode) -> void:
	if _active_node != node:
		_active_node = node
		queue_redraw()


# stores edges and triggers redraw
func update_edges(root: HenStateViewerGraphTypes.DirectedGraphNode) -> void:
	graph_root = root
	_build_edge_views()
	queue_redraw()


# the transition type owns the color; the routing kind only tints edges without meta
func _kind_color(edge: HenStateViewerGraphTypes.DirectedGraphEdge) -> Color:
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


# resets pooled lines fully so no width/color/dash leaks between graph rebuilds
func _setup_line(line: Line2D, edge: HenStateViewerGraphTypes.DirectedGraphEdge) -> void:
	# lines render behind the overlay's own drawing so arrows and pulses stay on top
	line.show_behind_parent = true
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.antialiased = true
	line.texture = DASH_TEXTURE
	line.texture_mode = Line2D.LINE_TEXTURE_TILE
	line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	line.width = NORMAL_WIDTH
	line.default_color = _kind_color(edge)

	if line.material == null:
		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = DASH_SHADER
		line.material = mat

	(line.material as ShaderMaterial).set_shader_parameter('dash_amount', 0.0)


func _build_edge_views() -> void:
	if graph_root == null:
		return

	var path_util: HenStateViewerPathUtils = HenStateViewerPathUtils.new()
	var edges: Array[HenStateViewerGraphTypes.DirectedGraphEdge] = _get_all_edges(graph_root)

	var line_idx: int = 0
	var label_idx: int = 0
	var label_items: Array = []
	_edge_views.clear()

	for edge in edges:
		if edge.sections.is_empty():
			continue

		var section: Dictionary = edge.sections[0]
		var curve: Curve2D = path_util.round_path(section, EDGE_CORNER_RADIUS)
		var points: PackedVector2Array = curve.get_baked_points()

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
		var label_text: String = edge.label.text
		var lbl: HenStateEdgePill = null
		if not label_text.is_empty():
			var label_pos: Vector2 = section.label_pos if section.has('label_pos') \
				else (section.start_point + section.end_point) * 0.5

			var icon_name: String = str(edge.meta.get('icon', ''))
			var icon: Texture2D = HenActionRow.icon_texture(icon_name) if not icon_name.is_empty() else null
			var pill_size: Vector2 = HenStateEdgePill.measure(label_text, icon != null)
			var pill_rect: Rect2 = Rect2(label_pos - pill_size * 0.5, pill_size)

			if label_idx < _label_pool.size():
				lbl = _label_pool[label_idx]
			else:
				lbl = PILL_SCENE.instantiate()
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
			dash = 0.0,
			lengths = lengths,
			total_len = total_len,
			state_width = NORMAL_WIDTH
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


# places each pill on the nearest free slot along its own edge so labels never cover each other
func _resolve_label_overlaps(items: Array, obstacles: Array) -> void:
	items.sort_custom(func(a, b):
		if a.rect.position.y != b.rect.position.y:
			return a.rect.position.y < b.rect.position.y
		if a.rect.position.x != b.rect.position.x:
			return a.rect.position.x < b.rect.position.x
		return a.idx < b.idx
	)

	var placed: Array = []
	for it in items:
		var final_rect: Rect2 = it.rect
		if it.total_len >= END_PAD * 2.0:
			final_rect = _find_slot_on_edge(it, obstacles, placed)

		# fallback: still covered, push off the boxes and already-placed pills
		if _overlap_area(final_rect, obstacles) + _overlap_area(final_rect, placed) > 0.0:
			var push_item: Dictionary = {rect = final_rect}
			var blockers: Array = obstacles + placed
			for _i in range(4):
				if not _push_off_obstacles(push_item, blockers):
					break
			final_rect = push_item.rect

		it.label.position = final_rect.position
		placed.append(final_rect)


# slides along the edge polyline from the ideal anchor outward until a clear spot appears
func _find_slot_on_edge(item: Dictionary, obstacles: Array, placed: Array) -> Rect2:
	var rect: Rect2 = item.rect
	var s0: float = _closest_arc_length(item.points, item.lengths, rect.get_center())
	var best_rect: Rect2 = rect
	var best_score: float = INF

	for j in range(SLIDE_TRIES + 1):
		for k in ([0] if j == 0 else [j, -j]):
			var s: float = clampf(s0 + float(k) * SLIDE_STEP, END_PAD, item.total_len - END_PAD)
			var center: Vector2 = _point_at_length(item.points, item.lengths, s)
			var cand: Rect2 = Rect2(center - rect.size * 0.5, rect.size)
			var score: float = _overlap_area(cand, obstacles) + _overlap_area(cand, placed)
			if score <= 0.0:
				return cand
			if score < best_score:
				best_score = score
				best_rect = cand

	return best_rect


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
func _push_off_obstacles(item: Dictionary, obstacles: Array) -> bool:
	var rect: Rect2 = item.rect
	var best: Rect2 = rect
	var best_overlap: float = _overlap_area(rect, obstacles)
	var best_dist: float = 0.0

	if best_overlap <= 0.0:
		return false

	for obs: Rect2 in obstacles:
		if not rect.intersects(obs):
			continue

		for candidate: Rect2 in _escape_rects(rect, obs):
			var overlap: float = _overlap_area(candidate, obstacles)
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


func _overlap_area(rect: Rect2, obstacles: Array) -> float:
	var total: float = 0.0

	for obs: Rect2 in obstacles:
		var clip: Rect2 = rect.intersection(obs)
		total += clip.size.x * clip.size.y

	return total


# only leaf states block labels: edges between sub-states run inside their compound box
func _state_rects(node: HenStateViewerGraphTypes.DirectedGraphNode, result: Array = []) -> Array:
	if node.children.is_empty():
		result.append(Rect2(node.get_absolute(), Vector2(node.layout.width, node.layout.height)))
	else:
		for child in node.children:
			_state_rects(child, result)

	return result


# edges stay lit while the hovered node is their source or an ancestor of it
func _is_edge_dimmed(edge: HenStateViewerGraphTypes.DirectedGraphEdge) -> bool:
	if _active_node != null:
		return not _is_self_or_descendant(edge.source, _active_node)
	if _hovered_edge != null:
		return edge != _hovered_edge
	return false


func _is_self_or_descendant(node: HenStateViewerGraphTypes.DirectedGraphNode, ancestor: HenStateViewerGraphTypes.DirectedGraphNode) -> bool:
	var current: HenStateViewerGraphTypes.DirectedGraphNode = node
	while current != null:
		if current == ancestor:
			return true
		current = current.parent
	return false


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

	var mouse_pos: Vector2 = get_local_mouse_position()
	var closest_edge: HenStateViewerGraphTypes.DirectedGraphEdge = null

	# hover threshold in screen pixels, so zooming in doesn't make edges grab the mouse
	var cam: Node2D = get_parent() as Node2D
	var zoom: float = maxf(cam.transform.x.x, 0.001) if cam else 1.0
	var closest_dist: float = 15.0 / zoom

	for view in _edge_views:
		var dist: float = _point_to_polyline_dist(mouse_pos, view.points)
		if dist < closest_dist:
			closest_dist = dist
			closest_edge = view.edge

	var needs_redraw: bool = false

	# only boost below 100%: keeps arrows/pulses (own _draw) constant on screen and
	# forces a redraw while zooming since they don't self-redraw like the Line2Ds
	var screen_scale: float = maxf(1.0, 1.0 / zoom)
	if not is_equal_approx(screen_scale, _screen_scale):
		_screen_scale = screen_scale
		needs_redraw = true

	if _hovered_edge != closest_edge:
		_hovered_edge = closest_edge
		needs_redraw = true

	var current_time: int = Time.get_ticks_msec()

	for view in _edge_views:
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
		var current_alpha: float = view.line.default_color.a
		var alpha: float = lerpf(current_alpha, target_alpha, 15.0 * _delta)

		if abs(alpha - target_alpha) < 0.01:
			alpha = target_alpha
		else:
			needs_redraw = true

		var kc: Color = _kind_color(view.edge)
		var base_color: Color = kc.lightened(0.35) if is_glowing else kc
		var line_color: Color = base_color.lerp(FLASH_COLOR, flash_strength)
		line_color.a = alpha

		if view.line.default_color != line_color:
			view.line.default_color = line_color
			needs_redraw = true

		var base_width: float = GLOW_WIDTH if is_glowing else NORMAL_WIDTH
		var target_width: float = lerpf(base_width, FLASH_WIDTH, flash_strength)
		var new_state_width: float = lerpf(view.state_width, target_width, 15.0 * _delta)

		if abs(new_state_width - target_width) < 0.01:
			new_state_width = target_width
		else:
			needs_redraw = true

		view.state_width = new_state_width

		# lerp the state width, then apply the zoom factor as an instant multiplier
		# so the on-screen thickness tracks the cam without lagging its zoom animation
		var scaled_width: float = new_state_width * screen_scale
		if view.line.width != scaled_width:
			view.line.width = scaled_width

		# dash flows only on hover, never while a debug pulse runs
		var target_dash: float = 1.0 if (is_glowing and flash_strength <= 0.0) else 0.0
		var new_dash: float = lerpf(view.dash, target_dash, 10.0 * _delta)
		if abs(new_dash - target_dash) < 0.01:
			new_dash = target_dash
		if new_dash != view.dash:
			view.dash = new_dash
			(view.line.material as ShaderMaterial).set_shader_parameter('dash_amount', new_dash)

		if view.label != null and view.label.modulate.a != alpha:
			view.label.modulate.a = alpha

	if not _flashed_edges.is_empty():
		needs_redraw = true

	if needs_redraw:
		queue_redraw()


func _draw() -> void:
	var current_time: int = Time.get_ticks_msec()

	for view in _edge_views:
		if not view.has_arrow:
			continue

		var is_dimmed: bool = _is_edge_dimmed(view.edge)
		var is_glowing: bool = (view.edge == _hovered_edge) and not is_dimmed

		var flash_strength: float = 0.0
		var flash_elapsed: float = 0.0
		if _flashed_edges.has(view.edge):
			flash_elapsed = float(current_time - _flashed_edges[view.edge])
			flash_strength = _flash_strength(flash_elapsed)

		var kc: Color = _kind_color(view.edge)
		var color: Color = (kc.lightened(0.35) if is_glowing else kc).lerp(FLASH_COLOR, flash_strength)
		color.a = view.line.default_color.a

		# glow damp from the state width (not the zoomed line width), then scaled
		# on screen so the arrow head stays constant when zoomed out
		var s: float = (0.5 + 0.5 * (view.state_width / NORMAL_WIDTH)) * _screen_scale
		var end_pt: Vector2 = view.arrow_end
		var prev_pt: Vector2 = view.arrow_prev
		var dir: Vector2 = (end_pt - prev_pt).normalized()
		var arrow_base: Vector2 = end_pt - dir * (9.0 * s)
		var perp: Vector2 = Vector2(-dir.y, dir.x) * (5.0 * s)

		draw_polygon(PackedVector2Array([end_pt, arrow_base + perp, arrow_base - perp]),
			PackedColorArray([color]))

		if flash_strength > 0.0:
			_draw_pulse(view, flash_elapsed, flash_strength)


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
