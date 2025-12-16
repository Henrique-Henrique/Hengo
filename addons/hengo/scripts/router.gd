@tool
class_name HenRouter extends Node


enum ROUTE_TYPE {
	BASE,
	STATE,
	FUNC,
	SIGNAL,
	INPUT,
	MACRO
}

var current_route: HenRouteData
var comment_reference: Dictionary = {}


func get_current_route_v_cnodes() -> Array:
	if current_route:
		return current_route.virtual_cnode_list

	return []


func change_route(_route: HenRouteData) -> void:
	if current_route == _route:
		_centralize_cam()
		return


	if current_route:
		for v_cnode: HenVirtualCNode in get_current_route_v_cnodes():
			v_cnode.hide()

	var global: HenGlobal = Engine.get_singleton(&'Global')

	for line: HenConnectionLine in global.connection_line_pool:
		line.visible = false

	for connection: HenConnectionLine in global.connection_line_pool:
		connection.visible = false

	for flow_connection: HenFlowConnectionLine in global.flow_connection_line_pool:
		flow_connection.visible = false

	current_route = _route

	global.CAM._check_virtual_cnodes()
	global.SIDE_BAR.update()
	_centralize_cam()
	HenFormatter.format_current_route()


func _centralize_cam() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var vc: HenVirtualCNode = current_route.virtual_cnode_list[-1]

	if not vc:
		return

	global.CAM.go_to_center(vc.visual.position)
