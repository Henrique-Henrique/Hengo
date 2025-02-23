@tool
class_name HenStateConnectionLine extends Line2D


const POINT_WIDTH: int = 40
const POINT_WIDTH_BEZIER = POINT_WIDTH / 2.

var from_transition
var to_state
var deleted: bool = false

# pool
var from_pool_visible: bool = true
var to_pool_visible: bool = true
var from_virtual_pos: Vector2
var to_virtual_pos: Vector2
var virtual_invert_start: int = 1
var virtual_invert_end: int = 1

func _ready() -> void:
	default_color = EditorInterface.get_editor_settings().get_setting('interface/theme/base_color').lightened(.1)

# public
#
func update_line() -> void:
	var _start_point: Vector2
	var _end_point: Vector2

	var to_pos: Vector2 = HenGlobal.STATE_CAM.get_relative_vec2(to_state.global_position) if to_pool_visible else to_virtual_pos
	var to_pos_2: Vector2 = (to_pos + to_state.size) if to_pool_visible else to_virtual_pos
	var from_pos: Vector2 = (HenGlobal.STATE_CAM.get_relative_vec2(from_transition.root.global_position) + from_transition.root.size / 2) if from_pool_visible else from_virtual_pos
	var from_pos_2: Vector2 = HenGlobal.STATE_CAM.get_relative_vec2(from_transition.root.global_position) if from_pool_visible else from_virtual_pos

	if to_pos > from_pos:
		_start_point = HenGlobal.STATE_CAM.get_relative_vec2(from_transition.global_position) + Vector2(from_transition.size.x, from_transition.size.y / 2)
		_end_point = HenGlobal.STATE_CAM.get_relative_vec2(to_state.global_position) + Vector2(-10, to_state.get_node('%Title').size.y / 2)

		if from_pool_visible:
			virtual_invert_start = 1
		
		if to_pool_visible:
			virtual_invert_end = 1
	elif to_pos < from_pos and to_pos > from_pos_2:
		var end: Vector2 = HenGlobal.STATE_CAM.get_relative_vec2(to_state.global_position)

		end.x += to_state.size.x + 10
		end.y += to_state.get_node('%Title').size.y / 2

		_start_point = HenGlobal.STATE_CAM.get_relative_vec2(from_transition.global_position) + Vector2(from_transition.size.x, from_transition.size.y / 2)
		_end_point = end

		if from_pool_visible:
			virtual_invert_start = 1
		
		if to_pool_visible:
			virtual_invert_end = -1
	elif to_pos_2 < from_pos_2:
		var end: Vector2 = HenGlobal.STATE_CAM.get_relative_vec2(to_state.global_position)

		end.x += to_state.size.x + 10
		end.y += to_state.get_node('%Title').size.y / 2

		_start_point = HenGlobal.STATE_CAM.get_relative_vec2(from_transition.global_position) + Vector2(0, from_transition.size.y / 2)
		_end_point = end

		if from_pool_visible:
			virtual_invert_start = -1
		
		if to_pool_visible:
			virtual_invert_end = -1
	elif to_pos < from_pos_2:
		_start_point = HenGlobal.STATE_CAM.get_relative_vec2(from_transition.global_position) + Vector2(0, from_transition.size.y / 2)
		_end_point = HenGlobal.STATE_CAM.get_relative_vec2(to_state.global_position) + Vector2(-10, to_state.get_node('%Title').size.y / 2)
		
		if from_pool_visible:
			virtual_invert_start = -1
		
		if to_pool_visible:
			virtual_invert_end = 1
	

	_draw_line(_start_point, _end_point, virtual_invert_start, virtual_invert_end)
		

func _draw_line(_start_point: Vector2, _end_point: Vector2, _invert_start: int = 1, _invert_end: int = 1) -> void:
	var start_pos: Vector2 = _start_point if from_pool_visible else from_virtual_pos
	var end_pos: Vector2 = _end_point if to_pool_visible else to_virtual_pos

	var first_point: Vector2 = start_pos + Vector2(POINT_WIDTH * _invert_start, 0)
	var last_point: Vector2 = end_pos - Vector2((POINT_WIDTH - 13) * _invert_end, 0)
	

	if (first_point.distance_to(last_point) / POINT_WIDTH) >= .7:
		var before_first_point: Vector2 = first_point - Vector2(POINT_WIDTH_BEZIER * _invert_start, 0)
		var after_first_point: Vector2 = first_point + first_point.direction_to(last_point) * POINT_WIDTH_BEZIER

		var first_bezier: Curve2D = Curve2D.new()

		first_bezier.add_point(before_first_point, Vector2.ZERO, first_point - before_first_point)
		first_bezier.add_point(after_first_point, first_point - after_first_point, Vector2.ZERO)

		# creating second bezier curve
		var before_last_point: Vector2 = last_point + Vector2(POINT_WIDTH_BEZIER * _invert_end, 0)
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
	await HenGlobal.STATE_CAM.get_tree().process_frame
	HenGlobal.STATE_CAM.get_node('Lines').add_child(self)
	global_position = HenGlobal.STATE_CAM.global_position

	update_line()

	if not from_transition.root.is_connected('on_move', update_line):
		from_transition.root.connect('on_move', update_line)
	
	if not to_state.is_connected('on_move', update_line):
		to_state.connect('on_move', update_line)

	deleted = false

	if _add_to_list:
		from_transition.line = self
		from_transition.root.to_lines.append(self)
		to_state.from_lines.append(self)


func remove_from_scene(_remove_from_list: bool = true) -> void:
	if is_inside_tree():
		HenGlobal.STATE_CAM.get_node('Lines').remove_child(self)
		
		if from_transition.root.is_connected('on_move', update_line):
			from_transition.root.disconnect('on_move', update_line)
		
		if to_state.is_connected('on_move', update_line):
			to_state.disconnect('on_move', update_line)
	
	deleted = true

	if _remove_from_list:
		from_transition.line = null
		from_transition.root.to_lines.erase(self)
		to_state.from_lines.erase(self)