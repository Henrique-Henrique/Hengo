@tool
class_name HenDashboardItem
extends PanelContainer

signal open_request(meta: Dictionary)
signal rename_request(meta: Dictionary, source: Control)
signal delete_request(meta: Dictionary)

const NAME_COLOR_NORMAL = Color(1, 1, 1, 0.78)
const NAME_COLOR_HOVER = Color(1, 1, 1, 1)

@onready var icon: TextureRect = $HBoxContainer/Icon
@onready var name_label: Label = %Name
@onready var rename_bt: Button = %Rename
@onready var delete_bt: Button = %Delete

var meta: Dictionary


func _ready() -> void:
	rename_bt.pressed.connect(func(): rename_request.emit(meta, rename_bt))
	delete_bt.pressed.connect(func(): delete_request.emit(meta))

	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_exit)

	gui_input.connect(_on_gui_input)
	name_label.add_theme_color_override('font_color', NAME_COLOR_NORMAL)

	HenUtils.tint_button(rename_bt, HenUtils.UI_COLORS.rename, false)
	HenUtils.tint_button(delete_bt, HenUtils.UI_COLORS.destructive, false)


func setup(_meta: Dictionary) -> void:
	meta = _meta
	name_label.text = meta.base_name

	if meta.has('type'):
		icon.texture = HenUtils.get_icon_texture(meta.type)
		icon.modulate = HenUtils.get_type_parent_color(meta.type, 1., Color.WHITE).lightened(.3)

	if meta.has('time'):
		%Time.text = _format_time(meta.time)


func _format_time(unix_time: int) -> String:
	# show relative time when recent, fall back to short date otherwise
	var now: int = int(Time.get_unix_time_from_system())
	var diff: int = now - unix_time

	if diff < 60:
		return 'now'
	if diff < 3600:
		return '%dm' % (diff / 60)
	if diff < 86400:
		return '%dh' % (diff / 3600)
	if diff < 604800:
		return '%dd' % (diff / 86400)

	var d: Dictionary = Time.get_datetime_dict_from_unix_time(unix_time)
	return '%02d/%02d' % [d.day, d.month]


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			open_request.emit(meta)


func _on_hover() -> void:
	name_label.add_theme_color_override('font_color', NAME_COLOR_HOVER)


func _on_exit() -> void:
	name_label.add_theme_color_override('font_color', NAME_COLOR_NORMAL)
