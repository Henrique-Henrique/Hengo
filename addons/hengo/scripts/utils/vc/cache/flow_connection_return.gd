@tool
class_name HenVCFlowConnectionReturn

var to_id: int
var connection: HenVCFlowConnectionData
var old_connections: Array


func _init(_connection: HenVCFlowConnectionData, _to_id = -1) -> void:
    connection = _connection
    to_id = _to_id


func add(_update: bool = true) -> void:
    # removing old inputs
    var remove_connection: Array = []
    
    for connection_ref: HenVCFlowConnectionData in connection.get_to().flow.flow_connections_2:
        if connection_ref.to_id != to_id:
            continue

        if connection_ref.line_ref:
            connection_ref.line_ref.visible = false
            connection_ref.line_ref = null
        
        remove_connection.append(connection_ref)

    for connection_ref: HenVCFlowConnectionData in remove_connection:
        connection.get_to().flow.flow_connections_2.erase(connection_ref)
        connection.get_from().flow.flow_connections_2.erase(connection_ref)

        old_connections.append(connection_ref)

    connection.get_from().flow.flow_connections_2.append(connection)
    connection.get_to().flow.flow_connections_2.append(connection)

    if _update:
        connection.get_from().update()
        connection.get_to().update()


func remove() -> void:
    connection.get_from().flow.flow_connections_2.erase(connection)
    connection.get_to().flow.flow_connections_2.erase(connection)

    if connection.line_ref:
        connection.line_ref.visible = false
        connection.line_ref = null

    for connection_ref: HenVCFlowConnectionData in old_connections:
        connection.get_from().flow.flow_connections_2.append(connection_ref)
        connection.get_to().flow.flow_connections_2.append(connection_ref)

    old_connections.clear()

    connection.get_from().update()
    connection.get_to().update()