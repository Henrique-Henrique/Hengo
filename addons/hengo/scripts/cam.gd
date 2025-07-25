@tool
class_name HenCam extends Node2D

@export var grid: TextureRect

var target_zoom: float = 1.

const MIN_ZOOM: float = .2
const MAX_ZOOM: float = 1.5
const ZOOM_INCREMENT: float = .15
const ZOOM_RATE: float = 12.

var t_x: Vector2 = Vector2(1, 0)
var t_y: Vector2 = Vector2(0, 1)
var pos: Vector2 = Vector2.ZERO

var ignore_process: bool = false

var can_scroll: bool = true

@onready var ref_point: Marker2D = get_node('RefPoint')
var initial: Vector2 = Vector2.ZERO

# private
#
func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self):
		return
	
	can_scroll = false
	var parent: Panel = get_parent()

	parent.item_rect_changed.connect(_on_ui_size_changed)

	(grid.material as ShaderMaterial).set_shader_parameter('zoom_factor', transform.x.x)
	(grid.material as ShaderMaterial).set_shader_parameter('offset', transform.origin)

	
func _on_ui_size_changed() -> void:
	(grid.material as ShaderMaterial).set_shader_parameter('screen_size', get_parent().size)


func _input(event: InputEvent) -> void:
	if HenGlobal.CAM == self:
		if event is InputEventMouseMotion:
			check_vc_action_menu()

			if (event as InputEventMouseMotion).button_mask == MOUSE_BUTTON_MASK_MIDDLE:
				transform.origin += (event as InputEventMouseMotion).relative
				(grid.material as ShaderMaterial).set_shader_parameter('offset', transform.origin)
				set_physics_process(false)
				_check_virtual_cnodes()
		
		elif event is InputEventMouseButton:
			if event.is_pressed():
				if can_scroll:
					if (event as InputEventMouseButton).button_index == MOUSE_BUTTON_WHEEL_UP:
						_zoom_in()
					if (event as InputEventMouseButton).button_index == MOUSE_BUTTON_WHEEL_DOWN:
						_zoom_out()


func _zoom_in() -> void:
	target_zoom = min(target_zoom + ZOOM_INCREMENT, MAX_ZOOM)
	_set_transform(get_global_mouse_position())


func _zoom_out() -> void:
	target_zoom = max(target_zoom - ZOOM_INCREMENT, MIN_ZOOM)
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
	if ignore_process or HenGlobal.CAM == self:
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


# checking virtual cnodes positions
func _check_virtual_cnodes(_pos: Vector2 = transform.origin, _zoom: float = transform.x.x) -> void:
	var rect: Rect2 = Rect2(
		_pos / -_zoom, # position
		(get_parent() as Panel).size / _zoom
	)


	if HenRouter.current_route:
		for v_cnode: HenVirtualCNode in HenRouter.current_route.ref.virtual_cnode_list:
			v_cnode.check_visibility(rect)


func get_rect() -> Rect2:
	return Rect2(
		transform.origin / -transform.x.x, # position
		(get_parent() as Panel).size / transform.x.x
	)

# public
#
func get_relative_vec2(_pos: Vector2) -> Vector2:
	return (_pos - global_position) / transform.x.x


func go_to(_pos: Vector2) -> void:
	pos = _pos * (-transform.x)
	set_physics_process(true)


func go_to_center(_pos: Vector2) -> void:
	pos = (_pos * (-transform.x.x)) + (get_parent().size / 2)
	ignore_process = true
	set_physics_process(true)


func check_vc_action_menu() -> void:
	if HenRouter.current_route:
		for vc: HenVirtualCNode in HenRouter.current_route.ref.virtual_cnode_list:
			if not vc.is_showing:
				continue

			var mouse_inside: bool = vc.check_mouse_inside()

			if vc.showing_action_menu and mouse_inside:
				continue

			vc.showing_action_menu = mouse_inside

			if vc.showing_action_menu:
				HenVCActionButtons.get_singleton().show_action(vc.cnode_ref)