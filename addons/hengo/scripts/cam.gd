@tool
class_name HenCam extends Node2D

@export var grid: TextureRect

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

@onready var ref_point: Marker2D = get_node('RefPoint')
var initial: Vector2 = Vector2.ZERO


func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self):
		return
	update_settings()

	can_scroll = false
	var parent: Control = get_parent()

	parent.item_rect_changed.connect(_on_ui_size_changed)

	(grid.material as ShaderMaterial).set_shader_parameter('zoom_factor', transform.x.x)
	(grid.material as ShaderMaterial).set_shader_parameter('offset', transform.origin)

	
func _on_ui_size_changed() -> void:
	(grid.material as ShaderMaterial).set_shader_parameter('screen_size', get_parent().size)


func update_settings() -> void:
	MIN_ZOOM = ProjectSettings.get_setting(HenSettings.MIN_ZOOM_PATH, 1.0)
	MAX_ZOOM = ProjectSettings.get_setting(HenSettings.MAX_ZOOM_PATH, 2.0)
	ZOOM_INCREMENT = ProjectSettings.get_setting(HenSettings.ZOOM_INCREMENT_PATH, 0.15)
	ZOOM_RATE = ProjectSettings.get_setting(HenSettings.ZOOM_RATE_PATH, 12.0)

	MAX_ZOOM = MAX_ZOOM * EditorInterface.get_editor_scale()


func _input(event: InputEvent) -> void:
	if (Engine.get_singleton(&'Global') as HenGlobal).CAM == self:
		if event is InputEventMouseMotion:
			check_vc_action_menu()

			if (event as InputEventMouseMotion).button_mask == MOUSE_BUTTON_MASK_MIDDLE or \
			   (event as InputEventMouseMotion).button_mask == MOUSE_BUTTON_MASK_RIGHT:
				transform.origin += (event as InputEventMouseMotion).relative
				(grid.material as ShaderMaterial).set_shader_parameter('offset', transform.origin)
				set_physics_process(false)
				_check_virtual_cnodes()
		
		elif event is InputEventPanGesture:
			transform.origin -= (event as InputEventPanGesture).delta * 40
			(grid.material as ShaderMaterial).set_shader_parameter('offset', transform.origin)
			set_physics_process(false)
			_check_virtual_cnodes()

		elif event is InputEventMagnifyGesture:
			var zoom_amount = (event as InputEventMagnifyGesture).factor
			if zoom_amount > 1.0:
				_zoom_in((zoom_amount - 1.0) * 2.0)
			elif zoom_amount < 1.0:
				_zoom_out((1.0 - zoom_amount) * 2.0)

		elif event is InputEventMouseButton:
			if event.is_pressed():
				if can_scroll:
					if (event as InputEventMouseButton).button_index == MOUSE_BUTTON_WHEEL_UP:
						_zoom_in()
					if (event as InputEventMouseButton).button_index == MOUSE_BUTTON_WHEEL_DOWN:
						_zoom_out()


func _zoom_in(amount: float = ZOOM_INCREMENT) -> void:
	target_zoom = min(target_zoom + amount, MAX_ZOOM)
	_set_transform(get_global_mouse_position())


func _zoom_out(amount: float = ZOOM_INCREMENT) -> void:
	target_zoom = max(target_zoom - amount, MIN_ZOOM)
	_set_transform(get_global_mouse_position())


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
	if ignore_process or (Engine.get_singleton(&'Global') as HenGlobal).CAM == self:
		var factor: float = ZOOM_RATE * _delta
		transform.x = lerp(transform.x, t_x, factor)
		transform.y = lerp(transform.y, t_y, factor)

		transform.origin = lerp(transform.origin, pos, factor)

		(grid.material as ShaderMaterial).set_shader_parameter('zoom_factor', transform.x.x)
		(grid.material as ShaderMaterial).set_shader_parameter('offset', transform.origin)

		_check_virtual_cnodes()

		if is_equal_approx(transform.origin.x, pos.x):
			set_physics_process(false)
			ignore_process = false


# checks virtual cnodes visibility
func _check_virtual_cnodes(_pos: Vector2 = transform.origin, _zoom: float = transform.x.x) -> void:
	var rect: Rect2 = Rect2(
		_pos / -_zoom, # position
		(get_parent() as Control).size / _zoom
	)
	var router: HenRouter = Engine.get_singleton(&'Router')

	for v_cnode: HenVirtualCNode in router.get_current_route_v_cnodes():
		v_cnode.check_visibility(rect)


func get_rect() -> Rect2:
	return Rect2(
		transform.origin / -transform.x.x, # position
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
	
	ignore_process = true
	set_physics_process(true)


func check_vc_action_menu() -> void:
	var router: HenRouter = Engine.get_singleton(&'Router')

	if router.current_route and is_instance_valid(router.current_route.get('ref')):
		for vc: HenVirtualCNode in router.get_current_route_v_cnodes():
			if not vc.is_showing_on_screen():
				continue

			var mouse_inside: bool = vc.check_mouse_inside()

			if vc.showing_action_menu and mouse_inside:
				continue

			vc.showing_action_menu = mouse_inside

			# if vc.showing_action_menu:
			# 	HenVCActionButtons.get_singleton().show_action(vc.cnode_ref)