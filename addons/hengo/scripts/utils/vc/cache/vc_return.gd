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

	v_cnode.add_virtual_cnode_to_parent_route()

	# io
	for connection: HenVCConnectionData in old_connections:
		global.SAVE_DATA.add_connection(connection)

	# flows
	for connection: HenVCFlowConnectionData in old_flow_connections:
		global.SAVE_DATA.add_flow_connection(connection)

	old_connections.clear()
	old_flow_connections.clear()

	v_cnode.is_deleted = false

	if global.IS_HEADLESS:
		return

	global.CAM._check_virtual_cnodes()

	if global.RIGHT_SIDE_BAR:
		var router: HenRouter = Engine.get_singleton(&'Router')
		global.RIGHT_SIDE_BAR.update(router.current_route)


func remove() -> void:
	if not v_cnode.can_delete:
		return
	
	if v_cnode.is_deleted:
		return

	v_cnode.remove_virtual_cnode_from_parent_route()

	var remove_connections: Array = []
	var remove_flow_connections: Array = []
	var global: HenGlobal = Engine.get_singleton(&'Global')
	
	# io
	for connection: HenVCConnectionData in global.SAVE_DATA.get_connection_from_vc(v_cnode):
		remove_connections.append(connection)

	# flows
	for connection: HenVCFlowConnectionData in global.SAVE_DATA.get_flow_connection_from_vc(v_cnode):
		remove_flow_connections.append(connection)

	# remove io
	for connection: HenVCConnectionData in remove_connections:
		global.SAVE_DATA.remove_connection(connection)
		old_connections.append(connection)

	# remove flow
	for flow_connection: HenVCFlowConnectionData in remove_flow_connections:
		global.SAVE_DATA.remove_flow_connection(flow_connection)
		old_flow_connections.append(flow_connection)

	v_cnode.is_deleted = true

	if global.IS_HEADLESS:
		return
	
	v_cnode.hide()

	global.CAM._check_virtual_cnodes()

	if global.RIGHT_SIDE_BAR:
		var router: HenRouter = Engine.get_singleton(&'Router')
		global.RIGHT_SIDE_BAR.update(router.current_route)