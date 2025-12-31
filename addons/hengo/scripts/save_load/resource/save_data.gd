@tool
class_name HenSaveData extends Resource

@export var counter: int
@export var identity: HenSaveDataIdentity
@export var routes: Dictionary
@export var macros: Array[HenSaveMacro]
@export var variables: Array[HenSaveVar]
@export var functions: Array[HenSaveFunc]
@export var signals: Array[HenSaveSignal]
@export var states: Array[HenSaveState]
@export var signals_callback: Array[HenSaveSignalCallback]
@export var connections: Dictionary
@export var flow_connections: Dictionary

var _node_cache: Dictionary = {}


func get_cnode_by_id(_id: int) -> HenVirtualCNode:
	if _node_cache.has(_id):
		return _node_cache.get(_id)
	
	for route_id: StringName in routes:
		for vc: HenVirtualCNode in (routes.get(route_id) as HenRouteData).virtual_cnode_list:
			if vc.id == _id:
				_node_cache[vc.id] = vc
				return vc
	
	return null


func create_route(_id: StringName, _name: String, _type: HenRouter.ROUTE_TYPE) -> HenRouteData:
	var route: HenRouteData = HenRouteData.create(
		_name,
		_type,
		_id
	)

	add_route(_id, route)
	return route


func get_base_route() -> HenRouteData:
	return routes.get(identity.id)


func add_route(_id: StringName, _route: HenRouteData) -> void:
	if not routes.has(_id):
		routes.set(_id, _route)


func get_route(_id: StringName) -> HenRouteData:
	return routes.get(_id)


func get_connection_from_vc(_vc: HenVirtualCNode) -> Array:
	var node_id: int = _vc.id
	if not connections.has(node_id):
		return []
	
	var vc_dict: Dictionary = connections[node_id]
	return vc_dict.values()


func get_connections_by_id(_vc_id: int) -> Array:
	if not connections.has(_vc_id):
		return []
	
	var vc_dict: Dictionary = connections[_vc_id] as Dictionary
	return vc_dict.values()


func add_connection(_connection: HenVCConnectionData) -> void:
	var nodes: Array = [_connection.get_from(self), _connection.get_to(self)]
	
	for _vc: HenVirtualCNode in nodes:
		var node_id: int = _vc.id
		
		if not connections.has(node_id):
			connections[node_id] = {}
		
		var vc_dict: Dictionary = connections[node_id]
		vc_dict[_connection.id] = _connection


func remove_connection(_connection: HenVCConnectionData) -> void:
	var nodes: Array = [_connection.get_from(self), _connection.get_to(self)]
	
	for _vc: HenVirtualCNode in nodes:
		var node_id: int = _vc.id
		
		if connections.has(node_id):
			var vc_dict: Dictionary = connections[node_id]

			if _connection.line_ref:
				_connection.line_ref.visible = false
				_connection.line_ref = null

			vc_dict.erase(_connection.id)
			
			if vc_dict.is_empty():
				connections.erase(node_id)


func get_flow_connection_from_vc(_vc: HenVirtualCNode) -> Array:
	var node_id: int = _vc.id
	if not flow_connections.has(node_id):
		return []
	
	var vc_dict: Dictionary = flow_connections[node_id]
	return vc_dict.values()


func get_outgoing_connection_from_vc(_vc: HenVirtualCNode) -> Array:
	var node_id: int = _vc.id
	if not connections.has(node_id):
		return []
	
	var vc_dict: Dictionary = connections[node_id]
	var outgoing: Array = []

	for connection: HenVCConnectionData in vc_dict.values():
		if connection.get_from(self) == _vc:
			outgoing.append(connection)

	return outgoing


func get_to_connection_from_vc(_vc: HenVirtualCNode) -> Array:
	var node_id: int = _vc.id
	if not connections.has(node_id):
		return []
	
	var vc_dict: Dictionary = connections[node_id]
	var outgoing: Array = []

	for connection: HenVCConnectionData in vc_dict.values():
		if connection.get_to(self) == _vc:
			outgoing.append(connection)

	return outgoing


func get_outgoing_flow_connection_from_vc(_vc: HenVirtualCNode) -> Array:
	var node_id: int = _vc.id
	if not flow_connections.has(node_id):
		return []
	
	var vc_dict: Dictionary = flow_connections[node_id]
	var outgoing: Array = []

	for connection: HenVCFlowConnectionData in vc_dict.values():
		if connection.get_from(self) == _vc:
			outgoing.append(connection)

	return outgoing


func get_flow_connections_by_id(_vc_id: int) -> Array:
	if not flow_connections.has(_vc_id):
		return []
	
	var vc_dict: Dictionary = flow_connections[_vc_id] as Dictionary
	return vc_dict.values()


func add_flow_connection(_connection: HenVCFlowConnectionData) -> void:
	var nodes: Array = [_connection.get_from(self), _connection.get_to(self)]
	
	for _vc: HenVirtualCNode in nodes:
		var node_id: int = _vc.id
		
		if not flow_connections.has(node_id):
			flow_connections[node_id] = {}
		
		var vc_dict: Dictionary = flow_connections[node_id]
		vc_dict[_connection.id] = _connection


func remove_flow_connection(_connection: HenVCFlowConnectionData) -> void:
	var nodes: Array = [_connection.get_from(self), _connection.get_to(self)]
	
	for _vc: HenVirtualCNode in nodes:
		var node_id: int = _vc.id
		
		if flow_connections.has(node_id):
			var vc_dict: Dictionary = flow_connections[node_id]
			
			if _connection.line_ref:
				_connection.line_ref.visible = false
				_connection.line_ref = null
			
			vc_dict.erase(_connection.id)
			if vc_dict.is_empty():
				flow_connections.erase(node_id)


func add_dep(_id: StringName) -> void:
	if not _id:
		return

	if identity.id == _id:
		return

	if not identity.deps.has(_id):
		identity.deps.append(_id)


func add_detailed_dep(_id: StringName, _dep_info: Dictionary) -> void:
	if not _id:
		return

	if identity.id == _id:
		return

	if not identity.detailed_deps.has(_id):
		identity.detailed_deps[_id] = []

	for dep: Dictionary in identity.detailed_deps[_id]:
		if dep.type == _dep_info.type and dep.id == _dep_info.id:
			return

	(identity.detailed_deps[_id] as Array).append(_dep_info)


func add_var(_save: bool = true) -> void:
	var v: HenSaveVar = HenSaveVar.create()

	if not v:
		return
	
	variables.append(v)


func add_state() -> void:
	var s: HenSaveState = HenSaveState.create()

	if not s:
		return
	
	states.append(s)


func add_func(_save: bool = true) -> void:
	var f: HenSaveFunc = HenSaveFunc.create()

	if not f:
		return
	
	if _save:
		if not HenUtils.save_side_bar_item(f, identity.id, HenSideBar.SideBarItem.FUNCTIONS):
			return
	
	functions.append(f)


func add_signal() -> void:
	var s: HenSaveSignal = HenSaveSignal.create()

	if not s:
		return
	
	signals.append(s)


func add_signals_callback(_save: bool = true) -> void:
	var sc: HenSaveSignalCallback = HenSaveSignalCallback.create()

	if not sc:
		return
	
	signals_callback.append(sc)


func add_macro(_save: bool = true) -> void:
	var m: HenSaveMacro = HenSaveMacro.create()

	if not m:
		return
	
	macros.append(m)
