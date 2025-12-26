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
    var global: HenGlobal = Engine.get_singleton(&'Global')
    var remove_connection: Array = []
    
    for connection_ref: HenVCConnectionData in global.SAVE_DATA.get_connection_from_vc(connection.get_to()):
        if connection_ref.to_id != to_id:
            continue

        remove_connection.append(connection_ref)

    for connection_ref: HenVCConnectionData in remove_connection:
        global.SAVE_DATA.remove_connection(connection_ref)
        old_connections.append(connection_ref)

    global.SAVE_DATA.add_connection(connection)

    if _update:
        connection.get_from().update()
        connection.get_to().update()


func remove() -> void:
    var global: HenGlobal = Engine.get_singleton(&'Global')
    global.SAVE_DATA.remove_connection(connection)

    for connection_ref: HenVCConnectionData in old_connections:
        global.SAVE_DATA.add_connection(connection_ref)

    old_connections.clear()

    connection.get_from().update()
    connection.get_to().update()