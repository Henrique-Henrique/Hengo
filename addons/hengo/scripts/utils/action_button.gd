@tool
class_name HenActionButton extends Button

const ADD_ICON = preload('res://addons/hengo/assets/icons/plus.svg')
const REMOVE_ICON = preload('res://addons/hengo/assets/icons/menu/x.svg')

var action: HenVCActionButtons.ActionInfo

func set_icon() -> void:
	match action.action_type:
		HenVCActionButtons.ActionType.CONNECT:
			icon = ADD_ICON
		HenVCActionButtons.ActionType.DISCONNECT:
			icon = REMOVE_ICON
	
	reset_size()