@tool
class_name HenFlowConnectionLine extends Line2D

# debug imports
const flow_debug_shader = preload('res://addons/hengo/assets/shaders/flow_debug.gdshader')
const normal_texture = preload('res://addons/hengo/assets/images/line_dashed.png')
const debug_texture = preload('res://addons/hengo/assets/images/flow_line_debug.svg')

var input: HenFlowConnector
var output: TextureRect
var flow_type: StringName = ''
var from_flow_idx: int = 0

var from: WeakRef
var to: WeakRef
var from_idx: int
var to_idx: int

# debug
const DEBUG_TIMER_TIME = .15
const DEBUG_TRANS_TIME = .7

var debug_timer: Timer

const POINT_WIDTH: float = 60.
const POINT_WIDTH_BEZIER: float = POINT_WIDTH

# pool
var from_pool_visible: bool = true
var to_pool_visible: bool = true
var last_from_pos: Vector2
var last_to_pos: Vector2


func update_line() -> void:
	var from_ref: HenVirtualCNode = from.get_ref()
	var to_ref: HenVirtualCNode = to.get_ref()

	if not from_ref or not to_ref:
		return

	var start_pos: Vector2 = get_flow_io_position(from_ref, false, from_idx) + Vector2(0, 20)
	var end_pos: Vector2 = get_flow_io_position(to_ref, true, to_idx) - Vector2(0, 20)
	var first_point: Vector2 = start_pos + Vector2(0, POINT_WIDTH)
	var last_point: Vector2 = end_pos - Vector2(0, POINT_WIDTH)

	if (first_point.distance_to(last_point) / POINT_WIDTH) >= 1.5:
		# creating last point here because after_first_point need him
		# creating first bezier curve
		var before_first_point: Vector2 = first_point - Vector2(0, POINT_WIDTH_BEZIER)
		var after_first_point: Vector2 = (
			first_point + first_point.direction_to(last_point) * POINT_WIDTH_BEZIER
		)

		var first_bezier: Curve2D = Curve2D.new()

		first_bezier.add_point(before_first_point, Vector2.ZERO, first_point - before_first_point)
		first_bezier.add_point(after_first_point, first_point - after_first_point, Vector2.ZERO)

		# creating second bezier curve
		var before_last_point: Vector2 = last_point + Vector2(0, POINT_WIDTH_BEZIER)
		var after_last_point: Vector2 = (
			last_point - last_point.direction_to(after_first_point) * POINT_WIDTH_BEZIER * -1
		)

		var last_bezier: Curve2D = Curve2D.new()

		last_bezier.add_point(after_last_point, Vector2.ZERO, last_point - after_last_point)
		last_bezier.add_point(before_last_point, last_point - before_last_point, Vector2.ZERO)

		points = [start_pos]
		points += first_bezier.get_baked_points()
		points += last_bezier.get_baked_points()
		points += PackedVector2Array([end_pos])
	else:
		points = [start_pos, end_pos]


func show_debug() -> void:
	if not is_inside_tree():
		return

	debug_timer.start(DEBUG_TIMER_TIME)


func hide_debug() -> void:
	texture = normal_texture
	material.shader = null
	debug_timer.queue_free()
	debug_timer = null
	width = 9

	# arrows
	input.modulate = Color('#515151')
	output.get_node('%ArrowUp').get_child(0).modulate = Color('#515151')

	var cnode_border: Panel = output.root.get_border()
	cnode_border.visible = false
	output.modulate = Color.WHITE

	# animations
	var tween: Tween = get_tree().create_tween().parallel().set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, 'width', 7, DEBUG_TIMER_TIME)
	

func change_debug_line_color(_color: Color) -> void:
	material.set_shader_parameter('color', _color)


func get_flow_io_position(_from: HenVirtualCNode, _is_input: bool, _target_idx: int) -> Vector2:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var flows: Array = _from.get_flow_inputs(global.SAVE_DATA) if _is_input else _from.get_flow_outputs(global.SAVE_DATA)
	
	if _target_idx < 0 or _target_idx >= flows.size():
		return _from.position
	
	var y_pos: float = 0.0 if _is_input else _from.size.y
	
	if flows.size() == 1:
		var center_x: float = _from.size.x / 2.0
		
		return _from.position + Vector2(center_x, y_pos)

	var spacing: float = 10.0
	var total_flows_width: float = 0.0
	var widths: Array = []

	for flow: HenVCFlow in flows:
		var item_width: float = HenUtils.get_text_size(flow.name).x
		widths.append(item_width)
		total_flows_width += item_width
	
	total_flows_width += spacing * (flows.size() - 1)
	
	var current_x_offset: float = (_from.size.x - total_flows_width) / 2.0
	
	for i in range(flows.size()):
		var current_item_width: float = widths[i]
		if i == _target_idx:
			var port_center_x: float = current_x_offset + (current_item_width / 2.0)
			return _from.position + Vector2(port_center_x, y_pos)
		current_x_offset += current_item_width + spacing
	
	return _from.position
