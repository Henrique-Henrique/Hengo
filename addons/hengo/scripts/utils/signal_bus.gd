@tool
class_name HenSignalBus extends Node
@warning_ignore_start('UNUSED_SIGNAL')

signal scripts_generation_finished(_script_list: PackedStringArray)
signal scripts_generation_started
signal set_terminal_text(_message: String)

# code search
signal request_code_search_show_list(_class_name: StringName, _list: Array)
signal request_code_search_type_result(_list: Array)
signal request_code_search_select(_data: Dictionary)

# dashboard
signal request_list_update