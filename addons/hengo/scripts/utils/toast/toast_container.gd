@tool
class_name HenToast extends Control

enum MessageType {
    INFO,
    ERROR,
    SUCCESS
}

const MAX_TOASTS = 10
const TOAST_WIDTH = 300
const TOAST_HEIGHT = 500
const BASE_MARGIN = 20
const SIDEBAR_GAP = 0

var container: VBoxContainer
var toast_scene = preload('res://addons/hengo/scenes/utils/toast/toast.tscn')
var right_sidebar: Control

# configures the container to grow backwards from the bottom right corner
func _ready():
	container = VBoxContainer.new()
	add_child(container)
	
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.anchor_left = 1.0
	container.anchor_top = 1.0
	container.anchor_right = 1.0
	container.anchor_bottom = 1.0
	container.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	container.grow_vertical = Control.GROW_DIRECTION_BEGIN
	container.alignment = BoxContainer.ALIGNMENT_END
	_connect_sidebar_signals()
	_update_container_offsets()


func _connect_sidebar_signals() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global:
		return

	right_sidebar = global.RIGHT_SIDE_BAR
	if not right_sidebar:
		return

	if not right_sidebar.resized.is_connected(_on_sidebar_layout_changed):
		right_sidebar.resized.connect(_on_sidebar_layout_changed)

	if not right_sidebar.visibility_changed.is_connected(_on_sidebar_layout_changed):
		right_sidebar.visibility_changed.connect(_on_sidebar_layout_changed)


func _on_sidebar_layout_changed() -> void:
	call_deferred('_update_container_offsets')


func _get_right_offset() -> float:
	var margin: float = HenUtils.get_scaled_size(BASE_MARGIN)
	if not is_instance_valid(right_sidebar):
		return margin

	if not right_sidebar.is_visible_in_tree():
		return margin

	var sidebar_left_global_x: float = right_sidebar.global_position.x
	var local_sidebar_left_x: float = sidebar_left_global_x - global_position.x
	var gap: float = HenUtils.get_scaled_size(SIDEBAR_GAP)
	return maxf((size.x - local_sidebar_left_x) + gap, margin)


func _update_container_offsets() -> void:
	if not container:
		return

	var width: float = HenUtils.get_scaled_size(TOAST_WIDTH)
	var height: float = HenUtils.get_scaled_size(TOAST_HEIGHT)
	var margin: float = HenUtils.get_scaled_size(BASE_MARGIN)
	var right_offset: float = _get_right_offset()

	container.offset_left = - (width + right_offset)
	container.offset_top = - height
	container.offset_right = - right_offset
	container.offset_bottom = - margin


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and container:
		_update_container_offsets()


# instantiates a new toast and removes the oldest one if limit is reached
func notify(_message: String, _type: MessageType = MessageType.INFO):
	_update_container_offsets()

	# prevents spamming by removing the oldest toast
	if container.get_child_count() >= MAX_TOASTS:
		container.get_child(0).queue_free()

	var toast: HenToastView = toast_scene.instantiate()
	container.add_child(toast)
	toast.setup(_message, _type)
