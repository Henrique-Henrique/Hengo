@tool
class_name HenVCConnectionReturn

var input_connection: HenVCConnectionData.InputConnectionData
var output_connection: HenVCConnectionData.OutputConnectionData
var from: WeakRef
var to: WeakRef
var to_id: int

var old_inputs_connections: Array

func _init(_in: HenVCConnectionData.InputConnectionData, _out: HenVCConnectionData.OutputConnectionData, _from: HenVirtualCNode, _to: HenVirtualCNode, _to_id = -1) -> void:
    input_connection = _in
    output_connection = _out
    from = weakref(_from)
    to = weakref(_to)
    to_id = _to_id


func add(_update: bool = true) -> void:
    # removing old inputs
    var remove_connection: Array = []
    
    for connection: HenVCConnectionData.InputConnectionData in (to.get_ref() as HenVirtualCNode).io.input_connections:
        if connection.to_id != to_id:
            continue

        if connection.line_ref:
            connection.line_ref.visible = false
            connection.line_ref = null
        
        if connection.from_ref.line_ref:
            connection.from_ref.line_ref.visible = false
            connection.from_ref.line_ref = null
        
        remove_connection.append(connection)

    for connection: HenVCConnectionData.InputConnectionData in remove_connection:
        (to.get_ref() as HenVirtualCNode).io.input_connections.erase(connection)
        connection.from.io.output_connections.erase(connection.from_ref)
        old_inputs_connections.append(connection)

    (from.get_ref() as HenVirtualCNode).io.output_connections.append(output_connection)
    (to.get_ref() as HenVirtualCNode).io.input_connections.append(input_connection)

    if _update:
        (from.get_ref() as HenVirtualCNode).renderer.update()
        (to.get_ref() as HenVirtualCNode).renderer.update()


func remove() -> void:
    (from.get_ref() as HenVirtualCNode).io.output_connections.erase(output_connection)
    (to.get_ref() as HenVirtualCNode).io.input_connections.erase(input_connection)

    if input_connection.line_ref:
        input_connection.line_ref.visible = false
        input_connection.line_ref = null
    
    if output_connection.line_ref:
        output_connection.line_ref.visible = false
        output_connection.line_ref = null

    for connection: HenVCConnectionData.InputConnectionData in old_inputs_connections:
        (to.get_ref() as HenVirtualCNode).io.input_connections.append(connection)
        connection.from.io.output_connections.append(connection.from_ref)

    old_inputs_connections.clear()
    input_connection.input_ref.reset_input_value()

    (from.get_ref() as HenVirtualCNode).renderer.update()
    (to.get_ref() as HenVirtualCNode).renderer.update()