@tool
class_name HenTypeReferences extends RefCounted

var states: Array[HenTypeCnode]
var base_route_cnode_list: Array[HenTypeCnode]
var cnode_ref: Dictionary = {}
var states_data: Dictionary = {}
var variables: Array[HenTypeVariable]
var functions: Array[HenTypeFunc]
var signals_callback: Array[HenTypeSignalCallbackData]
var signals: Array[HenTypeSignalData]
var macros: Array[HenTypeMacro]
var side_bar_item_ref: Dictionary = {}
var script_data: HenScriptData

func _init(_script_data: HenScriptData = null) -> void:
	script_data = HenScriptData.new() if not _script_data else _script_data