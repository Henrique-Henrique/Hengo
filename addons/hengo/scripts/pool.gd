@tool
class_name HenPool extends RefCounted

static func get_cnode_from_pool() -> HenCnode:
    var _cnode: HenCnode

    for cnode: HenCnode in (Engine.get_singleton(&'Global') as HenGlobal).cnode_pool:
        if not cnode.visible:
            _cnode = cnode
            cnode.unselect(0)
            break

    return _cnode


static func get_line_from_pool() -> HenConnectionLine:
    var _line: HenConnectionLine

    for line: HenConnectionLine in (Engine.get_singleton(&'Global') as HenGlobal).connection_line_pool:
        if not line.visible:
            line.from = null
            line.to = null
            line.points = []
            line.position = Vector2.ZERO
            line.visible = true
            line.from_pool_visible = false
            line.to_pool_visible = false
            line.last_from_pos = Vector2.ZERO
            line.last_to_pos = Vector2.ZERO
            _line = line
            break
    
    return _line


static func get_flow_line_from_pool() -> HenFlowConnectionLine:
    var _line: HenFlowConnectionLine

    for line: HenFlowConnectionLine in (Engine.get_singleton(&'Global') as HenGlobal).flow_connection_line_pool:
        if not line.visible:
            line.from = null
            line.to = null
            line.points = []
            line.position = Vector2.ZERO
            line.visible = true
            line.from_pool_visible = false
            line.to_pool_visible = false
            line.last_from_pos = Vector2.ZERO
            line.last_to_pos = Vector2.ZERO
            _line = line
            break
    
    return _line