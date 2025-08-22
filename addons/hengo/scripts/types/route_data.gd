@tool
class_name HenRouteData extends RefCounted

var name: String
var type: HenRouter.ROUTE_TYPE
var id: String
var ref: WeakRef


func _init(_name: String, _type: HenRouter.ROUTE_TYPE, _id: String, _ref: WeakRef) -> void:
	name = _name
	type = _type
	id = _id
	ref = _ref


func get_ref() -> Variant:
	if not ref:
		return null
	
	return ref.get_ref()