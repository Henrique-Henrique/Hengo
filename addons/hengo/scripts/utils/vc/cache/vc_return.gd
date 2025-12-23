@tool
class_name HenVCNodeReturn

var v_cnode: HenVirtualCNode
var old_connections: Array
var old_flow_connections: Array


func _init(_v_cnode: HenVirtualCNode) -> void:
	v_cnode = _v_cnode


func add() -> void:
	if not v_cnode.can_delete:
		return

	if not v_cnode.is_deleted:
		return

	var global: HenGlobal = Engine.get_singleton(&'Global')

	v_cnode.add_vc_to_parent_route()

	# io
	for connection: HenVCConnectionData in old_connections:
		global.SAVE_DATA.add_connection(connection)
	
		connection.get_from().update()
		connection.get_to().update()

	# flows
	for connection: HenVCFlowConnectionData in old_flow_connections:
		global.SAVE_DATA.add_flow_connection(connection)
		
		connection.get_from().update()
		connection.get_to().update()

	old_connections.clear()
	old_flow_connections.clear()

	v_cnode.is_deleted = false
	v_cnode.show()
	HenFormatter.format_current_route()

	if global.RIGHT_SIDE_BAR:
		var router: HenRouter = Engine.get_singleton(&'Router')
		global.RIGHT_SIDE_BAR.update(router.current_route)


func remove() -> void:
	if not v_cnode.can_delete:
		return
	
	if v_cnode.is_deleted:
		return

	v_cnode.remove_vc_from_parent_route()

	var remove_connections: Array = []
	var remove_flow_connections: Array = []
	var global: HenGlobal = Engine.get_singleton(&'Global')
	
	# io
	for connection: HenVCConnectionData in global.SAVE_DATA.get_connection_from_vc(v_cnode):
		if connection.line_ref:
			connection.line_ref.visible = false
			connection.line_ref = null
		
		remove_connections.append(connection)

	# flows
	for connection: HenVCFlowConnectionData in global.SAVE_DATA.get_flow_connection_from_vc(v_cnode):
		if connection.line_ref:
			connection.line_ref.visible = false
			connection.line_ref = null
		
		remove_flow_connections.append(connection)

	# remove io
	for connection: HenVCConnectionData in remove_connections:
		global.SAVE_DATA.remove_connection(connection)
		
		connection.get_from().update()
		connection.get_to().update()
		old_connections.append(connection)

	# remove flow
	for flow_connection: HenVCFlowConnectionData in remove_flow_connections:
		global.SAVE_DATA.remove_flow_connection(flow_connection)
		
		flow_connection.get_from().update()
		flow_connection.get_to().update()
		old_flow_connections.append(flow_connection)

	v_cnode.hide()
	v_cnode.is_deleted = true
	HenFormatter.format_current_route()

	if global.RIGHT_SIDE_BAR:
		var router: HenRouter = Engine.get_singleton(&'Router')
		global.RIGHT_SIDE_BAR.update(router.current_route)