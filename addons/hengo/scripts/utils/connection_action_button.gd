@tool
class_name HenConnectionActionButton extends PanelContainer

enum ActionType {CONNECT, DISCONNECT}
enum PortType {INPUT, OUTPUT, FLOW_INPUT, FLOW_OUTPUT}

const ICON_PLUG = preload('res://addons/hengo/assets/new_icons/plug.svg')
const ICON_UNPLUG = preload('res://addons/hengo/assets/new_icons/unplug.svg')

var action_type: ActionType
var port_type: PortType
var port_id: StringName
var port_io_type: StringName
var vc_ref: HenVirtualCNode


func _ready() -> void:
	gui_input.connect(_on_gui)


# configures the button for a specific port
func configure(_vc: HenVirtualCNode, _port_type: PortType, _port_id: StringName, _is_connected: bool, _io_type: StringName = &'') -> void:
	vc_ref = _vc
	port_type = _port_type
	port_id = _port_id
	port_io_type = _io_type

	var icon_node: TextureRect = get_node('Icon')
	
	if _is_connected:
		action_type = ActionType.DISCONNECT
		icon_node.texture = ICON_UNPLUG
		modulate = Color.WHITE
		self_modulate = Color(0.75, 0.35, 0.35)
		icon_node.modulate = Color(1.0, 0.9, 0.9)
	else:
		action_type = ActionType.CONNECT
		icon_node.texture = ICON_PLUG
		modulate = Color.WHITE
		self_modulate = Color(0.35, 0.75, 0.45)
		icon_node.modulate = Color(0.9, 1.0, 0.9)


func animate_show() -> void:
	scale = Vector2(0.8, 0.8)
	modulate.a = 0.0
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self , 'scale', Vector2.ONE, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self , 'modulate:a', 1.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _on_gui(_event: InputEvent) -> void:
	if not _event is InputEventMouseButton:
		return

	var e: InputEventMouseButton = _event

	if not e.pressed or e.button_index != MOUSE_BUTTON_LEFT:
		return

	if action_type == ActionType.CONNECT:
		_handle_connect()
	else:
		_handle_disconnect()


func _handle_connect() -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()

	match port_type:
		PortType.INPUT:
			vc_ref.request_io_connection(&'in', port_id, mouse_pos, port_io_type)
		PortType.OUTPUT:
			vc_ref.request_io_connection(&'out', port_id, mouse_pos, port_io_type)
		PortType.FLOW_INPUT:
			vc_ref.request_flow_connector_connection(port_id, mouse_pos)
		PortType.FLOW_OUTPUT:
			vc_ref.request_flow_connector_connection(port_id, mouse_pos)

	HenVCActionButtons.get_singleton().hide_action()


func _handle_disconnect() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	match port_type:
		PortType.INPUT:
			var connection_cmd = vc_ref.get_input_connection_command(port_id, global.SAVE_DATA)
			if connection_cmd:
				global.history.create_action('Remove Connection')
				global.history.add_do_method(connection_cmd.remove)
				global.history.add_undo_method(connection_cmd.add)
				global.history.commit_action()
		PortType.OUTPUT:
			# outputs can have multiple connections, remove all
			pass
		PortType.FLOW_INPUT:
			var flow_cmd = vc_ref.get_flow_input_connection_command(port_id)
			if flow_cmd:
				global.history.create_action('Remove Flow Connection')
				global.history.add_do_method(flow_cmd.remove)
				global.history.add_undo_method(flow_cmd.add)
				global.history.commit_action()
		PortType.FLOW_OUTPUT:
			var flow_cmd = vc_ref.get_flow_output_connection_command(port_id)
			if flow_cmd:
				global.history.create_action('Remove Flow Connection')
				global.history.add_do_method(flow_cmd.remove)
				global.history.add_undo_method(flow_cmd.add)
				global.history.commit_action()

	HenVCActionButtons.get_singleton().hide_action()
