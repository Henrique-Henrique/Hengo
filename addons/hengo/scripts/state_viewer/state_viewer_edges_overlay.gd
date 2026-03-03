@tool
class_name HenStateViewerEdgesOverlay
extends Control

var graph_root: HenStateViewerGraphTypes.DirectedGraphNode

var _line_pool: Array[Line2D] = []
var _label_pool: Array[Label] = []

var _active_node: HenStateViewerGraphTypes.DirectedGraphNode = null
var _hovered_edge: HenStateViewerGraphTypes.DirectedGraphEdge = null
var _edge_views: Array[Dictionary] = []
var _flashed_edges: Dictionary = {}

const LINE_COLOR: Color = Color(0.6, 0.6, 0.65, 1.0)
const ARROW_COLOR: Color = Color(0.6, 0.6, 0.65, 1.0)
const PILL_BG: Color = Color(0.14, 0.14, 0.16, 1.0)
const PILL_BORDER: Color = Color(0.24, 0.24, 0.26, 1.0)
const LABEL_COLOR: Color = Color(0.9, 0.9, 0.9, 1.0)
const DIM_ALPHA: float = 0.2
const GLOW_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)
const GLOW_WIDTH: float = 3.0
const NORMAL_WIDTH: float = 1.5


func _ready() -> void:
	# ensure process is running for hover detection
	set_process(true)


func get_hovered_edge() -> HenStateViewerGraphTypes.DirectedGraphEdge:
	return _hovered_edge


func flash_edge(source: String, event: String) -> void:
	var target_edge: HenStateViewerGraphTypes.DirectedGraphEdge = null
	for view in _edge_views:
		var edge: HenStateViewerGraphTypes.DirectedGraphEdge = view.edge
		var source_short = edge.source.id.get_slice('.', edge.source.id.get_slice_count('.') - 1)
		var edge_event = edge.label.text
		if source_short == source and edge_event == event:
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


func _build_edge_views() -> void:
	if graph_root == null:
		return

	var font: Font = ThemeDB.fallback_font
	var path_util: HenStateViewerPathUtils = HenStateViewerPathUtils.new()
	var edges: Array[HenStateViewerGraphTypes.DirectedGraphEdge] = _get_all_edges(graph_root)

	var line_idx: int = 0
	var label_idx: int = 0
	_edge_views.clear()

	for edge in edges:
		if edge.sections.is_empty():
			continue

		var section: Dictionary = edge.sections[0]
		var curve: Curve2D = path_util.round_path(section)
		var points: PackedVector2Array = curve.get_baked_points()

		var line: Line2D
		if line_idx < _line_pool.size():
			line = _line_pool[line_idx]
		else:
			line = Line2D.new()
			line.default_color = LINE_COLOR
			line.width = NORMAL_WIDTH
			line.antialiased = true
			add_child(line)
			_line_pool.append(line)
			
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
			var pad_x: float = 6.0
			var pad_y: float = 2.0
			var pill_w: float = text_size.x + pad_x * 2.0
			var pill_h: float = text_size.y + pad_y * 2.0
			var pill_rect: Rect2 = Rect2(label_pos - Vector2(pill_w * 0.5, pill_h * 0.5), Vector2(pill_w, pill_h))

			var style: StyleBoxFlat = StyleBoxFlat.new()
			style.bg_color = PILL_BG
			style.border_color = PILL_BORDER
			style.set_border_width_all(1)
			style.corner_radius_top_left = 6
			style.corner_radius_top_right = 6
			style.corner_radius_bottom_left = 6
			style.corner_radius_bottom_right = 6
			
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
			lbl.position = pill_rect.position
			lbl.size = pill_rect.size
			label_idx += 1

		# store everything needed for fast lookup and drawing
		var arrow_end: Vector2 = points[points.size() - 1] if points.size() >= 2 else Vector2.ZERO
		var arrow_prev: Vector2 = points[points.size() - 2] if points.size() >= 2 else Vector2.ZERO
		var has_arrow: bool = points.size() >= 2

		_edge_views.append({
			edge = edge,
			points = points,
			line = line,
			label = lbl,
			has_arrow = has_arrow,
			arrow_end = arrow_end,
			arrow_prev = arrow_prev
		})

	while _line_pool.size() > line_idx:
		var unused_line: Line2D = _line_pool.pop_back()
		unused_line.queue_free()

	while _label_pool.size() > label_idx:
		var unused_lbl: Label = _label_pool.pop_back()
		unused_lbl.queue_free()


func _process(_delta: float) -> void:
	if _edge_views.is_empty():
		return

	var mouse_pos: Vector2 = get_local_mouse_position()
	var closest_edge: HenStateViewerGraphTypes.DirectedGraphEdge = null
	var closest_dist: float = 15.0 # hover threshold

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
		var is_dimmed: bool = false
		if _active_node != null:
			if view.edge.source != _active_node:
				is_dimmed = true
		elif _hovered_edge != null:
			if view.edge != _hovered_edge:
				is_dimmed = true

		var is_flashed: bool = false
		if _flashed_edges.has(view.edge):
			if current_time - _flashed_edges[view.edge] < 500:
				is_flashed = true
			else:
				_flashed_edges.erase(view.edge)

		var is_glowing: bool = (view.edge == _hovered_edge) and not is_dimmed
		
		if is_flashed:
			is_glowing = true
			is_dimmed = false

		var target_alpha: float = DIM_ALPHA if is_dimmed else 1.0
		var current_alpha: float = view.line.default_color.a
		var alpha: float = lerpf(current_alpha, target_alpha, 15.0 * _delta)
		
		if abs(alpha - target_alpha) < 0.01:
			alpha = target_alpha
		else:
			needs_redraw = true

		var line_color: Color = Color('#63ff92') if is_flashed else (GLOW_COLOR if is_glowing else LINE_COLOR)
		line_color.a = alpha

		if view.line.default_color != line_color:
			view.line.default_color = line_color
			needs_redraw = true
			
		var target_width: float = (GLOW_WIDTH + 1.0) if is_flashed else (GLOW_WIDTH if is_glowing else NORMAL_WIDTH)
		var current_width: float = view.line.width
		var new_width: float = lerpf(current_width, target_width, 15.0 * _delta)
		
		if abs(new_width - target_width) < 0.01:
			new_width = target_width
		else:
			needs_redraw = true

		if view.line.width != new_width:
			view.line.width = new_width

		if view.label != null and view.label.modulate.a != alpha:
			view.label.modulate.a = alpha

	if needs_redraw:
		queue_redraw()


func _draw() -> void:
	for view in _edge_views:
		if not view.has_arrow:
			continue

		var is_dimmed: bool = false
		if _active_node != null:
			if view.edge.source != _active_node:
				is_dimmed = true
		elif _hovered_edge != null:
			if view.edge != _hovered_edge:
				is_dimmed = true

		var is_glowing: bool = (view.edge == _hovered_edge) and not is_dimmed

		var color: Color = GLOW_COLOR if is_glowing else ARROW_COLOR
		color.a = view.line.default_color.a

		var end_pt: Vector2 = view.arrow_end
		var prev_pt: Vector2 = view.arrow_prev
		var dir: Vector2 = (end_pt - prev_pt).normalized()
		var arrow_base: Vector2 = end_pt - dir * 6.0
		var perp: Vector2 = Vector2(-dir.y, dir.x) * 3.5

		draw_polygon(PackedVector2Array([end_pt, arrow_base + perp, arrow_base - perp]),
			PackedColorArray([color]))


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
