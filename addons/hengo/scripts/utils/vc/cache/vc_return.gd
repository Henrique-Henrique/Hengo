@tool
class_name HenVCNodeReturn

var v_cnode: HenVirtualCNode
var old_inputs_connections: Array
var old_outputs_connections: Array
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

    v_cnode.io.input_connections.append_array(old_inputs_connections)
    v_cnode.io.output_connections.append_array(old_outputs_connections)

    # inputs
    for input_connection: HenVCConnectionData.InputConnectionData in old_inputs_connections:
        input_connection.from.io.output_connections.append(input_connection.from_ref)
        input_connection.from.renderer.update()

    # outputs
    for output_connection: HenVCConnectionData.OutputConnectionData in old_outputs_connections:
        output_connection.to.io.input_connections.append(output_connection.to_ref)
        output_connection.to.renderer.update()

    # flow connection
    for flow_connection: HenVCFlowConnectionData in old_flow_connections:
        if flow_connection.to and flow_connection.to.get_ref():
            flow_connection.to_from_ref.from_connections.append(flow_connection)
            (flow_connection.to.get_ref() as HenVirtualCNode).renderer.update()


    # from flow connections
    for from_flow_connection: HenVCFromFlowConnectionData in old_from_flow_connections:
        for flow_connection: HenVCFlowConnectionData in from_flow_connection.from_connections:
            flow_connection.to = weakref(v_cnode)
            (flow_connection.from.get_ref() as HenVirtualCNode).renderer.update()

    old_inputs_connections.clear()
    old_outputs_connections.clear()
    old_from_flow_connections.clear()
    old_flow_connections.clear()

    v_cnode.state.is_deleted = false
    v_cnode.renderer.update()


func remove() -> void:
    if not v_cnode.state.can_delete:
        return
    
    var list: Array = (v_cnode.route_info.route_ref.ref as HenVirtualCNode).children.virtual_cnode_list \
        if v_cnode.route_info.route_ref.ref is HenVirtualCNode \
        else v_cnode.route_info.route_ref.ref.virtual_cnode_list
    
    list.erase(v_cnode)

    old_inputs_connections.append_array(v_cnode.io.input_connections)
    old_outputs_connections.append_array(v_cnode.io.output_connections)
    old_flow_connections.append_array(v_cnode.flow.flow_connections)
    old_from_flow_connections.append_array(v_cnode.flow.from_flow_connections)

    # inputs
    for input_connection: HenVCConnectionData.InputConnectionData in v_cnode.io.input_connections:
        input_connection.from.io.output_connections.erase(input_connection.from_ref)

        if input_connection.line_ref:
            input_connection.line_ref.visible = false

            # remove the line reference from both inputs
            input_connection.line_ref = null
            input_connection.from_ref.line_ref = null
        
        input_connection.from.renderer.update()

    # outputs
    for output_connection: HenVCConnectionData.OutputConnectionData in v_cnode.io.output_connections:
        output_connection.to.io.input_connections.erase(output_connection.to_ref)

        if output_connection.line_ref:
            output_connection.line_ref.visible = false

            # remove the line reference from both inputs
            output_connection.line_ref = null
            output_connection.to_ref.line_ref = null
        
        output_connection.to.renderer.update()

    # flow connections
    for flow_connection: HenVCFlowConnectionData in v_cnode.flow.flow_connections:
        if flow_connection.line_ref:
            flow_connection.line_ref.visible = false
            flow_connection.line_ref = null
        
        if flow_connection.to and flow_connection.to.get_ref():
            flow_connection.to_from_ref.from_connections.erase(flow_connection)

            (flow_connection.to.get_ref() as HenVirtualCNode).renderer.update()

    # from flow connections
    for from_flow_connection: HenVCFromFlowConnectionData in v_cnode.flow.from_flow_connections:
        for from_connection: HenVCFlowConnectionData in from_flow_connection.from_connections:
            if from_connection.line_ref:
                from_connection.line_ref.visible = false
                from_connection.line_ref = null

            from_connection.to = null

            (from_connection.from.get_ref() as HenVirtualCNode).renderer.update()

    v_cnode.io.input_connections.clear()
    v_cnode.io.output_connections.clear()
    v_cnode.renderer.hide()
    v_cnode.state.is_deleted = true