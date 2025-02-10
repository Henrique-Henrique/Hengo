@tool
class_name HenRouter extends Node


enum ROUTE_TYPE {
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
	if not current_route.is_empty():
		for vc: HenVirtualCNode in HenGlobal.vc_list[current_route.id]:
			vc.reset()

	current_route = _route

	if route_reference.has(_route.id):
		# cleaning cnode tree
		for cnode: HenCnode in HenGlobal.CNODE_CONTAINER.get_children():
			if cnode.is_pool:
				cnode.visible = false

		HenGlobal.CNODE_CAM._check_virtual_cnodes()


		# clearing lines
		var line_container = HenGlobal.CNODE_CAM.get_node('Lines')

		for line in line_container.get_children():
			line_container.remove_child(line)
		
		# clearing comments
		for comment in HenGlobal.COMMENT_CONTAINER.get_children():
			HenGlobal.COMMENT_CONTAINER.remove_child(comment)

		# showing cnodes
		var cnode_list = route_reference.get(_route.id)

		for cnode: HenCnode in cnode_list:
			HenGlobal.CNODE_CONTAINER.add_child(cnode)

		# showing lines
		for line in line_route_reference.get(_route.id):
			line_container.add_child(line)

		# showing comments
		for comment in comment_reference.get(_route.id):
			HenGlobal.COMMENT_CONTAINER.add_child(comment)

		match _route.type:
			ROUTE_TYPE.STATE:
				# debug
				for cnode: HenCnode in cnode_list:
					if [HenCnode.SUB_TYPE.VIRTUAL, HenCnode.TYPE.IF].has(cnode.sub_type):
						HenGlobal.node_references[cnode.hash] = cnode.get_connection_lines_in_flow()
				
				for state in HenGlobal.STATE_CAM.get_tree().get_nodes_in_group(HenEnums.STATE_SELECTED_GROUP):
					state.unselect()
				
				_route.state_ref.select()

	else:
		# TODO error msg
		pass