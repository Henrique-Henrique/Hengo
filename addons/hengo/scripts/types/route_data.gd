@tool
class_name HenRouteData extends Resource

@export var name: String
@export var type: HenRouter.ROUTE_TYPE
@export var id: String
@export var virtual_cnode_list: Array[HenVirtualCNode]
@export var virtual_sub_type_vc_list: Array[HenVirtualCNode]

func _init() -> void:
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')

	if not signal_bus.add_virtual_cnode_to_route.is_connected(add_virtual_cnode_to_route):
		signal_bus.add_virtual_cnode_to_route.connect(add_virtual_cnode_to_route)
	
	if not signal_bus.remove_virtual_cnode_from_route.is_connected(remove_virtual_cnode_from_route):
		signal_bus.remove_virtual_cnode_from_route.connect(remove_virtual_cnode_from_route)


static func create(_name: String, _type: HenRouter.ROUTE_TYPE, _id: String) -> HenRouteData:
	var route: HenRouteData = HenRouteData.new()
	route.name = _name
	route.type = _type
	route.id = _id
	return route


func add_virtual_cnode_to_route(_id: String, _vc: HenVirtualCNode) -> void:
	if not id == _id:
		return
	
	if not virtual_cnode_list.has(_vc):
		virtual_cnode_list.append(_vc)
	

func remove_virtual_cnode_from_route(_id: String, _vc: HenVirtualCNode) -> void:
	if not id == _id:
		return
	
	virtual_cnode_list.erase(_vc)