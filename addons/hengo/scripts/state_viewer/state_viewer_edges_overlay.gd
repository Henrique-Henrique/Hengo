@tool
class_name HenStateViewerEdgesOverlay
extends Node2D
# node2d on purpose: a control's own draw commands are culled by its rect,
# so arrows/pulses vanished whenever the graph origin left the screen

var graph_root: HenStateViewerGraphTypes.DirectedGraphNode

var _line_pool: Array[Line2D] = []
var _label_pool: Array[Label] = []

var _active_node: HenStateViewerGraphTypes.DirectedGraphNode = null
var _hovered_edge: HenStateViewerGraphTypes.DirectedGraphEdge = null
var _edge_views: Array[Dictionary] = []
var _flashed_edges: Dictionary = {}

const FORWARD_COLOR: Color = Color(0.64, 0.66, 0.72, 1.0)
const BACK_COLOR: Color = Color('#c9a35e')
const CROSS_COLOR: Color = Color('#c368ed')
const FLASH_COLOR: Color = Color('#63ff92')
const PILL_BG: Color = Color(0.13, 0.13, 0.16, 0.95)
const LABEL_COLOR: Color = Color(0.9, 0.9, 0.9, 1.0)
const DIM_ALPHA: float = 0.2
const NORMAL_WIDTH: float = 2.0
const GLOW_WIDTH: float = 3.5
const FLASH_WIDTH: float = 4.5
const EDGE_CORNER_RADIUS: float = 14.0
const FLASH_TRAVEL_MS: float = 450.0
const FLASH_TOTAL_MS: float = 800.0
const PULSE_LEN: float = 90.0
const DASH_TEXTURE: Texture2D = preload('res://addons/hengo/assets/images/line_dashed.png')
const DASH_SHADER: Shader = preload('res://addons/hengo/assets/shaders/state_dash.gdshader')


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


# maps each edge kind to its base color
func _kind_color(edge: HenStateViewerGraphTypes.DirectedGraphEdge) -> Color:
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

	var font: Font = ThemeDB.fallback_font
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

		# pill label at midpoint
		var label_text: String = edge.label.text
		var lbl: Label = null
		if not label_text.is_empty():
			var label_pos: Vector2 = section.label_pos if section.has('label_pos') \
				else (section.start_point + section.end_point) * 0.5

			var font_size_pill: int = 14
			var text_size: Vector2 = font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_pill)
			var pad_x: float = 8.0
			var pad_y: float = 3.0
			var pill_w: float = text_size.x + pad_x * 2.0
			var pill_h: float = text_size.y + pad_y * 2.0
			var pill_rect: Rect2 = Rect2(label_pos - Vector2(pill_w * 0.5, pill_h * 0.5), Vector2(pill_w, pill_h))

			var kc: Color = _kind_color(edge)
			var style: StyleBoxFlat = StyleBoxFlat.new()
			style.bg_color = PILL_BG
			style.border_color = Color(kc.r, kc.g, kc.b, 0.55)
			style.set_border_width_all(1)
			style.corner_radius_top_left = 8
			style.corner_radius_top_right = 8
			style.corner_radius_bottom_left = 8
			style.corner_radius_bottom_right = 8

			if label_idx < _label_pool.size():
				lbl = _label_pool[label_idx]
			else:
				lbl = Label.new()
				lbl.add_theme_font_size_override('font_size', font_size_pill)
				lbl.add_theme_color_override('font_color', LABEL_COLOR)
				lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				add_child(lbl)
				_label_pool.append(lbl)

			lbl.text = label_text
			lbl.add_theme_stylebox_override('normal', style)
			lbl.size = pill_rect.size
			label_idx += 1
			label_items.append({label = lbl, rect = pill_rect})

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
			total_len = total_len
		})

	while _line_pool.size() > line_idx:
		var unused_line: Line2D = _line_pool.pop_back()
		unused_line.queue_free()

	while _label_pool.size() > label_idx:
		var unused_lbl: Label = _label_pool.pop_back()
		unused_lbl.queue_free()

	# drop flash entries whose edges no longer exist after a rebuild
	var valid_edges: Dictionary = {}
	for view in _edge_views:
		valid_edges[view.edge] = true
	for key in _flashed_edges.keys():
		if not valid_edges.has(key):
			_flashed_edges.erase(key)

	_resolve_label_overlaps(label_items)


# nudges overlapping pills apart vertically so labels stay readable; layout's label_pos stays the ideal anchor
func _resolve_label_overlaps(items: Array) -> void:
	items.sort_custom(func(a, b): return a.rect.position.y < b.rect.position.y)

	for _pass in range(4):
		var moved: bool = false
		for i in range(items.size()):
			for j in range(i + 1, items.size()):
				var ra: Rect2 = items[i].rect
				var rb: Rect2 = items[j].rect
				if ra.intersects(rb):
					var overlap_y: float = (ra.position.y + ra.size.y) - rb.position.y
					if overlap_y > 0.0:
						rb.position.y += overlap_y + 2.0
						items[j].rect = rb
						moved = true
		if not moved:
			break

	for it in items:
		it.label.position = it.rect.position


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
		var new_width: float = lerpf(view.line.width, target_width, 15.0 * _delta)

		if abs(new_width - target_width) < 0.01:
			new_width = target_width
		else:
			needs_redraw = true

		if view.line.width != new_width:
			view.line.width = new_width

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

		# arrow scales with the current line width, dampened so glow doesn't balloon it
		var s: float = 0.5 + 0.5 * (view.line.width / NORMAL_WIDTH)
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
	var pulse_w: float = view.line.width + 2.5

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
