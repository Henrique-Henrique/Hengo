@tool
class_name HenVCFlowConnectionReturn

var flow_connection: HenVCFlowConnectionData

var to: HenVirtualCNode
var to_id: int
var from_id: int
var from: HenVirtualCNode
var to_from_ref: HenVCFromFlowConnection

# old
var old_to: HenVirtualCNode
var old_to_id: int
var old_from_id: int
var old_from: HenVirtualCNode
var old_to_from_ref: HenVCFromFlowConnection

func _init(_flow: HenVCFlowConnectionData, _from_id: int, _to: HenVirtualCNode, _to_id: int, _from: HenVirtualCNode, _to_from_ref: HenVCFromFlowConnection) -> void:
    from_id = _from_id
    flow_connection = _flow
    to = _to
    to_id = _to_id
    from = _from
    to_from_ref = _to_from_ref

func add() -> void:
    # remove other flow connection
    if flow_connection.to:
        flow_connection.to_from_ref.from_connections.erase(flow_connection)

        if flow_connection.line_ref:
            flow_connection.line_ref.visible = false
            flow_connection.line_ref = null
        
        old_to = flow_connection.to
        old_from_id = flow_connection.from_id
        old_to_id = flow_connection.to_id
        old_from = flow_connection.from
        old_to_from_ref = flow_connection.to_from_ref

    flow_connection.from_id = from_id
    flow_connection.to = to
    flow_connection.to_id = to_id
    flow_connection.from = from
    flow_connection.to_from_ref = to_from_ref
    flow_connection.line_ref = null

    flow_connection.to_from_ref.from_connections.append(flow_connection)

    flow_connection.from.update()
    flow_connection.to.update()

func remove() -> void:
    flow_connection.to = null
    flow_connection.to_from_ref.from_connections.erase(flow_connection)

    if flow_connection.line_ref:
        flow_connection.line_ref.visible = false
    
    flow_connection.line_ref = null

    # adding old flow connection
    if old_to:
        flow_connection.from_id = old_from_id
        flow_connection.to = old_to
        flow_connection.to_id = old_to_id
        flow_connection.from = old_from
        flow_connection.to_from_ref = old_to_from_ref

        old_to_from_ref.from_connections.append(flow_connection)
        old_to.update()

    old_to = null

    flow_connection.from.update()