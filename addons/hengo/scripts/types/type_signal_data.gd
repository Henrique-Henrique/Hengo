@tool
class_name HenTypeSignalData extends RefCounted

var id: int
var name: String
var signal_name: String
var signal_name_to_code: String
var type: StringName
var virtual_cnode_list: Array[HenTypeCnode]
var params: Array[HenTypeParam]
var bind_params: Array[HenTypeParam]
var local_vars: Array[HenTypeVariable]
var signal_enter: HenTypeCnode
