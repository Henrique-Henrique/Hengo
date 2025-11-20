@tool
class_name HenToastView extends PanelContainer

@onready var label: Label = $VBox/Content/Label
@onready var icon_rect: TextureRect = $VBox/Content/Icon
@onready var progress: ProgressBar = $VBox/Progress

var types = {
	HenToast.MessageType.INFO: {
		color = Color.DODGER_BLUE,
		icon = preload("res://addons/hengo/assets/new_icons/info.svg")
	},
	HenToast.MessageType.SUCCESS: {
		color = Color.SPRING_GREEN,
		icon = preload("res://addons/hengo/assets/new_icons/circle-check.svg")
	},
	HenToast.MessageType.ERROR: {
		color = Color.TOMATO,
		icon = preload("res://addons/hengo/assets/new_icons/circle-slash.svg")
	}
}

# initializes ui elements based on type and schedules the animation
func setup(text: String, type: HenToast.MessageType = HenToast.MessageType.INFO, duration: float = 4.0):
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	
	label.text = text

	var terminal_text: String = ''

	match type:
		HenToast.MessageType.INFO:
			terminal_text = HenUtils.get_building_text(text)
		HenToast.MessageType.ERROR:
			terminal_text = HenUtils.get_error_text(text)
		HenToast.MessageType.SUCCESS:
			terminal_text = HenUtils.get_success_text(text)

	signal_bus.set_terminal_text.emit.call_deferred(terminal_text)
	
	if type in types:
		var config = types.get(type as HenToast.MessageType, 0)
		progress.modulate = config.color
		icon_rect.texture = config.icon
		icon_rect.modulate = config.color
		get('theme_override_styles/panel').bg_color = Color(config.color, .1)

	modulate.a = 0.0
	scale = Vector2(0.9, 0.9)
	
	_animate_entry.call_deferred(duration)


# handles the elastic entrance, progress bar and exit sequence
func _animate_entry(duration):
	# sets pivot to center for correct scaling effect
	pivot_offset = size / 2
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, 'scale', Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, 'modulate:a', 1.0, 0.3)
	tween.tween_property(progress, 'value', 0.0, duration).set_trans(Tween.TRANS_LINEAR)
	
	var exit_tween = create_tween()
	exit_tween.tween_interval(duration)
	exit_tween.tween_property(self, 'modulate:a', 0.0, 0.3)
	exit_tween.parallel().tween_property(self, 'scale', Vector2(0.9, 0.9), 0.3)
	exit_tween.tween_callback(queue_free)