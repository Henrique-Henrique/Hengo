@tool
extends MarginContainer

@onready var name_label: Label = %Name
@onready var bt: Button = %Bt
@onready var type_label: Button = %Type
@onready var child_count: Label = $%ChildCount
@onready var container: PanelContainer = $%Container

var data: Dictionary

func _ready() -> void:
	name_label.add_theme_font_size_override('font_size', 15 * EditorInterface.get_editor_scale())
	type_label.add_theme_font_size_override('font_size', 12 * EditorInterface.get_editor_scale())
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
		print(JSON.stringify(data))
		var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
		signal_bus.request_code_search_select.emit(data)


func set_item_data(_data: Dictionary) -> void:
	data = _data
	name_label.text = _data.get(&'name', '')
	var _type: StringName = _data.get(&'_class_name', '')
	type_label.text = _type
	type_label.icon = HenUtils.get_icon_texture(_type)
	
	var color_base: Color = Color('#adadadff')

	var type_color: Color = HenUtils.get_type_parent_color(_type, 1, color_base)
	type_label.self_modulate = type_color

	var child_size: int = (data.get('recursive_props', []) as Array).size()

	container.self_modulate = Color(type_color, .5)

	if child_size > 1:
		child_count.self_modulate = type_color
		child_count.text = str(child_size)
	else:
		var return_type: StringName = _data.get(&'return_type', '')
		var global: HenGlobal = Engine.get_singleton(&'Global')

		if global.CODE_SEARCH:
			var con_type: StringName = global.CODE_SEARCH.get_connection_type()
		
			if con_type != "":
				return_type = con_type

			if return_type == "":
				if _type == &"Getter":
					var outputs: Array = (_data.get('data', {}) as Dictionary).get('outputs', [])
					if not outputs.is_empty():
						return_type = (outputs[0] as Dictionary).get('type', '')
				elif _type == &"Setter":
					var inputs: Array = (_data.get('data', {}) as Dictionary).get('inputs', [])
					for input in inputs:
						if not (input as Dictionary).get('is_ref', false):
							return_type = (input as Dictionary).get('type', '')
							break

		if return_type != "":
			child_count.visible = true
			child_count.self_modulate = HenUtils.get_type_parent_color(return_type, 1, color_base)
			child_count.text = return_type
		else:
			child_count.visible = false

	if data.has('input_io_idx') or data.has('output_io_idx') or data.get('is_match', false) or data.get('force_valid', false):
		modulate.a = 1.0
	else:
		modulate.a = 0.6
