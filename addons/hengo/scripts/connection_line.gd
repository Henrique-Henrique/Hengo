@tool
class_name HenConnectionLine extends Line2D


@onready var from_icon: TextureRect = $FromIcon
@onready var remote_container: PanelContainer = $Remote


# debug imports
const flow_debug_shader = preload('res://addons/hengo/assets/shaders/flow_debug.gdshader')
const normal_texture = preload('res://addons/hengo/assets/images/line.png')
const debug_texture = preload('res://addons/hengo/assets/images/line_debug.svg')

var input
var output
var conn_size: Vector2

var deleted: bool = false

const POINT_WIDTH: int = 50
const POINT_WIDTH_BEZIER: int = int(POINT_WIDTH / 2.)

# debug
const DEBUG_TIMER_TIME = .15
const DEBUG_TRANS_TIME = 1.

var debug_timer: Timer

var from: WeakRef
var to: WeakRef
var from_idx: int
var to_idx: int

const TITLE_SIZE_Y = 43
const CNODE_IO_SIZE = 40

# offscreen-fallback geometry, tuned so the rough anchor matches the eventual
# connector offset. output ~ (size.x - EDGE_INSET, ROW0_Y + idx*ROW_STEP),
# input ~ (EDGE_INSET, ROW0_Y + idx*ROW_STEP)
const CONN_EDGE_INSET: float = 26.5
const CONN_ROW0_Y: float = 131.0
const CONN_ROW_STEP: float = 54.5

# pool
var from_pool_visible: bool = true
var to_pool_visible: bool = true
var last_from_pos: Vector2
var last_to_pos: Vector2

# instance id of the connection bound to this pooled line, 0 = unbound; detects
# a pool recycle that is_instance_valid(line_ref) can't
var owner_conn_id: int = 0

# connector offset from the node origin (world units), captured while the node
# is visible and reused as the anchor when it is offscreen
var from_offset: Vector2
var to_offset: Vector2
var has_from_offset: bool = false
var has_to_offset: bool = false


# generates a smooth cubic bezier curve between two points
func update_line() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global.CAM: return

	if not from or not to: return
	var from_ref: HenVirtualCNode = from.get_ref()
	var to_ref: HenVirtualCNode = to.get_ref()
	if not from_ref or not to_ref: return

	# endpoint priority: live connector -> captured offset while offscreen ->
	# rough anchor before first render
	var start_pos: Vector2
	if from_pool_visible and is_instance_valid(input):
		start_pos = global.CAM.get_relative_vec2(input.global_position) + input.size / 2
		last_from_pos = start_pos
		from_offset = start_pos - from_ref.position
		has_from_offset = true
	elif has_from_offset:
		start_pos = from_ref.position + from_offset
	else:
		start_pos = from_ref.position + Vector2(
			from_ref.size.x - CONN_EDGE_INSET,
			CONN_ROW0_Y + from_idx * CONN_ROW_STEP)

	var end_pos: Vector2
	if to_pool_visible and is_instance_valid(output):
		end_pos = global.CAM.get_relative_vec2(output.global_position) + output.size / 2
		last_to_pos = end_pos
		to_offset = end_pos - to_ref.position
		has_to_offset = true
	elif has_to_offset:
		end_pos = to_ref.position + to_offset
	else:
		end_pos = to_ref.position + Vector2(
			CONN_EDGE_INSET,
			CONN_ROW0_Y + to_idx * CONN_ROW_STEP)

	# dynamic curvature based on distance
	var distance: float = abs(end_pos.x - start_pos.x)
	var tangent_offset: float = clamp(distance / 2.0, 20.0, 100.0)

	var control_1: Vector2 = start_pos + Vector2(tangent_offset, 0)
	var control_2: Vector2 = end_pos - Vector2(tangent_offset, 0)

	var curve_points: PackedVector2Array = PackedVector2Array()
	var steps: int = 20 # adjust for smoothness
	
	for i in range(steps + 1):
		var t: float = i / float(steps)
		var point: Vector2 = start_pos.bezier_interpolate(control_1, control_2, end_pos, t)
		curve_points.append(point)

	points = curve_points
	
	_update_visual_style(start_pos, end_pos)

# handles the line visual state
func _update_visual_style(start_pos: Vector2, end_pos: Vector2) -> void:
	if (start_pos.y + 200 < end_pos.y) or (start_pos.x + 800 < end_pos.x):
		var global: HenGlobal = Engine.get_singleton(&'Global')
		from_icon.visible = true
		remote_container.visible = true
		
		if from.get_ref():
			var from_vc: HenVirtualCNode = from.get_ref()
			var icon: TextureRect = remote_container.get_node('%VCIcon') as TextureRect

			icon.texture = HenUtils.get_icon_for_subtype(from_vc.sub_type)
			icon.modulate = HenUtils.get_color_for_subtype(from_vc.sub_type)

			(remote_container.get_node('%VCName') as Label).text = from_vc.get_vc_name(global.SAVE_DATA)
			remote_container.reset_size()
			
		if to.get_ref():
			var to_vc: HenVirtualCNode = to.get_ref()
			from_icon.texture = HenUtils.get_icon_for_subtype(to_vc.sub_type)
			from_icon.modulate = HenUtils.get_color_for_subtype(to_vc.sub_type)

		from_icon.position = start_pos + Vector2(50, -from_icon.size.y / 2.0)
		remote_container.position = end_pos - Vector2(remote_container.size.x + 50, remote_container.size.y / 2.0)
		
		self_modulate = Color.TRANSPARENT
	else:
		from_icon.visible = false
		remote_container.visible = false
		self_modulate = Color.WHITE


func set_color(_color: Color) -> void:
	gradient.colors[0] = _color
	gradient.colors[1] = _color


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