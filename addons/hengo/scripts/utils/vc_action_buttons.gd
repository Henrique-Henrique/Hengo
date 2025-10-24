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
	visible = true


func hide_action() -> void:
	visible = false


func set_bt_config(_action: ActionInfo, _bt: HenActionButton, _pos: Vector2) -> void:
	_bt.visible = true
	_bt.action = _action
	_bt.global_position = _pos
	_bt.set_icon()


static func get_singleton() -> HenVCActionButtons:
	return (Engine.get_singleton(&'Global') as HenGlobal).HENGO_ROOT.get_node('%VCActionButtons') as HenVCActionButtons
