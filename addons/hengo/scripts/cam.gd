@tool
extends Node2D

# imports
const _Global = preload('res://addons/hengo/scripts/global.gd')

var target_zoom: float = 1.

const MIN_ZOOM: float = .2
const MAX_ZOOM: float = 1.
const ZOOM_INCREMENT: float = .15
const ZOOM_RATE: float = 12.

var t_x: Vector2 = Vector2(1, 0)
var t_y: Vector2 = Vector2(0, 1)
var pos: Vector2 = Vector2.ZERO

# @onready var center_point: Panel = get_parent().get_node('%RefPoint')
@onready var ref_point: Marker2D = get_node('RefPoint')
var initial: Vector2 = Vector2.ZERO

# private
#
func _ready() -> void:
	var parent: Panel = get_parent()

	parent.item_rect_changed.connect(_on_ui_size_changed)

	((parent.get_child(0) as TextureRect).material as ShaderMaterial).set_shader_parameter('zoom_factor', transform.x.x)
	((parent.get_child(0) as TextureRect).material as ShaderMaterial).set_shader_parameter('offset', transform.origin)

	
func _on_ui_size_changed() -> void:
	((get_parent().get_child(0) as TextureRect).material as ShaderMaterial).set_shader_parameter('screen_size', get_parent().size)


func _input(event: InputEvent) -> void:
	if _Global.CAM == self:
		if event is InputEventMouseMotion:
			if (event as InputEventMouseMotion).button_mask == MOUSE_BUTTON_MASK_MIDDLE:
				transform.origin += (event as InputEventMouseMotion).relative

				((get_parent().get_child(0) as TextureRect).material as ShaderMaterial).set_shader_parameter('offset', transform.origin)
				set_physics_process(false)
		
		elif event is InputEventMouseButton:
			if event.is_pressed():
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
	if _Global.CAM == self:
		var factor: float = ZOOM_RATE * _delta
		transform.x = lerp(transform.x, t_x, factor)
		transform.y = lerp(transform.y, t_y, factor)

		transform.origin = lerp(transform.origin, pos, factor)

		((get_parent().get_child(0) as TextureRect).material as ShaderMaterial).set_shader_parameter('zoom_factor', transform.x.x)
		((get_parent().get_child(0) as TextureRect).material as ShaderMaterial).set_shader_parameter('offset', transform.origin)

		if is_equal_approx(transform.origin.x, pos.x):
			set_physics_process(false)


# public
#
func get_relative_vec2(_pos: Vector2) -> Vector2:
	return (_pos - global_position) / transform.x.x