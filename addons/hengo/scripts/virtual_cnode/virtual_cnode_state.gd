class_name HenVirtualCNodeState extends RefCounted


var is_showing: bool = false
var can_delete: bool = true
var is_deleted: bool = false
var invalid: bool = false
var showing_action_menu: bool = false

signal cnode_need_update

func on_side_bar_deleted(_deleted: bool) -> void:
	invalid = _deleted
	cnode_need_update.emit()
