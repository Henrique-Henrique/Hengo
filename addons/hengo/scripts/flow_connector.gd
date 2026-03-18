@tool
class_name HenFlowConnector extends TextureRect

var id: StringName
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
	(Engine.get_singleton(&'Global') as HenGlobal).TOOLTIP.close()

	if not is_connected:
		texture = preload('res://addons/hengo/assets/images/flow_out.svg')


func _on_gui(_event: InputEvent) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if _event is InputEventMouseButton:
		if _event.pressed:
			if _event.button_index == MOUSE_BUTTON_LEFT:
				global.can_make_flow_connection = true
				global.CONNECTION_GUIDE.is_in_out = false
				global.CONNECTION_GUIDE.start(global.CAM.get_relative_vec2(self.global_position) + self.size / 2)
				global.CONNECTION_GUIDE.gradient.colors = [Color.GRAY, Color.GRAY]
		else:
			if _event.button_index == MOUSE_BUTTON_LEFT:
				if global.can_make_flow_connection and global.flow_connection_to_data.is_empty():
					(owner as HenCnode).request_flow_connetor_connection(id, get_global_mouse_position())
				elif global.can_make_flow_connection and not global.flow_connection_to_data.is_empty():
					create_flow_connection_request.emit()

				global.flow_connection_to_data.clear()
				global.can_make_flow_connection = false
				global.CONNECTION_GUIDE.end()
				global.TOOLTIP.close()
	elif _event is InputEventMouseMotion:
		global.TOOLTIP.go_to(get_global_mouse_position(), '{0} {1}'.format([HenEnums.TOOLTIP_TEXT.MOUSE_ICON, 'Left Click And Drag to Connect']))


func reset_signals(_vc: HenVirtualCNode, _flow: HenVCFlow):
	for signal_name: StringName in [
		'create_flow_connection_request'
	]:
		for connection: Dictionary in get_signal_connection_list(signal_name):
			@warning_ignore('unsafe_method_access')
			connection.signal.disconnect(connection.callable)

	create_flow_connection_request.connect(_flow.on_create_connection_request.bind(_vc))