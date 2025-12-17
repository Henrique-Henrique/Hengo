@tool
class_name HenRouteData extends RefCounted

var name: String
var type: HenRouter.ROUTE_TYPE
var id: String
var virtual_cnode_list: Array[HenVirtualCNode]
var virtual_sub_type_vc_list: Array[HenVirtualCNode]

var signal_enter: HenVirtualCNode
var input_ref: WeakRef
var output_ref: WeakRef


func _init(_name: String, _type: HenRouter.ROUTE_TYPE, _id: String) -> void:
	name = _name
	type = _type
	id = _id