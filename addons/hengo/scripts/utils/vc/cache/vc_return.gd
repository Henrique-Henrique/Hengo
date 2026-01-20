@tool
class_name HenVCNodeReturn

var v_cnode: HenVirtualCNode
var old_connections: Array
var old_flow_connections: Array


func _init(_v_cnode: HenVirtualCNode) -> void:
	v_cnode = _v_cnode


# restores node and its connections
func add() -> void:
	if not v_cnode.can_delete:
		return

	if not v_cnode.is_deleted:
		return

	var global: HenGlobal = Engine.get_singleton(&'Global')

	v_cnode.add_virtual_cnode_to_parent_route()

	for connection: HenVCConnectionData in old_connections:
		global.SAVE_DATA.add_connection(connection)

	for connection: HenVCFlowConnectionData in old_flow_connections:
		global.SAVE_DATA.add_flow_connection(connection)

	v_cnode.is_deleted = false

	if not global.IS_HEADLESS:
		v_cnode.check_visibility()

		for connection: HenVCConnectionData in old_connections:
			connection.get_to(global.SAVE_DATA).update()
			connection.get_from(global.SAVE_DATA).update()
		
		for flow_connection: HenVCFlowConnectionData in old_flow_connections:
			flow_connection.get_to(global.SAVE_DATA).update()
			flow_connection.get_from(global.SAVE_DATA).update()
		
		if global.RIGHT_SIDE_BAR:
			var router: HenRouter = Engine.get_singleton(&'Router')
			global.RIGHT_SIDE_BAR.update(router.current_route)

	old_connections.clear()
	old_flow_connections.clear()
	
	if not global.IS_HEADLESS:
		global.AUTO_CAMERA.on_vc_added(v_cnode)


# removes node and stores connections for undo
func remove() -> void:
	if not v_cnode.can_delete:
		return
	
	if v_cnode.is_deleted:
		return

	v_cnode.remove_virtual_cnode_from_parent_route()

	var remove_connections: Array = []
	var remove_flow_connections: Array = []
	var global: HenGlobal = Engine.get_singleton(&'Global')

	for connection: HenVCConnectionData in global.SAVE_DATA.get_connection_from_vc(v_cnode):
		remove_connections.append(connection)

	for connection: HenVCFlowConnectionData in global.SAVE_DATA.get_flow_connection_from_vc(v_cnode):
		remove_flow_connections.append(connection)

	for connection: HenVCConnectionData in remove_connections:
		global.SAVE_DATA.remove_connection(connection)
		old_connections.append(connection)

	for flow_connection: HenVCFlowConnectionData in remove_flow_connections:
		global.SAVE_DATA.remove_flow_connection(flow_connection)
		old_flow_connections.append(flow_connection)

	v_cnode.is_deleted = true

	if global.IS_HEADLESS:
		return
	
	v_cnode.hide()

	for connection: HenVCConnectionData in remove_connections:
		connection.get_to(global.SAVE_DATA).update()
		connection.get_from(global.SAVE_DATA).update()
	
	for flow_connection: HenVCFlowConnectionData in remove_flow_connections:
		flow_connection.get_to(global.SAVE_DATA).update()
		flow_connection.get_from(global.SAVE_DATA).update()

	if global.RIGHT_SIDE_BAR:
		var router: HenRouter = Engine.get_singleton(&'Router')
		global.RIGHT_SIDE_BAR.update(router.current_route)

	var auto_router: HenRouter = Engine.get_singleton(&'Router')
	global.AUTO_CAMERA.on_vc_removed(v_cnode, auto_router.current_route, remove_flow_connections)