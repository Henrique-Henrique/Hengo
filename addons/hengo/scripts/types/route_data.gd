@tool
class_name HenRouteData extends Resource

@export var id: StringName
@export var name: String
@export var type: HenRouter.ROUTE_TYPE
@export var virtual_cnode_list: Array
@export var virtual_sub_type_vc_list: Array


static func create(_name: String, _type: HenRouter.ROUTE_TYPE, _id: StringName) -> HenRouteData:
	var route: HenRouteData = HenRouteData.new()
	route.name = _name
	route.type = _type
	route.id = _id
	return route


func add_virtual_cnode_to_route(_vc: HenVirtualCNode) -> void:
	if not virtual_cnode_list.has(_vc):
		virtual_cnode_list.append(_vc)
	

func remove_virtual_cnode_from_route(_vc: HenVirtualCNode) -> void:
	virtual_cnode_list.erase(_vc)