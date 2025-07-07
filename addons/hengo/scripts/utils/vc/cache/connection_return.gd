@tool
class_name HenVCConnectionReturn

var input_connection: HenVCConnectionData.InputConnectionData
var output_connection: HenVCConnectionData.OutputConnectionData
var from: HenVirtualCNode
var to: HenVirtualCNode
var to_id: int

var old_inputs_connections: Array

func _init(_in: HenVCConnectionData.InputConnectionData, _out: HenVCConnectionData.OutputConnectionData, _from: HenVirtualCNode, _to: HenVirtualCNode, _to_id = -1) -> void:
    input_connection = _in
    output_connection = _out
    from = _from
    to = _to
    to_id = _to_id


func add(_update: bool = true) -> void:
    # removing old inputs
    var remove_connection: Array = []
    
    for connection: HenVCConnectionData.InputConnectionData in to.input_connections:
        if connection.to_id != to_id:
            continue

        if connection.line_ref:
            connection.line_ref.visible = false
            connection.line_ref = null
        
        if connection.from_ref.line_ref:
            connection.from_ref.line_ref.visible = false
            connection.from_ref.line_ref = null
        
        remove_connection.append(connection)

    for connection in remove_connection:
        to.input_connections.erase(connection)
        connection.from.output_connections.erase(connection.from_ref)
        old_inputs_connections.append(connection)

    from.output_connections.append(output_connection)
    to.input_connections.append(input_connection)

    if _update:
        from.update()
        to.update()


func remove() -> void:
    from.output_connections.erase(output_connection)
    to.input_connections.erase(input_connection)

    if input_connection.line_ref:
        input_connection.line_ref.visible = false
        input_connection.line_ref = null
    
    if output_connection.line_ref:
        output_connection.line_ref.visible = false
        output_connection.line_ref = null

    for connection: HenVCConnectionData.InputConnectionData in old_inputs_connections:
        to.input_connections.append(connection)
        connection.from.output_connections.append(connection.from_ref)

    old_inputs_connections.clear()
    input_connection.input_ref.reset_input_value()

    from.update()
    to.update()