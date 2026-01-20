@tool
class_name HenVCFlowConnectionReturn

var connection: HenVCFlowConnectionData
var old_connections: Array


func _init(_connection: HenVCFlowConnectionData) -> void:
	connection = _connection


# adds flow connection and removes conflicting ones
func add() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var from_connections: Array = global.SAVE_DATA.get_flow_connection_from_vc(connection.get_from(global.SAVE_DATA))
	var remove_connection: Array = []
	
	for connection_ref: HenVCFlowConnectionData in from_connections:
		if connection_ref.get_from(global.SAVE_DATA) != connection.get_from(global.SAVE_DATA):
			continue

		if connection_ref.from_id != connection.from_id:
			continue

		remove_connection.append(connection_ref)

	for connection_ref: HenVCFlowConnectionData in remove_connection:
		global.SAVE_DATA.remove_flow_connection(connection_ref)
		old_connections.append(connection_ref)

	global.SAVE_DATA.add_flow_connection(connection)

	if global.IS_HEADLESS:
		return
	
	connection.get_to(global.SAVE_DATA).update()
	connection.get_from(global.SAVE_DATA).update()
	
	global.AUTO_CAMERA.on_connection_changed(connection.get_to(global.SAVE_DATA))


func remove() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	global.SAVE_DATA.remove_flow_connection(connection)

	for connection_ref: HenVCFlowConnectionData in old_connections:
		global.SAVE_DATA.add_flow_connection(connection_ref)

	old_connections.clear()

	if global.IS_HEADLESS:
		return
	
	connection.get_to(global.SAVE_DATA).update()
	connection.get_from(global.SAVE_DATA).update()