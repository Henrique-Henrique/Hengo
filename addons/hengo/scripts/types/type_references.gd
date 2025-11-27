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
var save_data: HenSaveData

func _init(_save_data: HenSaveData = null) -> void:
	save_data = HenSaveData.new() if not _save_data else _save_data