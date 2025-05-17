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

static var current_route: Dictionary = {} # name: String, type: ROUTE_TYPE, id: String
static var line_route_reference: Dictionary = {}
static var comment_reference: Dictionary = {}

static func get_current_route_v_cnodes() -> Array:
	if current_route:
		return current_route.ref.virtual_cnode_list

	return []

static func change_route(_route: Dictionary) -> void:
	if current_route == _route:
		return

	if current_route:
		for v_cnode: HenVirtualCNode in current_route.ref.virtual_cnode_list:
			v_cnode.hide()


	for line: HenConnectionLine in HenGlobal.connection_line_pool:
		line.visible = false


	for connection: HenConnectionLine in HenGlobal.connection_line_pool:
		connection.visible = false


	for flow_connection: HenFlowConnectionLine in HenGlobal.flow_connection_line_pool:
		flow_connection.visible = false


	current_route = _route

	HenGlobal.CAM._check_virtual_cnodes()
	HenGlobal.SIDE_BAR._on_list_changed()