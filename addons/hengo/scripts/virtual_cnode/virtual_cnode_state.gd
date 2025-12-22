class_name HenVirtualCNodeState extends Resource

@export var can_delete: bool = true
@export var invalid: bool = false

var is_showing: bool = false
var is_deleted: bool = false
var showing_action_menu: bool = false

signal cnode_need_update

func on_side_bar_deleted(_deleted: bool) -> void:
	invalid = _deleted
	cnode_need_update.emit()
