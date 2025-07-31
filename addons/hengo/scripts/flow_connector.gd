@tool
class_name HenFlowConnector extends TextureRect

@export var root: HenCnode
@export var type: String = 'cnode'

var id: int = 0
var connections_lines: Array = []
var is_connected: bool = false

func _ready():
	gui_input.connect(_on_gui)
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_exit)
	item_rect_changed.connect(_on_rect_change)


func _on_hover() -> void:
	if not is_connected:
		texture = preload('res://addons/hengo/assets/icons/flow_arrow_hover.svg')


func _on_exit() -> void:
	HenGlobal.TOOLTIP.close()

	if not is_connected:
		texture = preload('res://addons/hengo/assets/images/flow_out.svg')


# updating line
func _on_rect_change() -> void:
	for line in connections_lines:
		if line.to_cnode.is_inside_tree():
			line.update_line()

func _on_gui(_event: InputEvent) -> void:
	if _event is InputEventMouseButton:
		if _event.pressed:
			if _event.button_index == MOUSE_BUTTON_LEFT:
				HenGlobal.can_make_flow_connection = true
				HenGlobal.flow_cnode_from = root
				HenGlobal.CONNECTION_GUIDE.is_in_out = false
				HenGlobal.CONNECTION_GUIDE.start(HenGlobal.CAM.get_relative_vec2(self.global_position) + self.size / 2)
				HenGlobal.CONNECTION_GUIDE.gradient.colors = [Color.GRAY, Color.GRAY]
		else:
			if _event.button_index == MOUSE_BUTTON_LEFT:
				if HenGlobal.can_make_flow_connection and HenGlobal.flow_connection_to_data.is_empty():
					var connection: HenVCFlowConnectionReturn = (root.virtual_ref.get_ref() as HenVirtualCNode).flow.get_flow_connection(id)

					if connection:
						HenGlobal.history.create_action('Remove Flow Connection')
						HenGlobal.history.add_do_method(connection.remove)
						HenGlobal.history.add_undo_method(connection.add)
						HenGlobal.history.commit_action()

					var method_list = preload('res://addons/hengo/scenes/utils/method_picker.tscn').instantiate()
					method_list.start(HenGlobal.script_config.type, get_global_mouse_position(), true, 'out', {
						from_flow_connector = self
					})
					HenGlobal.GENERAL_POPUP.get_parent().show_content(method_list, 'Pick a Method', get_global_mouse_position())
				elif HenGlobal.can_make_flow_connection and not HenGlobal.flow_connection_to_data.is_empty():
					var connection: HenVCFlowConnectionReturn = create_virtual_connection(HenGlobal.flow_connection_to_data)
					
					if connection:
						HenGlobal.history.create_action('Add Connection')
						HenGlobal.history.add_do_method(connection.add)
						HenGlobal.history.add_do_reference(connection)
						HenGlobal.history.add_undo_method(connection.remove)
						HenGlobal.history.commit_action()


				HenGlobal.flow_connection_to_data = {}
				HenGlobal.can_make_flow_connection = false
				HenGlobal.flow_cnode_from = null
				HenGlobal.CONNECTION_GUIDE.end()
				HenGlobal.TOOLTIP.close()
	elif _event is InputEventMouseMotion:
		HenGlobal.TOOLTIP.go_to(get_global_mouse_position(), '{0} {1}'.format([HenEnums.TOOLTIP_TEXT.MOUSE_ICON, 'Left Click And Drag to Connect']))


func create_virtual_connection(_config: Dictionary) -> HenVCFlowConnectionReturn:
	return (root.virtual_ref.get_ref() as HenVirtualCNode).flow.add_flow_connection(
		id,
		_config.to_id,
		_config.to_cnode.virtual_ref
	)