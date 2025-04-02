@tool
class_name HenRouter extends Node


enum ROUTE_TYPE {
	BASE,
	STATE,
	FUNC,
	SIGNAL,
	INPUT
}

static var current_route: Dictionary = {} # name: String, type: ROUTE_TYPE, id: String
static var route_reference: Dictionary = {} # { [key: String]: Cnode[] }
static var line_route_reference: Dictionary = {}
static var comment_reference: Dictionary = {}

static func change_route(_route: Dictionary) -> void:
	if current_route == _route:
		return

	# hide all virtuals
	if not current_route.is_empty() and HenGlobal.vc_list.has(current_route.id):
		for vc: HenVirtualCNode in HenGlobal.vc_list[current_route.id]:
			vc.hide()


	for line: HenConnectionLine in HenGlobal.connection_line_pool:
		line.visible = false


	for connection: HenConnectionLine in HenGlobal.connection_line_pool:
		connection.visible = false


	for flow_connection: HenFlowConnectionLine in HenGlobal.flow_connection_line_pool:
		flow_connection.visible = false


	current_route = _route


	if route_reference.has(_route.id):
		# show/hide cnodes
		HenGlobal.CAM._check_virtual_cnodes()


		# clearing comments
		for comment in HenGlobal.COMMENT_CONTAINER.get_children():
			HenGlobal.COMMENT_CONTAINER.remove_child(comment)

		# showing cnodes
		var cnode_list = route_reference.get(_route.id)

		for cnode: HenCnode in cnode_list:
			HenGlobal.CNODE_CONTAINER.add_child(cnode)

		# showing comments
		for comment in comment_reference.get(_route.id):
			HenGlobal.COMMENT_CONTAINER.add_child(comment)


	else:
		# TODO error msg
		pass