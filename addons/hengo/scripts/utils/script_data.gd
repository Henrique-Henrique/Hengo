@tool
class_name HenScriptData
extends Resource

@export var path: StringName
@export var type: String
@export var node_counter: int
@export var prop_counter: int
@export var debug_symbols: Dictionary
@export var props: Array
@export var generals: Array
@export var connections: Array
@export var flow_connections: Array
@export var func_list: Array
@export var comments: Array
@export var virtual_cnode_list: Array
@export var state_event_list: Array
@export var side_bar_list: Dictionary


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