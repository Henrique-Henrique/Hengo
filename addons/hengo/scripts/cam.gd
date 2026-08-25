@tool
class_name HenCam extends Node2D

@export var grid: TextureRect
@export var is_global_cam: bool = true

var target_zoom: float = 1.

var MIN_ZOOM: float = 1
var MAX_ZOOM: float = 2
var ZOOM_INCREMENT: float = .15
var ZOOM_RATE: float = 12.

var t_x: Vector2 = Vector2(1, 0)
var t_y: Vector2 = Vector2(0, 1)
var pos: Vector2 = Vector2.ZERO

var ignore_process: bool = false

var can_scroll: bool = true

var _left_pan: bool = false
var _panning: bool = false

# per-frame usec budget for draining pending_show_queue; caps show() cost so a
# dense graph doesn't stutter the pan
const SHOW_BUDGET_USEC: int = 4000

const PAN_BUTTONS: Array[int] = [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]

# _check_virtual_cnodes throttle: skip re-checks until the viewport moves enough
# or a few frames pass, to avoid iterating every node each tick
const CHECK_MIN_DELTA_PX: float = 16.0
const CHECK_MIN_DELTA_ZOOM: float = 0.01
const CHECK_MAX_FRAMES_SKIP: int = 3
var _last_check_pos: Vector2 = Vector2.INF
var _last_check_zoom: float = -1.0
var _frames_since_check: int = 0

@onready var ref_point: Marker2D = get_node('RefPoint')
var initial: Vector2 = Vector2.ZERO


func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self ):
		return
	add_to_group(&'hen_cam')
	update_settings()

	if is_global_cam:
		can_scroll = false
	var parent: Control = get_parent()

	parent.item_rect_changed.connect(_on_ui_size_changed)

	(grid.material as ShaderMaterial).set_shader_parameter('zoom_factor', transform.x.x)
	(grid.material as ShaderMaterial).set_shader_parameter('offset', transform.origin)

	_update_zoom_label()


func _on_ui_size_changed() -> void:
	(grid.material as ShaderMaterial).set_shader_parameter('screen_size', get_parent().size)


func update_settings() -> void:
	MIN_ZOOM = ProjectSettings.get_setting(HenSettings.MIN_ZOOM_PATH, 1.0)
	MAX_ZOOM = ProjectSettings.get_setting(HenSettings.MAX_ZOOM_PATH, 2.0)
	ZOOM_INCREMENT = ProjectSettings.get_setting(HenSettings.ZOOM_INCREMENT_PATH, 0.15)
	ZOOM_RATE = ProjectSettings.get_setting(HenSettings.ZOOM_RATE_PATH, 12.0)


static func set_all_can_scroll(_tree: SceneTree, _value: bool) -> void:
	if not _tree:
		return

	for node: Node in _tree.get_nodes_in_group(&'hen_cam'):
		(node as HenCam).can_scroll = _value


static func reset_all_zoom(_tree: SceneTree) -> void:
	if not _tree:
		return

	for node: Node in _tree.get_nodes_in_group(&'hen_cam'):
		(node as HenCam).reset_zoom()


static func update_all_settings(_tree: SceneTree) -> void:
	if not _tree:
		return

	for node: Node in _tree.get_nodes_in_group(&'hen_cam'):
		(node as HenCam).update_settings()


static func set_all_input_enabled(_tree: SceneTree, _value: bool) -> void:
	if not _tree:
		return

	for node: Node in _tree.get_nodes_in_group(&'hen_cam'):
		var cam: HenCam = node as HenCam
		cam.set_process_input(_value)

		if not _value:
			cam.set_physics_process(false)


func is_cam_active() -> bool:
	var parent: Control = get_parent() as Control

	if is_global_cam:
		return false

	if not is_inside_tree():
		return false

	if parent and parent.is_visible_in_tree():
		var rect: Rect2 = parent.get_global_rect()
		return rect.has_point(parent.get_global_mouse_position())

	return false


func _input(event: InputEvent) -> void:
	# a release outside the canvas still has to disarm, so it comes before the gate
	if event is InputEventMouseButton:
		var released: InputEventMouseButton = event as InputEventMouseButton
		if not released.pressed:
			if released.button_index == MOUSE_BUTTON_LEFT:
				_left_pan = false

			if released.button_index in PAN_BUTTONS:
				_panning = false

	if is_cam_active():
		if event is InputEventMouseMotion:

			var mask: int = (event as InputEventMouseMotion).button_mask

			if mask == MOUSE_BUTTON_MASK_MIDDLE or mask == MOUSE_BUTTON_MASK_RIGHT or \
			   (_left_pan and mask == MOUSE_BUTTON_MASK_LEFT):
				# arms on the drag, not on the press, so a click on a card never flashes the grab cursor
				_panning = true
				transform.origin += (event as InputEventMouseMotion).relative
				(grid.material as ShaderMaterial).set_shader_parameter('offset', transform.origin)
				set_physics_process(false)

		elif event is InputEventPanGesture:
			transform.origin -= (event as InputEventPanGesture).delta * 40
			(grid.material as ShaderMaterial).set_shader_parameter('offset', transform.origin)
			set_physics_process(false)

		elif event is InputEventMagnifyGesture:
			var zoom_amount = (event as InputEventMagnifyGesture).factor
			if zoom_amount > 1.0:
				_zoom_in((zoom_amount - 1.0) * 2.0)
			elif zoom_amount < 1.0:
				_zoom_out((1.0 - zoom_amount) * 2.0)

		elif event is InputEventMouseButton:
			var mb: InputEventMouseButton = event as InputEventMouseButton

			if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
				_left_pan = _can_start_left_pan()

			if mb.is_pressed():
				if can_scroll:
					if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
						_zoom_in()
					if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
						_zoom_out()


