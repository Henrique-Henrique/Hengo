@tool
class_name HenPool extends RefCounted


static func get_line_from_pool(_from_cnode: HenCnode, _to_cnode: HenCnode, _input_connector, _output_connector) -> HenConnectionLine:
    var _line: HenConnectionLine

    for line: HenConnectionLine in HenGlobal.connection_line_pool:
        if not line.visible:
            line.points = []
            line.from_cnode = _from_cnode
            line.to_cnode = _to_cnode
            line.input = _input_connector
            line.output = _output_connector
            line.position = Vector2.ZERO
            line.visible = true

            _line = line
            break
    
    return _line