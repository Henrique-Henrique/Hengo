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

# a state was picked outside the graph, which is asked to centre the view on it
signal request_focus_state(_state: HenSaveState)

# emitted whenever the open scope changes (the script itself, a function, a macro)
signal route_changed


# set to true during batch compilation to suppress thread-unsafe UI signals
var is_batch_loading: bool = false



signal debug_state_changed(_state_name: StringName, _script_id: String)
signal debug_flow_transition(_vc_id: int, _port: StringName)
signal debug_state_flow(_vc_id: int, _port: StringName, _script_id: String)
signal debug_action_flow(_action_id: StringName, _script_id: String)
signal debug_state_transition(_source: String, _event: String, _script_id: String)

signal debug_nodes_listed(_script_id: String, _nodes: Array)
signal debug_session_started
signal debug_session_stopped
signal debug_instance_selected(_script_id: String, _instance_id: int)