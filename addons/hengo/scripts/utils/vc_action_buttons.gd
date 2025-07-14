@tool
class_name HenVCActionButtons extends Control

enum Type {
	INPUT,
	OUTPUT,
	FROM_FLOW,
	FLOW
}

enum ActionType {
	CONNECT,
	DISCONNECT,
}

class ActionInfo:
	var type: Type
	var action_type: ActionType

	func _init(_type: Type, _action_type: ActionType) -> void:
		type = _type
		action_type = _action_type


func show_action(_vc: HenCnode) -> void:
	if not _vc or not _vc.virtual_ref:
		return
	
	visible = true
	
	for bt: Button in get_children():
		bt.visible = false

	var idx: int = 0


	for input: HenCnodeInOut in _vc.get_node('%InputContainer').get_children():
		if not input.visible:
			continue
		
		set_bt_config(ActionInfo.new(
			Type.INPUT,
			ActionType.DISCONNECT if _vc.virtual_ref.input_has_connection(input.input_ref.id) else ActionType.CONNECT
		), get_child(idx), Vector2(
			input.global_position.x,
			input.global_position.y
		) + Vector2(-50, input.size.y / 4) * HenGlobal.CAM.transform.x.x)

		idx += 1


	for output: HenCnodeInOut in _vc.get_node('%OutputContainer').get_children():
		if not output.visible:
			continue

		set_bt_config(ActionInfo.new(
			Type.OUTPUT,
			ActionType.DISCONNECT if _vc.virtual_ref.output_has_connection(output.input_ref.id) else ActionType.CONNECT
		), get_child(idx), Vector2(
			output.global_position.x,
			output.global_position.y
		) + Vector2(output.size.x + 20, output.size.y / 4) * HenGlobal.CAM.transform.x.x)

		idx += 1


	for from_flow: HenFromFlow in _vc.get_node('%FromFlowContainer').get_children():
		@warning_ignore('unsafe_property_access')
		if not from_flow.visible:
			continue

		var arrow: TextureRect = from_flow.get_node('%Arrow') as TextureRect

		set_bt_config(ActionInfo.new(
			Type.FROM_FLOW,
			ActionType.DISCONNECT if _vc.virtual_ref.from_flow_has_connection(from_flow.id) else ActionType.CONNECT
		), get_child(idx), Vector2(
			arrow.global_position.x,
			arrow.global_position.y
		) + Vector2(-arrow.texture.get_size().x / 1.2, -30) * HenGlobal.CAM.transform.x.x)

		idx += 1


	for flow in _vc.get_node('%FlowContainer').get_children():
		@warning_ignore('unsafe_property_access')
		if not flow.visible:
			continue

		var connector: HenFlowConnector = flow.get_node('FlowSlot/Control/Connector')

		set_bt_config(ActionInfo.new(
			Type.FLOW,
			ActionType.DISCONNECT if _vc.virtual_ref.flow_has_connection(connector.id) else ActionType.CONNECT
		), get_child(idx), Vector2(
			connector.global_position.x,
			connector.global_position.y
		) + Vector2(connector.size.x / 6, 50) * HenGlobal.CAM.transform.x.x)

		idx += 1


func hide_action() -> void:
	visible = false


func set_bt_config(_action: ActionInfo, _bt: HenActionButton, _pos: Vector2) -> void:
	_bt.visible = true
	_bt.action = _action
	_bt.global_position = _pos
	_bt.set_icon()


static func get_singleton() -> HenVCActionButtons:
	return HenGlobal.HENGO_ROOT.get_node('%VCActionButtons') as HenVCActionButtons
