@tool
class_name HenFromFlow extends PanelContainer

var id: int

signal hover

func _ready() -> void:
	mouse_entered.connect(_on_hover)


func _on_hover() -> void:
	if not (Engine.get_singleton(&'Global') as HenGlobal).can_make_flow_connection: return
	hover.emit(id)


func reset_signals(_flow: HenVCFlow):
	for signal_name: StringName in [
		'hover'
	]:
		for connection: Dictionary in get_signal_connection_list(signal_name):
			@warning_ignore('unsafe_method_access')
			connection.signal.disconnect(connection.callable)

	hover.connect(_flow.on_flow_input_hover)