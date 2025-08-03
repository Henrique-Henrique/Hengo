@tool
class_name HenVCNodeReturn

var v_cnode: HenVirtualCNode
var old_connections: Array
var old_flow_connections: Array
var old_from_flow_connections: Array


func _init(_v_cnode: HenVirtualCNode) -> void:
    v_cnode = _v_cnode


func add() -> void:
    if v_cnode.state.is_deleted and not v_cnode.state.can_delete:
        return
    
    var list: Array = (v_cnode.route_info.route_ref.ref as HenVirtualCNode).children.virtual_cnode_list \
        if v_cnode.route_info.route_ref.ref is HenVirtualCNode \
        else v_cnode.route_info.route_ref.ref.virtual_cnode_list

    if not list.has(v_cnode):
        list.append(v_cnode)

    v_cnode.io.connections.append_array(old_connections)

    # inputs
    for connection: HenVCConnectionData in old_connections:
        connection.from.io.connections.append(connection)
        connection.to.io.connections.append(connection)
    
        connection.from.update()
        connection.to.update()


    # flow connection
    for flow_connection: HenVCFlowConnectionData in old_flow_connections:
        if flow_connection.to and flow_connection.to.get_ref():
            flow_connection.to_from_ref.from_connections.append(flow_connection)
            (flow_connection.to.get_ref() as HenVirtualCNode).update()


    # from flow connections
    for from_flow_connection: HenVCFromFlowConnectionData in old_from_flow_connections:
        for flow_connection: HenVCFlowConnectionData in from_flow_connection.from_connections:
            flow_connection.to = weakref(v_cnode)
            (flow_connection.from.get_ref() as HenVirtualCNode).update()

    old_connections.clear()
    old_from_flow_connections.clear()
    old_flow_connections.clear()

    v_cnode.state.is_deleted = false
    v_cnode.update()


func remove() -> void:
    if not v_cnode.state.can_delete:
        return
    
    var list: Array = (v_cnode.route_info.route_ref.ref as HenVirtualCNode).children.virtual_cnode_list \
        if v_cnode.route_info.route_ref.ref is HenVirtualCNode \
        else v_cnode.route_info.route_ref.ref.virtual_cnode_list
    
    list.erase(v_cnode)

    old_connections.append_array(v_cnode.io.connections)
    old_flow_connections.append_array(v_cnode.flow.flow_connections)
    old_from_flow_connections.append_array(v_cnode.flow.from_flow_connections)

    # inputs
    for connection: HenVCConnectionData in v_cnode.io.connections:
        connection.from.io.connections.erase(connection)
        connection.to.io.connections.erase(connection)

        if connection.line_ref:
            connection.line_ref.visible = false
            connection.line_ref = null
        
        connection.from.update()


    # flow connections
    for flow_connection: HenVCFlowConnectionData in v_cnode.flow.flow_connections:
        if flow_connection.line_ref:
            flow_connection.line_ref.visible = false
            flow_connection.line_ref = null
        
        if flow_connection.to and flow_connection.to.get_ref():
            flow_connection.to_from_ref.from_connections.erase(flow_connection)

            (flow_connection.to.get_ref() as HenVirtualCNode).update()

    # from flow connections
    for from_flow_connection: HenVCFromFlowConnectionData in v_cnode.flow.from_flow_connections:
        for from_connection: HenVCFlowConnectionData in from_flow_connection.from_connections:
            if from_connection.line_ref:
                from_connection.line_ref.visible = false
                from_connection.line_ref = null

            from_connection.to = null

            (from_connection.from.get_ref() as HenVirtualCNode).update()

    v_cnode.io.connections.clear()
    v_cnode.hide()
    v_cnode.state.is_deleted = true