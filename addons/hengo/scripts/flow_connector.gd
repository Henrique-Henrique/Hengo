@tool
class_name HenFlowConnector extends TextureRect

@export var type: String = 'cnode'

var id: int = 0
var is_connected: bool = false

signal create_flow_connection_request

func _ready():
	gui_input.connect(_on_gui)
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_exit)


func _on_hover() -> void:
	if not is_connected:
		texture = preload('res://addons/hengo/assets/icons/flow_arrow_hover.svg')


func _on_exit() -> void:
	HenGlobal.TOOLTIP.close()

	if not is_connected:
		texture = preload('res://addons/hengo/assets/images/flow_out.svg')


func _on_gui(_event: InputEvent) -> void:
	if _event is InputEventMouseButton:
		if _event.pressed:
			if _event.button_index == MOUSE_BUTTON_LEFT:
				HenGlobal.can_make_flow_connection = true
				HenGlobal.CONNECTION_GUIDE.is_in_out = false
				HenGlobal.CONNECTION_GUIDE.start(HenGlobal.CAM.get_relative_vec2(self.global_position) + self.size / 2)
				HenGlobal.CONNECTION_GUIDE.gradient.colors = [Color.GRAY, Color.GRAY]
		else:
			if _event.button_index == MOUSE_BUTTON_LEFT:
				if HenGlobal.can_make_flow_connection and HenGlobal.flow_connection_to_data.is_empty():
					var method_list: HenMethodPicker = preload('res://addons/hengo/scenes/utils/method_picker.tscn').instantiate()
					method_list.start(HenGlobal.script_config.type, get_global_mouse_position(), true, 'out', {
						from_flow_connector = self
					})
					HenGlobal.GENERAL_POPUP.get_parent().show_content(method_list, 'Pick a Method', get_global_mouse_position())
				elif HenGlobal.can_make_flow_connection and not HenGlobal.flow_connection_to_data.is_empty():
					create_flow_connection_request.emit()

				HenGlobal.flow_connection_to_data.clear()
				HenGlobal.can_make_flow_connection = false
				HenGlobal.CONNECTION_GUIDE.end()
				HenGlobal.TOOLTIP.close()
	elif _event is InputEventMouseMotion:
		HenGlobal.TOOLTIP.go_to(get_global_mouse_position(), '{0} {1}'.format([HenEnums.TOOLTIP_TEXT.MOUSE_ICON, 'Left Click And Drag to Connect']))


func reset_signals(_flow: HenVCFlow):
	for signal_name: StringName in [
		'create_flow_connection_request'
	]:
		for connection: Dictionary in get_signal_connection_list(signal_name):
			@warning_ignore('unsafe_method_access')
			connection.signal.disconnect(connection.callable)

	create_flow_connection_request.connect(_flow.on_create_connection_request)