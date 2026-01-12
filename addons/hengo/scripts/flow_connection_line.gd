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


# generates a smooth vertical cubic bezier for flow connections
func update_line() -> void:
	var from_ref: HenVirtualCNode = from.get_ref()
	var to_ref: HenVirtualCNode = to.get_ref()

	if not from_ref or not to_ref:
		return

	var start_pos: Vector2 = get_flow_io_position(from_ref, false, from_idx) + Vector2(0, 20)
	var end_pos: Vector2 = get_flow_io_position(to_ref, true, to_idx) - Vector2(0, 20)
	
	# calculate vertical curvature
	var distance_y: float = abs(end_pos.y - start_pos.y)
	var tangent_offset: float = clamp(distance_y / 2.0, 30.0, 150.0)

	# control points aligned vertically
	var control_1: Vector2 = start_pos + Vector2(0, tangent_offset)
	var control_2: Vector2 = end_pos - Vector2(0, tangent_offset)

	var curve_points: PackedVector2Array = PackedVector2Array()
	var steps: int = 24 # slightly more steps for vertical flow smoothness
	
	for i in range(steps + 1):
		var t: float = i / float(steps)
		var point: Vector2 = start_pos.bezier_interpolate(control_1, control_2, end_pos, t)
		curve_points.append(point)

	points = curve_points


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
