@tool
class_name HenToast extends CanvasLayer

enum MessageType {
    INFO,
    ERROR,
    SUCCESS
}

const MAX_TOASTS = 10

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
	
	container.offset_left = -300
	container.offset_top = -500
	container.offset_right = -20
	container.offset_bottom = -20
	
	container.alignment = BoxContainer.ALIGNMENT_END


# instantiates a new toast and removes the oldest one if limit is reached
func notify(_message: String, _type: MessageType = MessageType.INFO):
	# prevents spamming by removing the oldest toast
	if container.get_child_count() >= MAX_TOASTS:
		container.get_child(0).queue_free()

	var toast: HenToastView = toast_scene.instantiate()
	container.add_child(toast)
	toast.setup(_message, _type)