func is_panning() -> bool:
	return _panning


# a press on a row or a button belongs to that control, not to the pan
func _can_start_left_pan() -> bool:
	if is_global_cam:
		return false

	var parent: Node = get_parent()

	# a drawn canvas has no controls to hit-test, so it answers for itself
	if parent and parent.has_method(&'blocks_pan') and parent.call(&'blocks_pan'):
		return false

	var hovered: Control = get_viewport().gui_get_hovered_control()

	return hovered == null or hovered == parent


func _zoom_in(amount: float = ZOOM_INCREMENT) -> void:
	target_zoom = min(target_zoom + amount, MAX_ZOOM)
	_set_transform(get_global_mouse_position())
	_update_zoom_label()


func _zoom_out(amount: float = ZOOM_INCREMENT) -> void:
	target_zoom = max(target_zoom - amount, MIN_ZOOM)
	_set_transform(get_global_mouse_position())
	_update_zoom_label()


func _process(_delta: float) -> void:
	pass


func reset_zoom() -> void:
	target_zoom = 1.0
	t_x = Vector2(1, 0)
	t_y = Vector2(0, 1)
	set_physics_process(true)
	_update_zoom_label()


# a pan writes transform.origin straight and leaves pos behind, while a running
# lerp has pos as the destination transform.origin is still travelling to
func capture_view() -> Dictionary:
	return {
		origin = pos if is_physics_processing() else transform.origin,
		zoom = target_zoom
	}


func apply_view(_view: Dictionary) -> void:
	var zoom: float = clampf(_view.get('zoom', 1.0), MIN_ZOOM, MAX_ZOOM)
	var origin: Vector2 = _view.get('origin', Vector2.ZERO)

	target_zoom = zoom
	t_x = Vector2(zoom, 0)
	t_y = Vector2(0, zoom)
	pos = origin
	transform = Transform2D(t_x, t_y, origin)

	ignore_process = false
	set_physics_process(false)

	if grid and grid.material:
		var mat: ShaderMaterial = grid.material as ShaderMaterial
		mat.set_shader_parameter('zoom_factor', zoom)
		mat.set_shader_parameter('offset', origin)

	_update_zoom_label()


func _set_transform(_pos: Vector2) -> void:
	ref_point.global_position = _pos

	var old: Vector2 = ref_point.global_position
	var old_x: Vector2 = transform.x
	var old_y: Vector2 = transform.y

	transform.x = Vector2(target_zoom, 0)
	transform.y = Vector2(0, target_zoom)

	pos = transform.origin + (old - ref_point.global_position)

	transform.x = old_x
	transform.y = old_y

	t_x = Vector2(target_zoom, 0)
	t_y = Vector2(0, target_zoom)

	set_physics_process(true)


func _physics_process(_delta: float) -> void:
	if ignore_process or is_cam_active():
		var factor: float = ZOOM_RATE * _delta
		transform.x = lerp(transform.x, t_x, factor)
		transform.y = lerp(transform.y, t_y, factor)

		transform.origin = lerp(transform.origin, pos, factor)

		(grid.material as ShaderMaterial).set_shader_parameter('zoom_factor', transform.x.x)
		(grid.material as ShaderMaterial).set_shader_parameter('offset', transform.origin)


		if is_equal_approx(transform.origin.x, pos.x):
			set_physics_process(false)
			ignore_process = false


# drains the batched-show queue under SHOW_BUDGET_USEC each frame; sorts
# farthest-first so pop_back shows the closest-to-center vcnodes first
# checks virtual cnode visibility; _force=true bypasses the pos/zoom throttle
# (lerp settle, route change)
func get_rect() -> Rect2:
	return Rect2(
		transform.origin / -transform.x.x,
		(get_parent() as Control).size / transform.x.x
	)


func get_relative_vec2(_pos: Vector2) -> Vector2:
	return (_pos - global_position) / transform.x.x


func go_to(_pos: Vector2) -> void:
	pos = _pos * (-transform.x)
	set_physics_process(true)


func go_to_center(_pos: Vector2) -> void:
	pos = (_pos * (-transform.x.x)) + (get_parent().size / 2)
	ignore_process = true
	set_physics_process(true)


# centers camera with optional zoom


func go_to_center_with_zoom(_pos: Vector2, _target_zoom: float = -1) -> void:
	var zoom_to_use: float = _target_zoom if _target_zoom > 0 else transform.x.x
	zoom_to_use = clamp(zoom_to_use, MIN_ZOOM, MAX_ZOOM)

	pos = (_pos * (-zoom_to_use)) + (get_parent().size / 2)

	if _target_zoom > 0:
		target_zoom = zoom_to_use
		t_x = Vector2(target_zoom, 0)
		t_y = Vector2(0, target_zoom)
		_update_zoom_label()

	ignore_process = true
	set_physics_process(true)

# drains the batched-show queue under SHOW_BUDGET_USEC each frame; sorts
# farthest-first so pop_back shows the closest-to-center vcnodes first

func _update_zoom_label() -> void:
	if not is_global_cam:
		return
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global or not global.HENGO_ROOT:
		return
	var label: Label = global.HENGO_ROOT.get_node_or_null('%ZoomLabel') as Label
	if label:
		label.text = 'Zoom: %d%%' % int(round(target_zoom * 100))