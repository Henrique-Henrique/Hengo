@tool
class_name HenSignalBus extends Node
@warning_ignore_start('UNUSED_SIGNAL')

signal scripts_generation_finished(_script_list: PackedStringArray)
signal scripts_generation_started
signal set_terminal_text(_message: String)

signal request_code_search_show_categories(_list: Array)
signal request_code_search_show_list(_list: Array)
signal request_code_search_type_result(_list: Array)
signal request_code_search_select(_data: Dictionary)

signal request_list_update

signal request_structural_update

signal add_virtual_cnode_to_route(_id: String, _vc: HenVirtualCNode)
signal remove_virtual_cnode_from_route(_id: String, _vc: HenVirtualCNode)

signal connection_added(_connection: HenVCConnectionData)
signal connection_removed(_connection: HenVCConnectionData)
signal flow_connection_added(_connection: HenVCFlowConnectionData)
signal flow_connection_removed(_connection: HenVCFlowConnectionData)

signal debug_state_changed(_state_name: StringName)
signal debug_flow_transition(_vc_id: int, _port: StringName)