@tool
extends PanelContainer

@onready var name_label: Label = %Name
@onready var bt: Button = %Bt
@onready var type_label: Label = %Type

var data: Dictionary

func _ready() -> void:
	bt.gui_input.connect(_on_bt_gui_input)


func _on_bt_gui_input(_event: InputEvent) -> void:
	if _event is InputEventMouseButton:
		var mb := _event as InputEventMouseButton

		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if (data.has('input_io_idx') or data.has('output_io_idx') or data.get('force_valid', false)) and not data.has('recursive_props'):
				_select()
			else:
				_on_press()
		if mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			_on_press()


func _on_press() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not is_instance_valid(global.CODE_SEARCH):
		return

	var prop_arr: Array = data.get('recursive_props', [])
	if prop_arr.is_empty():
		prop_arr = global.CODE_SEARCH.get_native_props_as_data(data)

	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')

	if prop_arr.size() == 1:
		signal_bus.request_code_search_select.emit(prop_arr[0])
	else:
		signal_bus.request_code_search_show_list.emit(prop_arr, 2)


func _select() -> void:
	if not data.is_empty():
		var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
		signal_bus.request_code_search_select.emit(data)


func set_item_data(_data: Dictionary) -> void:
	data = _data
	name_label.text = _data.get(&'name', '')
	type_label.text = _data.get(&'_class_name', '')

	if data.has('input_io_idx') or data.has('output_io_idx') or data.get('is_match', false) or data.get('force_valid', false):
		modulate.a = 1.0
	else:
		modulate.a = 0.6
