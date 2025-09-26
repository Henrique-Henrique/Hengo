@tool
class_name HenVCConnectionReturn

var to_id: int
var connection: HenVCConnectionData
var old_connections: Array


func _init(_connection: HenVCConnectionData, _to_id = -1) -> void:
    connection = _connection
    to_id = _to_id


func add(_update: bool = true) -> void:
    # removing old inputs
    var remove_connection: Array = []
    
    for connection_ref: HenVCConnectionData in connection.get_to().io.connections:
        if connection_ref.to_id != to_id:
            continue

        if connection_ref.line_ref:
            connection_ref.line_ref.visible = false
            connection_ref.line_ref = null
        
        remove_connection.append(connection_ref)

    for connection_ref: HenVCConnectionData in remove_connection:
        connection_ref.get_to().io.connections.erase(connection_ref)
        connection_ref.get_from().io.connections.erase(connection_ref)

        old_connections.append(connection_ref)

    connection.get_from().io.connections.append(connection)
    connection.get_to().io.connections.append(connection)

    if _update:
        connection.get_from().update()
        connection.get_to().update()
    HenFormatter.format_current_route()


func remove() -> void:
    connection.get_from().io.connections.erase(connection)
    connection.get_to().io.connections.erase(connection)

    if connection.line_ref:
        connection.line_ref.visible = false
        connection.line_ref = null

    for connection_ref: HenVCConnectionData in old_connections:
        connection_ref.get_from().io.connections.append(connection_ref)
        connection_ref.get_to().io.connections.append(connection_ref)

    old_connections.clear()
    connection.input_ref.reset_input_value()

    connection.get_from().update()
    connection.get_to().update()
    HenFormatter.format_current_route()