@tool
extends PanelContainer

@onready var name_label: Label = %Name
@onready var bt: Button = %Bt
@onready var type_label: Label = %Type

var data: Dictionary

func _ready() -> void:
	bt.pressed.connect(_on_press)
	bt.gui_input.connect(_on_bt_gui_input)


func _on_bt_gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.double_click and mb.button_index == MOUSE_BUTTON_LEFT:
		_select()


func _on_press() -> void:
	var api: HenApi = Engine.get_singleton(&'API')
	var prop_arr: Array = api.get_native_props_as_data(data)
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')

	if not prop_arr.is_empty():
		signal_bus.request_code_search_show_list.emit(prop_arr, 2)

func _select() -> void:
	if not data.is_empty():
		var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
		signal_bus.request_code_search_select.emit(data)


func set_item_data(_data: Dictionary) -> void:
	data = _data
	name_label.text = _data.get(&'name', '')
	type_label.text = _data.get(&'_class_name', '')
