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

var container: VBoxContainer
var toast_scene = preload('res://addons/hengo/scenes/utils/toast/toast.tscn')


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
	_update_container_offsets()


func _update_container_offsets() -> void:
	if not container:
		return

	var width: float = HenUtils.get_scaled_size(TOAST_WIDTH)
	var height: float = HenUtils.get_scaled_size(TOAST_HEIGHT)
	var margin: float = HenUtils.get_scaled_size(BASE_MARGIN)

	container.offset_left = - (width + margin)
	container.offset_top = - height
	container.offset_right = - margin
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
