class_name HenVirtualCNodeState extends RefCounted


var is_showing: bool = false
var can_delete: bool = true
var is_deleted: bool = false
var invalid: bool = false
var showing_action_menu: bool = false

var vc: WeakRef

func _init(_vc: HenVirtualCNode) -> void:
	vc = weakref(_vc)


func on_side_bar_deleted(_deleted: bool) -> void:
	invalid = _deleted
	if vc.get_ref(): vc.get_ref().renderer.update()
