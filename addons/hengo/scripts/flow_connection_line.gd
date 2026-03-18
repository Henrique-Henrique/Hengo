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
	if not input or not output: return

	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global.CAM: return
	
	var from_ref: HenVirtualCNode = from.get_ref()
	var to_ref: HenVirtualCNode = to.get_ref()
	
	if not from_ref or not to_ref: return

	var start_pos: Vector2
	if from_pool_visible:
		start_pos = global.CAM.get_relative_vec2(input.global_position) + input.size / 2 + Vector2(0, 20)
		last_from_pos = start_pos
	else:
		start_pos = last_from_pos if last_from_pos != Vector2.ZERO else from_ref.position + Vector2(from_ref.size.x / 2.0, 0)
	
	var end_pos: Vector2
	if to_pool_visible:
		end_pos = global.CAM.get_relative_vec2(output.global_position) + output.size / 2 - Vector2(0, 20)
		last_to_pos = end_pos
	else:
		end_pos = last_to_pos if last_to_pos != Vector2.ZERO else to_ref.position + Vector2(to_ref.size.x / 2.0, to_ref.size.y)
	
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

	if !debug_timer:
		debug_timer = Timer.new()
		debug_timer.wait_time = DEBUG_TIMER_TIME
		debug_timer.timeout.connect(hide_debug)
		add_child(debug_timer)

	texture = debug_texture
	material.shader = flow_debug_shader
	material.set_shader_parameter('color', Color('#63ff92ff'))
	width = 20

	input.modulate = Color('#63ff92ff')
	output.modulate = Color('#63ff92ff')
	
	debug_timer.start(DEBUG_TIMER_TIME)


func hide_debug() -> void:
	texture = normal_texture
	material.shader = null
	
	if debug_timer:
		debug_timer.queue_free()
		debug_timer = null

	width = 9

	# arrows
	input.modulate = Color.WHITE
	output.modulate = Color.WHITE

	# animations
	var tween: Tween = get_tree().create_tween().parallel().set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, 'width', 7, DEBUG_TIMER_TIME)
	

func change_debug_line_color(_color: Color) -> void:
	material.set_shader_parameter('color', _color)
