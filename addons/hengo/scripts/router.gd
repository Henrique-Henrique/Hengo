@tool
extends Node

# imports
const _Global = preload('res://addons/hengo/scripts/global.gd')

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

	current_route = _route

	if route_reference.has(_route.id):
		# cleaning cnode tree
		for cnode in _Global.CNODE_CONTAINER.get_children():
			_Global.CNODE_CONTAINER.remove_child(cnode)

		# clearing lines
		var line_container = _Global.CNODE_CAM.get_node('Lines')

		for line in line_container.get_children():
			line_container.remove_child(line)
		
		# clearing comments
		for comment in _Global.COMMENT_CONTAINER.get_children():
			_Global.COMMENT_CONTAINER.remove_child(comment)


		# showing cnodes
		var cnode_list = route_reference.get(_route.id)

		for cnode in cnode_list:
			_Global.CNODE_CONTAINER.add_child(cnode)

		# showing lines
		for line in line_route_reference.get(_route.id):
			line_container.add_child(line)

		# showing comments
		for comment in comment_reference.get(_route.id):
			_Global.COMMENT_CONTAINER.add_child(comment)


		match _route.type:
			ROUTE_TYPE.FUNC:
				_Global.LOCAL_VAR_SECTION.show_local_vars(_route)
			ROUTE_TYPE.STATE:
				# debug
				for cnode in cnode_list:
					if ['virtual', 'if'].has(cnode.type):
						_Global.node_references[cnode.hash] = cnode.get_connection_lines_in_flow()
				
				_Global.LOCAL_VAR_SECTION.hide()
			_:
				_Global.LOCAL_VAR_SECTION.hide()

	else:
		# TODO error msg
		pass