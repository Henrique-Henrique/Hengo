@tool
class_name HenSaveData extends Resource

@export var counter: int
@export var macros: Array[HenSaveMacro]
@export var variables: Array[HenSaveVar]
@export var functions: Array[HenSaveFunc]
@export var identity: HenSaveDataIdentity
@export var signals: Array[HenSaveSignal]
@export var signals_callback: Array[HenSaveSignalCallback]
@export var base_route: HenRouteData
@export var connections: Dictionary
@export var flow_connections: Dictionary


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
	var nodes: Array = [_connection.get_from(), _connection.get_to()]
	
	for _vc: HenVirtualCNode in nodes:
		var node_id: int = _vc.id
		
		if not connections.has(node_id):
			connections[node_id] = {}
		
		var vc_dict: Dictionary = connections[node_id]
		vc_dict[_connection.id] = _connection


func remove_connection(_connection: HenVCConnectionData) -> void:
	var nodes: Array = [_connection.get_from(), _connection.get_to()]
	
	for _vc: HenVirtualCNode in nodes:
		var node_id: int = _vc.id
		
		if connections.has(node_id):
			var vc_dict: Dictionary = connections[node_id]
			vc_dict.erase(_connection.id)


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
		if connection.get_from() == _vc:
			outgoing.append(connection)

	return outgoing


func get_to_connection_from_vc(_vc: HenVirtualCNode) -> Array:
	var node_id: int = _vc.id
	if not connections.has(node_id):
		return []
	
	var vc_dict: Dictionary = connections[node_id]
	var outgoing: Array = []

	for connection: HenVCConnectionData in vc_dict.values():
		if connection.get_to() == _vc:
			outgoing.append(connection)

	return outgoing


func get_outgoing_flow_connection_from_vc(_vc: HenVirtualCNode) -> Array:
	var node_id: int = _vc.id
	if not flow_connections.has(node_id):
		return []
	
	var vc_dict: Dictionary = flow_connections[node_id]
	var outgoing: Array = []

	for connection: HenVCFlowConnectionData in vc_dict.values():
		if connection.get_from() == _vc:
			outgoing.append(connection)

	return outgoing


func get_flow_connections_by_id(_vc_id: int) -> Array:
	if not flow_connections.has(_vc_id):
		return []
	
	var vc_dict: Dictionary = flow_connections[_vc_id] as Dictionary
	return vc_dict.values()


func add_flow_connection(_connection: HenVCFlowConnectionData) -> void:
	var nodes: Array = [_connection.get_from(), _connection.get_to()]
	
	for _vc: HenVirtualCNode in nodes:
		var node_id: int = _vc.id
		
		if not flow_connections.has(node_id):
			flow_connections[node_id] = {}
		
		var vc_dict: Dictionary = flow_connections[node_id]
		vc_dict[_connection.id] = _connection


func remove_flow_connection(_connection: HenVCFlowConnectionData) -> void:
	var nodes: Array = [_connection.get_from(), _connection.get_to()]
	
	for _vc: HenVirtualCNode in nodes:
		var node_id: int = _vc.id
		
		if flow_connections.has(node_id):
			var vc_dict: Dictionary = flow_connections[node_id]
			vc_dict.erase(_connection.id)


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


func add_var() -> void:
	var v: HenSaveVar = HenSaveVar.create()

	if not v:
		return
	
	variables.append(v)


func add_func() -> void:
	var f: HenSaveFunc = HenSaveFunc.create()

	if not f:
		return
	

	if not HenUtils.save_side_bar_item(f, identity.id, HenSideBar.SideBarItem.FUNCTIONS):
		return
	
	f.save_data_id = identity.id
	functions.append(f)


func add_signal() -> void:
	var s: HenSaveSignal = HenSaveSignal.create()

	if not s:
		return
	
	signals.append(s)


func add_signals_callback() -> void:
	var sc: HenSaveSignalCallback = HenSaveSignalCallback.create()

	if not sc:
		return
	
	signals_callback.append(sc)


func add_macro() -> void:
	var m: HenSaveMacro = HenSaveMacro.create()

	if not m:
		return
	
	macros.append(m)
