@tool
@abstract
class_name HenVirtualCNodeState extends HenVirtualCNodeReference

@export var can_delete: bool = true
@export var invalid: bool = false

var is_showing: bool = false
var is_deleted: bool = false
var showing_action_menu: bool = false
var selected: bool = false

signal cnode_need_update

func on_side_bar_deleted(_deleted: bool) -> void:
	invalid = _deleted
	cnode_need_update.emit()


func is_showing_on_screen() -> bool:
	return is_showing and is_instance_valid(cnode_instance)