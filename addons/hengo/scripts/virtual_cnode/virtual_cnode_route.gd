class_name HenVirtualCNodeRoute extends Resource

@export var route: HenRouteData
@export var parent_route_id: String


func add_virtual_cnode_to_parent_route(_vc: HenVirtualCNode) -> void:
	if not parent_route_id:
		return
	
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	signal_bus.add_virtual_cnode_to_route.emit(parent_route_id, _vc)
	

func remove_virtual_cnode_from_parent_route(_vc: HenVirtualCNode) -> void:
	if not parent_route_id:
		return
	
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	signal_bus.remove_virtual_cnode_from_route.emit(parent_route_id, _vc)