@tool
class_name HenPool extends RefCounted

# scenes for on-demand line-pool growth (see get_line_from_pool)
const CONNECTION_LINE_SCENE = preload('res://addons/hengo/scenes/connection_line.tscn')
const FLOW_CONNECTION_LINE_SCENE = preload('res://addons/hengo/scenes/flow_connection_line.tscn')


static func get_cnode_from_pool() -> HenCnode:
    var _cnode: HenCnode

    for cnode: HenCnode in (Engine.get_singleton(&'Global') as HenGlobal).cnode_pool:
        if not cnode.visible:
            _cnode = cnode
            cnode.unselect(0)
            break

    return _cnode


# resets a data line to a clean allocated state
static func _reset_data_line(line: HenConnectionLine) -> HenConnectionLine:
    line.from = null
    line.to = null
    line.input = null
    line.output = null
    line.points = []
    line.position = Vector2.ZERO
    line.visible = true
    line.from_pool_visible = false
    line.to_pool_visible = false
    line.last_from_pos = Vector2.ZERO
    line.last_to_pos = Vector2.ZERO
    line.has_from_offset = false
    line.has_to_offset = false
    line.owner_conn_id = 0
    line.modulate = Color.WHITE
    return line


static func get_line_from_pool() -> HenConnectionLine:
    var global: HenGlobal = Engine.get_singleton(&'Global') as HenGlobal

    for line: HenConnectionLine in global.connection_line_pool:
        if not line.visible:
            return _reset_data_line(line)

    # no free line: the async pool build creates cnodes before lines, so grow on
    # demand instead of returning null and dropping the line
    var fresh: HenConnectionLine = CONNECTION_LINE_SCENE.instantiate()
    fresh.position = Vector2(50000, 50000)
    global.connection_line_pool.append(fresh)
    if global.CAM and global.CAM.has_node('Lines'):
        global.CAM.get_node('Lines').add_child(fresh)
    return _reset_data_line(fresh)


static func _reset_flow_line(line: HenFlowConnectionLine) -> HenFlowConnectionLine:
    line.from = null
    line.to = null
    line.input = null
    line.output = null
    line.points = []
    line.position = Vector2.ZERO
    line.visible = true
    line.from_pool_visible = false
    line.to_pool_visible = false
    line.last_from_pos = Vector2.ZERO
    line.last_to_pos = Vector2.ZERO
    line.has_from_offset = false
    line.has_to_offset = false
    line.owner_conn_id = 0
    line.modulate = Color.WHITE
    return line


static func get_flow_line_from_pool() -> HenFlowConnectionLine:
    var global: HenGlobal = Engine.get_singleton(&'Global') as HenGlobal

    for line: HenFlowConnectionLine in global.flow_connection_line_pool:
        if not line.visible:
            return _reset_flow_line(line)

    # grow on demand — same startup pool-build race as get_line_from_pool.
    var fresh: HenFlowConnectionLine = FLOW_CONNECTION_LINE_SCENE.instantiate()
    fresh.position = Vector2(50000, 50000)
    global.flow_connection_line_pool.append(fresh)
    if global.CAM and global.CAM.has_node('Lines'):
        global.CAM.get_node('Lines').add_child(fresh)
    return _reset_flow_line(fresh)


# free-stack: pop_back is O(1); on an empty stack, rebuild it from the master
# pool. ph.visible marks what is free
static func get_placeholder_from_pool() -> ColorRect:
    var global: HenGlobal = Engine.get_singleton(&'Global') as HenGlobal

    while not global.placeholder_pool_free.is_empty():
        var ph: ColorRect = global.placeholder_pool_free.pop_back()
        if is_instance_valid(ph) and not ph.visible:
            return ph

    for cand: ColorRect in global.placeholder_pool:
        if is_instance_valid(cand) and not cand.visible:
            global.placeholder_pool_free.push_back(cand)

    if global.placeholder_pool_free.is_empty():
        return null

    return global.placeholder_pool_free.pop_back()


static func release_placeholder(_ph: ColorRect) -> void:
    if not is_instance_valid(_ph):
        return
    _ph.visible = false
    var global: HenGlobal = Engine.get_singleton(&'Global') as HenGlobal
    global.placeholder_pool_free.push_back(_ph)
