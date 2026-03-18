@tool
class_name HenDashboardItem
extends PanelContainer

signal open_request(meta: Dictionary)
signal rename_request(meta: Dictionary)
signal delete_request(meta: Dictionary)

@onready var icon: TextureRect = $HBoxContainer/Icon
@onready var name_label: Label = %Name
@onready var rename_bt: Button = %Rename
@onready var delete_bt: Button = %Delete

var meta: Dictionary

func _ready() -> void:
	rename_bt.pressed.connect(func(): rename_request.emit(meta))
	delete_bt.pressed.connect(func(): delete_request.emit(meta))
	
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_exit)

	gui_input.connect(_on_gui_input)

func setup(_meta: Dictionary) -> void:
	meta = _meta
	name_label.text = meta.base_name
	
	self_modulate = HenUtils.get_type_parent_color(meta.type, 1., Color.WHITE).lightened(.5)

	if meta.has('type'):
		icon.texture = HenUtils.get_icon_texture(meta.type)
	
	if meta.has('time'):
		var time_dict: Dictionary = Time.get_datetime_dict_from_unix_time(meta.time)
		%Time.text = "%02d/%02d/%02d %02d:%02d" % [time_dict.day, time_dict.month, time_dict.year, time_dict.hour, time_dict.minute]

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			open_request.emit(meta)

func _on_hover() -> void:
	var style: StyleBoxFlat = get_theme_stylebox('panel').duplicate()

	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(1, 1, 1, .6)
	
	add_theme_stylebox_override('panel', style)

func _on_exit() -> void:
	remove_theme_stylebox_override('panel')
