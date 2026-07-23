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


func get_current_route_v_cnodes() -> Array:
	if current_route:
		return current_route.virtual_cnode_list

	return []


func change_route(_route: HenRouteData) -> void:
	if current_route == _route:
		_centralize_cam()
		return

	var old_route: HenRouteData = current_route

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

	# drop the old route's pending shows and hide its leftover placeholders
	for vc: HenVirtualCNode in global.pending_show_queue:
		if is_instance_valid(vc):
			vc.is_queued_for_show = false
	global.pending_show_queue.clear()
	for ph: ColorRect in global.placeholder_pool:
		ph.visible = false

	current_route = _route

	# force: the camera didn't move, but the new route's vcnodes must be checked now
	global.CAM._check_virtual_cnodes(global.CAM.transform.origin, global.CAM.transform.x.x, true)
	global.SIDE_BAR.update()
	
	global.AUTO_CAMERA.on_route_changed(old_route, _route)

	HenFormatter.format_current_route()

	(Engine.get_singleton(&'SignalBus') as HenSignalBus).route_changed.emit(_route)


func _centralize_cam(_vc: HenVirtualCNode = null) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not current_route:
		return

	if current_route.virtual_cnode_list.is_empty():
		return

	var vc: HenVirtualCNode = _vc if _vc else current_route.virtual_cnode_list.get(0)

	if not vc:
		return

	global.CAM.go_to_center(vc.position)
