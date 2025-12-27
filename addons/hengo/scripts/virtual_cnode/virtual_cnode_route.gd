@tool
@abstract
class_name HenVirtualCNodeRoute extends HenVirtualCNodeVisual

@export var parent_route_id: Variant


func get_route() -> HenRouteData:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	return global.SAVE_DATA.get_route(str(id))


func get_parent_route() -> HenRouteData:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	print(global.SAVE_DATA.routes)
	return global.SAVE_DATA.get_route(str(parent_route_id))


func add_virtual_cnode_to_parent_route() -> void:
	var route: HenRouteData = get_parent_route()

	if not route:
		return

	route.add_virtual_cnode_to_route(self)
	

func remove_virtual_cnode_from_parent_route() -> void:
	var route: HenRouteData = get_parent_route()
	print(parent_route_id)
	prints(parent_route_id, route)

	if not route:
		return

	route.remove_virtual_cnode_from_route(self)