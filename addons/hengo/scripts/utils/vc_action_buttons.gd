@tool
class_name HenVCActionButtons extends Control

const ADD_ICON = preload('res://addons/hengo/assets/icons/menu/plus.svg')
const REMOVE_ICON = preload('res://addons/hengo/assets/icons/menu/x.svg')

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
			input.global_position.x - 50,
			input.global_position.y + input.size.y / 4
		))

		idx += 1


	for output: HenCnodeInOut in _vc.get_node('%OutputContainer').get_children():
		if not output.visible:
			continue

		set_bt_config(ActionInfo.new(
			Type.OUTPUT,
			ActionType.DISCONNECT if _vc.virtual_ref.output_has_connection(output.input_ref.id) else ActionType.CONNECT
		), get_child(idx), Vector2(
			output.global_position.x + output.size.x + 15,
			output.global_position.y + output.size.y / 4
		))

		idx += 1


	for from_flow: HenFromFlow in _vc.get_node('%FromFlowContainer').get_children():
		@warning_ignore('unsafe_property_access')
		if not from_flow.visible:
			continue

		var arrow: TextureRect = from_flow.get_node('%Arrow') as TextureRect

		set_bt_config(ActionInfo.new(
			Type.FROM_FLOW,
			ActionType.CONNECT
		), get_child(idx), Vector2(
			arrow.global_position.x - arrow.texture.get_size().x,
			arrow.global_position.y - 30
		))

		idx += 1


	for flow in _vc.get_node('%FlowContainer').get_children():
		@warning_ignore('unsafe_property_access')
		if not flow.visible:
			continue

		var connector: HenFlowConnector = flow.get_node('FlowSlot/Control/Connector')

		set_bt_config(ActionInfo.new(
			Type.FLOW,
			ActionType.CONNECT
		), get_child(idx), Vector2(
			connector.global_position.x + connector.size.x / 4,
			connector.global_position.y + 50
		))

		idx += 1


func hide_action() -> void:
	visible = false


func set_bt_config(_action: ActionInfo, _bt: Button, _pos: Vector2) -> void:
	_bt.visible = true
	_bt.global_position = _pos

	match _action.action_type:
		ActionType.CONNECT:
			_bt.icon = ADD_ICON
		ActionType.DISCONNECT:
			_bt.icon = REMOVE_ICON


static func get_singleton() -> HenVCActionButtons:
	return HenGlobal.HENGO_ROOT.get_node('%VCActionButtons') as HenVCActionButtons
