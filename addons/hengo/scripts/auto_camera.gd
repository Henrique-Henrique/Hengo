@tool
class_name HenAutoCamera extends RefCounted

# manages automatic camera movement and zoom based on user actions

var focused_vc_by_route: Dictionary = {}
var last_focused_vc: HenVirtualCNode = null

# batch delete tracking
var _delete_batch_count: int = 0
var _delete_batch_time: int = 0
const DELETE_BATCH_THRESHOLD_MS: int = 100


func is_auto_move_enabled() -> bool:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	return global.SETTINGS.auto_move


func is_auto_zoom_enabled() -> bool:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	return global.SETTINGS.auto_zoom


func is_auto_move_on_add_enabled() -> bool:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	return global.SETTINGS.auto_move and global.SETTINGS.auto_move_on_add


func is_auto_move_on_remove_enabled() -> bool:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	return global.SETTINGS.auto_move and global.SETTINGS.auto_move_on_remove


func is_auto_move_on_connection_enabled() -> bool:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	return global.SETTINGS.auto_move and global.SETTINGS.auto_move_on_connection


func get_current_zoom() -> float:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if global.CAM:
		return global.CAM.transform.x.x
	return 1.0


# focuses camera on a virtual cnode, optionally preserving current zoom
func focus_on_vc(_vc: HenVirtualCNode, _preserve_zoom: bool = true) -> void:
	if not _vc:
		return
	
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global.CAM:
		return
	
	last_focused_vc = _vc
	
	var router: HenRouter = Engine.get_singleton(&'Router')
	if router.current_route:
		focused_vc_by_route[router.current_route.id] = _vc.id
	
	var center_pos: Vector2 = _vc.position + (_vc.size / 2.0)
	
	if _preserve_zoom:
		global.CAM.go_to_center(center_pos)
	else:
		var target_zoom: float = global.SETTINGS.auto_zoom_level if is_auto_zoom_enabled() else get_current_zoom()
		global.CAM.go_to_center_with_zoom(center_pos, target_zoom)


func on_vc_added(_vc: HenVirtualCNode) -> void:
	if not is_auto_move_on_add_enabled():
		return
	
	if not _vc or _vc.is_deleted:
		return
	
	focus_on_vc(_vc, false)


# skips camera movement when deleting multiple nodes
func on_vc_removed(_vc: HenVirtualCNode, _route: HenRouteData, _flow_connections: Array = []) -> void:
	if not is_auto_move_on_remove_enabled():
		return
	
	if not _route:
		return
	
	# detect batch delete
	var current_time: int = Time.get_ticks_msec()
	if current_time - _delete_batch_time < DELETE_BATCH_THRESHOLD_MS:
		_delete_batch_count += 1
	else:
		_delete_batch_count = 1
	_delete_batch_time = current_time
	
	# skip if deleting multiple
	if _delete_batch_count > 1:
		return
	
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var next_target: HenVirtualCNode = get_next_focus_target_from_connections(_vc, _flow_connections, global.SAVE_DATA)
	
	if not next_target:
		next_target = get_next_focus_target_from_list(_vc, _route)
	
	if next_target:
		focus_on_vc(next_target, true)


func on_route_changed(_old_route: HenRouteData, _new_route: HenRouteData) -> void:
	if _old_route and last_focused_vc:
		focused_vc_by_route[_old_route.id] = last_focused_vc.id
	
	if not _new_route:
		return
	
	var global: HenGlobal = Engine.get_singleton(&'Global')
	
	if not is_auto_move_enabled():
		var router: HenRouter = Engine.get_singleton(&'Router')
		router._centralize_cam()
		return
	
	var target_vc: HenVirtualCNode = null
	
	if focused_vc_by_route.has(_new_route.id):
		var saved_vc_id: int = focused_vc_by_route[_new_route.id]
		target_vc = find_vc_by_id(saved_vc_id, _new_route)
	
	if not target_vc and not _new_route.virtual_cnode_list.is_empty():
		target_vc = _new_route.virtual_cnode_list[0]
	
	if target_vc:
		focus_on_vc(target_vc, not is_auto_zoom_enabled())
	else:
		global.CAM.go_to_center(Vector2.ZERO)


func on_connection_changed(_target_vc: HenVirtualCNode) -> void:
	if not is_auto_move_on_connection_enabled():
		return
	
	if _target_vc and not _target_vc.is_deleted:
		focus_on_vc(_target_vc, true)


func save_current_focus(_route: HenRouteData) -> void:
	if not _route or not last_focused_vc:
		return
	
	focused_vc_by_route[_route.id] = last_focused_vc.id


# prioritizes flow parent, then flow child
func get_next_focus_target_from_connections(_removed_vc: HenVirtualCNode, _flow_connections: Array, _save_data: HenSaveData) -> HenVirtualCNode:
	if _flow_connections.is_empty():
		return null
	
	for connection: Variant in _flow_connections:
		if not connection is HenVCFlowConnectionData:
			continue
		
		var flow_conn: HenVCFlowConnectionData = connection
		var to_vc: HenVirtualCNode = flow_conn.get_to(_save_data)
		var from_vc: HenVirtualCNode = flow_conn.get_from(_save_data)
		
		if to_vc and to_vc.id == _removed_vc.id and from_vc and not from_vc.is_deleted:
			return from_vc
	
	for connection: Variant in _flow_connections:
		if not connection is HenVCFlowConnectionData:
			continue
		
		var flow_conn: HenVCFlowConnectionData = connection
		var to_vc: HenVirtualCNode = flow_conn.get_to(_save_data)
		var from_vc: HenVirtualCNode = flow_conn.get_from(_save_data)
		
		if from_vc and from_vc.id == _removed_vc.id and to_vc and not to_vc.is_deleted:
			return to_vc
	
	return null


func get_next_focus_target_from_list(_removed_vc: HenVirtualCNode, _route: HenRouteData) -> HenVirtualCNode:
	if not _route or _route.virtual_cnode_list.is_empty():
		return null
	
	var list: Array[HenVirtualCNode] = _route.virtual_cnode_list
	
	for vc: HenVirtualCNode in list:
		if vc.id != _removed_vc.id and not vc.is_deleted:
			return vc
	
	return null


func find_vc_by_id(_id: int, _route: HenRouteData) -> HenVirtualCNode:
	if not _route:
		return null
	
	for vc: HenVirtualCNode in _route.virtual_cnode_list:
		if vc.id == _id and not vc.is_deleted:
			return vc
	
	return null
