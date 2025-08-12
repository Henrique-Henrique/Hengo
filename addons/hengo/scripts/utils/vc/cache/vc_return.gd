@tool
class_name HenVCNodeReturn

var v_cnode: HenVirtualCNode
var old_connections: Array
var old_flow_connections: Array


func _init(_v_cnode: HenVirtualCNode) -> void:
    v_cnode = _v_cnode


func add() -> void:
    if v_cnode.state.is_deleted and not v_cnode.state.can_delete:
        return
    
    var list: Array = ((v_cnode.route_info.route_ref.ref as WeakRef).get_ref() as HenVirtualCNode).children.virtual_cnode_list \
        if (v_cnode.route_info.route_ref.ref as WeakRef).get_ref() is HenVirtualCNode \
        else (v_cnode.route_info.route_ref.ref as WeakRef).get_ref().virtual_cnode_list

    if not list.has(v_cnode):
        list.append(v_cnode)


    # io
    for connection: HenVCConnectionData in old_connections:
        connection.get_from().io.connections.append(connection)
        connection.get_to().io.connections.append(connection)
    
        connection.get_from().update()
        connection.get_to().update()


    # flows
    for connection: HenVCFlowConnectionData in old_flow_connections:
        connection.get_from().flow.flow_connections_2.append(connection)
        connection.get_to().flow.flow_connections_2.append(connection)
    
        connection.get_from().update()
        connection.get_to().update()

    old_connections.clear()
    old_flow_connections.clear()

    v_cnode.state.is_deleted = false
    v_cnode.update()


func remove() -> void:
    if not v_cnode.state.can_delete:
        return
    
    var list: Array = ((v_cnode.route_info.route_ref.ref as WeakRef).get_ref() as HenVirtualCNode).children.virtual_cnode_list \
        if (v_cnode.route_info.route_ref.ref as WeakRef).get_ref() is HenVirtualCNode \
        else (v_cnode.route_info.route_ref.ref as WeakRef).get_ref().virtual_cnode_list
    
    list.erase(v_cnode)

    var remove_connections: Array = []
    var remove_flow_connections: Array = []
    
    # io
    for connection: HenVCConnectionData in v_cnode.io.connections:
        if connection.line_ref:
            connection.line_ref.visible = false
            connection.line_ref = null
        
        remove_connections.append(connection)

    # flows
    for connection: HenVCFlowConnectionData in v_cnode.flow.flow_connections_2:
        if connection.line_ref:
            connection.line_ref.visible = false
            connection.line_ref = null
        
        remove_flow_connections.append(connection)


    # remove io
    for connection: HenVCConnectionData in remove_connections:
        connection.get_from().io.connections.erase(connection)
        connection.get_to().io.connections.erase(connection)
        connection.get_from().update()
        connection.get_to().update()
        old_connections.append(connection)

    # remove flow
    for flow_connection: HenVCFlowConnectionData in remove_flow_connections:
        flow_connection.get_from().flow.flow_connections_2.erase(flow_connection)
        flow_connection.get_to().flow.flow_connections_2.erase(flow_connection)
        flow_connection.get_from().update()
        flow_connection.get_to().update()
        old_flow_connections.append(flow_connection)


    v_cnode.hide()
    v_cnode.state.is_deleted = true