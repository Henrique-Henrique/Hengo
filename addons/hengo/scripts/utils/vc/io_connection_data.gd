class_name CNodeInOutConnectionData extends RefCounted

var vc: HenVirtualCNode
var in_out: HenVCInOutData

func _init(_vc: HenVirtualCNode, _in_out: HenVCInOutData) -> void:
    vc = _vc
    in_out = _in_out