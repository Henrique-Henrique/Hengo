@tool
class_name HenScriptData extends RefCounted

var path: StringName
var type: String
var node_counter: int
var prop_counter: int
var debug_symbols: Dictionary
var props: Array
var generals: Array
var connections: Array
var flow_connections: Array
var func_list: Array
var comments: Array
var virtual_cnode_list: Array
var state_event_list: Array
var side_bar_list: Dictionary

const HENGO_EXT: StringName = '.hengo'

func get_save() -> Dictionary:
    return {
        path = path,
        type = type,
        node_counter = node_counter,
        prop_counter = prop_counter,
        debug_symbols = debug_symbols,
        props = props,
        generals = generals,
        connections = connections,
        flow_connections = flow_connections,
        func_list = func_list,
        comments = comments,
        virtual_cnode_list = virtual_cnode_list,
        state_event_list = state_event_list,
        side_bar_list = side_bar_list,
    }


static func load(_data: Dictionary) -> HenScriptData:
    var script_data: HenScriptData = HenScriptData.new()

    script_data.path = _data.path
    script_data.type = _data.type
    script_data.node_counter = _data.node_counter
    script_data.prop_counter = _data.prop_counter
    script_data.debug_symbols = _data.debug_symbols
    script_data.props = _data.props
    script_data.generals = _data.generals
    script_data.connections = _data.connections
    script_data.flow_connections = _data.flow_connections
    script_data.func_list = _data.func_list
    script_data.comments = _data.comments
    script_data.virtual_cnode_list = _data.virtual_cnode_list
    script_data.state_event_list = _data.state_event_list
    script_data.side_bar_list = _data.side_bar_list

    return script_data


static func load_from_file(_data_path: String) -> HenScriptData:
    if FileAccess.file_exists(_data_path):
        var file: FileAccess = FileAccess.open(_data_path, FileAccess.READ)
        var data: Dictionary = JSON.parse_string(file.get_as_text())
        file.close()

        return HenScriptData.load(data)
    else:
        return null


static func save(_script_data: HenScriptData, _data_path: String) -> void:
    var file: FileAccess = FileAccess.open(_data_path, FileAccess.WRITE)
    file.store_string(JSON.stringify(_script_data.get_save()))
    file.close()