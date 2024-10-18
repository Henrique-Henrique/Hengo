@tool
extends Line2D

# imports
const _Global = preload('res://addons/hengo/scripts/global.gd')
const _CodeGeneration = preload('res://addons/hengo/scripts/code_generation.gd')
const _Router = preload('res://addons/hengo/scripts/router.gd')

# debug imports
const flow_debug_shader = preload('res://addons/hengo/assets/shaders/flow_debug.gdshader')
const normal_texture = preload('res://addons/hengo/assets/images/line_dashed.png')
const debug_texture = preload('res://addons/hengo/assets/images/flow_line_debug.svg')

var from_connector
var to_cnode
var flow_type: StringName = ''

# debug
const DEBUG_TIMER_TIME = .15
const DEBUG_TRANS_TIME = .7

var debug_timer: Timer

const POINT_WIDTH: float = 50.
const POINT_WIDTH_BEZIER: float = POINT_WIDTH / 1.1

func update_line() -> void:
	var from_pos: Vector2 = _Global.CNODE_CAM.get_relative_vec2(from_connector.global_position) + from_connector.size / 2
	var end_pos: Vector2 = _Global.CNODE_CAM.get_relative_vec2(to_cnode.global_position) + Vector2(to_cnode.size.x / 2, 0)

	var first_point: Vector2 = from_pos + Vector2(0, POINT_WIDTH)
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

		points = [from_pos]
		points += first_bezier.get_baked_points()
		points += last_bezier.get_baked_points()
		points += PackedVector2Array([end_pos])
	else:
		points = [from_pos, end_pos]


func add_to_scene(_add_to_list: bool = true) -> void:
	_Global.CNODE_CAM.get_node('Lines').add_child(self)
	global_position = _Global.CNODE_CAM.global_position

	update_line()

	if not from_connector.root.is_connected('on_move', update_line):
		from_connector.root.connect('on_move', update_line)
	
	if not to_cnode.is_connected('on_move', update_line):
		to_cnode.connect('on_move', update_line)

	from_connector.is_connected = true
	from_connector.texture = load('res://addons/hengo/assets/icons/flow_arrow_hover.svg')
	to_cnode.get_node('%ArrowUp').visible = true


	if _add_to_list:
		(from_connector.root.flow_to as Dictionary)[flow_type] = to_cnode
		to_cnode.from_lines.append(self)
		from_connector.connections_lines.append(self)
	
	to_cnode.check_error()

	if not (_Router.line_route_reference[to_cnode.route_ref.id] as Array).has(self):
		_Router.line_route_reference[to_cnode.route_ref.id].append(self)
	

func remove_from_scene(_remove_from_list: bool = true) -> void:
	if is_inside_tree():
		_Global.CNODE_CAM.get_node('Lines').remove_child(self)
		
		if from_connector.root.is_connected('on_move', update_line):
			from_connector.root.disconnect('on_move', update_line)
		
		if to_cnode.is_connected('on_move', update_line):
			to_cnode.disconnect('on_move', update_line)
		
		_Router.line_route_reference[to_cnode.route_ref.id].erase(self)
	
	from_connector.is_connected = false
	from_connector.texture = load('res://addons/hengo/assets/icons/flow_arrow.svg')
	to_cnode.get_node('%ArrowUp').visible = false

	if _remove_from_list:
		(from_connector.root.flow_to as Dictionary).erase(flow_type)
		to_cnode.from_lines.erase(self)
		from_connector.connections_lines.erase(self)
	
	to_cnode.check_error()


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

		var cnode_border: Panel = to_cnode.get_border()
		var from_cnode_border: Panel = from_connector.root.get_border()
		var border_style: StyleBoxFlat = cnode_border.get('theme_override_styles/panel')
		var from_border_style: StyleBoxFlat = from_cnode_border.get('theme_override_styles/panel')

		var to_color: Color = Color('#FABC3F') if to_cnode.type == 'debug_value' else Color('#52b788')
		var from_color: Color = Color('#FABC3F') if from_connector.root.type == 'debug_value' else Color('#52b788')

		# arrows colors
		from_connector.modulate = to_color
		to_cnode.get_node('%ArrowUp').get_child(0).modulate = to_color

		border_style.set('border_color', to_color)
		border_style.set('bg_color', Color(to_color, .1))

		from_border_style.set('border_color', from_color)
		from_border_style.set('bg_color', Color(from_color, .1))
	

		# animations
		var tween: Tween = get_tree().create_tween().parallel().set_trans(Tween.TRANS_LINEAR)
		tween.tween_method(change_debug_line_color, default_color, to_color, DEBUG_TIMER_TIME)
		tween.tween_property(self, 'width', 17, DEBUG_TIMER_TIME)
	
		cnode_border.visible = true
		from_cnode_border.visible = true
		return

	debug_timer.start(DEBUG_TIMER_TIME)


func hide_debug() -> void:
	texture = normal_texture
	material.shader = null
	debug_timer.queue_free()
	debug_timer = null
	width = 9

	# arrows
	from_connector.modulate = Color('#515151')
	to_cnode.get_node('%ArrowUp').get_child(0).modulate = Color('#515151')

	var cnode_border: Panel = to_cnode.get_border()
	cnode_border.visible = false
	to_cnode.modulate = Color.WHITE

	# animations
	var tween: Tween = get_tree().create_tween().parallel().set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, 'width', 7, DEBUG_TIMER_TIME)
	

func change_debug_line_color(_color: Color) -> void:
	material.set_shader_parameter('color', _color)
