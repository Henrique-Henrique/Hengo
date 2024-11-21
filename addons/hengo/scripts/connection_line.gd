@tool
extends Line2D

# imports
const _Global = preload('res://addons/hengo/scripts/global.gd')
const _Assets = preload('res://addons/hengo/scripts/assets.gd')
const _Enums = preload('res://addons/hengo/references/enums.gd')
const _Router = preload('res://addons/hengo/scripts/router.gd')

# debug imports
const flow_debug_shader = preload('res://addons/hengo/assets/shaders/flow_debug.gdshader')
const normal_texture = preload('res://addons/hengo/assets/images/line.png')
const debug_texture = preload('res://addons/hengo/assets/images/line_debug.svg')

var from_cnode
var to_cnode
var input
var output
var conn_size: Vector2

const POINT_WIDTH: int = 50
const POINT_WIDTH_BEZIER: int = POINT_WIDTH / 2

# debug
const DEBUG_TIMER_TIME = .15
const DEBUG_TRANS_TIME = 1.

var debug_timer: Timer


func update_line() -> void:
	var start_pos: Vector2 = _Global.CNODE_CAM.get_relative_vec2(input.global_position) + conn_size
	var end_pos: Vector2 = _Global.CNODE_CAM.get_relative_vec2(output.global_position) + conn_size

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


func add_to_scene(_add_to_list: bool = true) -> void:
	_Global.CNODE_CAM.get_node('Lines').add_child(self)
	global_position = _Global.CNODE_CAM.global_position

	update_line()

	if not from_cnode.is_connected('on_move', update_line):
		from_cnode.connect('on_move', update_line)
	
	if not to_cnode.is_connected('on_move', update_line):
		to_cnode.connect('on_move', update_line)

	output.owner.remove_in_prop()
	output.owner.root.check_error()

	# reconnecting
	if _add_to_list:
		input.owner.to_connection_lines.append(self)
		output.owner.from_connection_lines.append(self)
		output.owner.in_connected_from = input.owner.root

	if not (_Router.line_route_reference[to_cnode.route_ref.id] as Array).has(self):
		_Router.line_route_reference[to_cnode.route_ref.id].append(self)


func remove_from_scene(_remove_from_list: bool = true) -> void:
	if is_inside_tree():
		_Global.CNODE_CAM.get_node('Lines').remove_child(self)

		if from_cnode.is_connected('on_move', update_line):
			from_cnode.disconnect('on_move', update_line)
		
		if to_cnode.is_connected('on_move', update_line):
			to_cnode.disconnect('on_move', update_line)
		
		_Router.line_route_reference[to_cnode.route_ref.id].erase(self)

	output.owner.set_in_prop()
	output.owner.root.check_error()

	# # reseting connection
	if _remove_from_list:
		input.owner.to_connection_lines.erase(self)
		output.owner.from_connection_lines.erase(self)
		output.owner.in_connected_from = null


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

		match input.owner.connection_type:
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