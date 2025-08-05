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

    v_cnode.io.connections.append_array(old_connections)
    v_cnode.flow.flow_connections_2.append_array(old_flow_connections)

    # inputs
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

    old_connections.append_array(v_cnode.io.connections)
    old_flow_connections.append_array(v_cnode.flow.flow_connections_2)

    # inputs
    for connection: HenVCConnectionData in v_cnode.io.connections:
        connection.get_from().io.connections.erase(connection)
        connection.get_to().io.connections.erase(connection)

        if connection.line_ref:
            connection.line_ref.visible = false
            connection.line_ref = null
        
        connection.get_from().update()


    # flows
    for connection: HenVCFlowConnectionData in v_cnode.flow.flow_connections_2:
        connection.get_from().flow.flow_connections_2.erase(connection)
        connection.get_to().flow.flow_connections_2.erase(connection)

        if connection.line_ref:
            connection.line_ref.visible = false
            connection.line_ref = null
        
        connection.get_from().update()

    v_cnode.io.connections.clear()
    v_cnode.flow.flow_connections_2.clear()
    v_cnode.hide()
    v_cnode.state.is_deleted = true