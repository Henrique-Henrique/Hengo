@tool
class_name HenConnectionLine extends Line2D

# debug imports
const flow_debug_shader = preload('res://addons/hengo/assets/shaders/flow_debug.gdshader')
const normal_texture = preload('res://addons/hengo/assets/images/line.png')
const debug_texture = preload('res://addons/hengo/assets/images/line_debug.svg')

var from_cnode: HenCnode
var to_cnode: HenCnode
var input
var output
var conn_size: Vector2

var deleted: bool = false

const POINT_WIDTH: int = 50
const POINT_WIDTH_BEZIER: int = POINT_WIDTH / 2

# debug
const DEBUG_TIMER_TIME = .15
const DEBUG_TRANS_TIME = 1.

var debug_timer: Timer

# pool
var from_pool_visible: bool = true
var to_pool_visible: bool = true
var from_virtual_pos: Vector2
var to_virtual_pos: Vector2


func update_line() -> void:
	var start_pos: Vector2 = HenGlobal.CAM.get_relative_vec2(input.global_position) + conn_size if from_pool_visible and input else from_virtual_pos
	var end_pos: Vector2 = HenGlobal.CAM.get_relative_vec2(output.global_position) + conn_size if to_pool_visible and output else to_virtual_pos

	var first_point: Vector2 = start_pos + Vector2(POINT_WIDTH, 0)
	var last_point: Vector2 = end_pos - Vector2(POINT_WIDTH, 0)

	if (first_point.distance_to(last_point) / POINT_WIDTH) >= .7:
		var before_first_point: Vector2 = first_point - Vector2(POINT_WIDTH_BEZIER, 0)
		var after_first_point: Vector2 = first_point + first_point.direction_to(last_point) * POINT_WIDTH_BEZIER

		var first_bezier: Curve2D = Curve2D.new()

		first_bezier.add_point(before_first_point, Vector2.ZERO, first_point - before_first_point)
		first_bezier.add_point(after_first_point, first_point - after_first_point, Vector2.ZERO)

		# creating second bezier curve
		var before_last_point: Vector2 = last_point + Vector2(POINT_WIDTH_BEZIER, 0)
		var after_last_point: Vector2 = last_point - last_point.direction_to(after_first_point) * POINT_WIDTH_BEZIER * -1

		var last_bezier: Curve2D = Curve2D.new()

		last_bezier.add_point(after_last_point, Vector2.ZERO, last_point - after_last_point)
		last_bezier.add_point(before_last_point, last_point - before_last_point, Vector2.ZERO)

		points = [start_pos]
		points += first_bezier.get_baked_points()
		points += last_bezier.get_baked_points()
		points += PackedVector2Array([end_pos])
	else:
		points = [start_pos, end_pos]


func update_colors(_from_type: StringName, _to_type: StringName) -> void:
	gradient.colors[0] = get_type_color(_from_type)
	gradient.colors[1] = get_type_color(_to_type)

	# debug colors
	match _from_type:
		'String':
			default_color = Color('#8eef97')
		'float':
			default_color = Color('#FFDD65')
		'int':
			default_color = Color('#5ABBEF')
		'bool':
			default_color = Color('#FC7F7F')
		'Vector2', 'Vector3':
			default_color = Color('#c368ed')
		'Variant':
			default_color = Color('#72788a')
		_:
			if ClassDB.is_parent_class(_from_type, 'Control'):
				default_color = Color('#8eef97')
			elif ClassDB.is_parent_class(_from_type, 'Node2D'):
				default_color = Color('#5ABBEF')
			elif ClassDB.is_parent_class(_from_type, 'Node3D'):
				default_color = Color('#FC7F7F')
			elif ClassDB.is_parent_class(_from_type, 'AnimationMixer'):
				default_color = Color('#c368ed')


func get_type_color(_type: String) -> Color:
	match _type:
		'String':
			return Color('#8eef97')
		'float':
			return Color('#FFDD65')
		'int':
			return Color('#5ABBEF')
		'bool':
			return Color('#FC7F7F')
		'Vector2', 'Vector3':
			return Color('#c368ed')
		'Variant':
			return Color('#72788a')
		_:
			if ClassDB.is_parent_class(_type, 'Control'):
				return Color('#8eef97')
			elif ClassDB.is_parent_class(_type, 'Node2D'):
				return Color('#5ABBEF')
			elif ClassDB.is_parent_class(_type, 'Node3D'):
				return Color('#FC7F7F')
			elif ClassDB.is_parent_class(_type, 'AnimationMixer'):
				return Color('#c368ed')

			return Color.WHITE


func reparent_conn(_old_conn, _new_conn) -> void:
	if _old_conn.owner.root.is_connected('on_move', update_line):
		_old_conn.owner.root.disconnect('on_move', update_line)
	
	if not _new_conn.owner.root.is_connected('on_move', update_line):
		_new_conn.owner.root.connect('on_move', update_line)


func show_debug() -> void:
	if not is_inside_tree():
		return

	if !debug_timer:
		debug_timer = Timer.new()
		debug_timer.wait_time = DEBUG_TIMER_TIME
		debug_timer.timeout.connect(hide_debug)
		add_child(debug_timer)
		debug_timer.start()
		material.shader = flow_debug_shader
		width = 13
		texture = debug_texture

		match input.owner.input_ref.connection_type:
			'Variant':
				material.set('shader_parameter/color', Color('#72788a'))
			_:
				material.set('shader_parameter/color', default_color)

		# animations
		var tween: Tween = get_tree().create_tween().parallel().set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(self, 'width', 17, DEBUG_TIMER_TIME)
		return

	debug_timer.start(DEBUG_TIMER_TIME)


func hide_debug() -> void:
	texture = normal_texture
	material.shader = null

	debug_timer.queue_free()
	debug_timer = null

	width = 7