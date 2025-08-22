@tool
class_name HenTypeFunc extends RefCounted

var id: int
var name: String
var inputs: Array[HenTypeParam]
var outputs: Array[HenTypeParam]
var virtual_cnode_list: Array[HenTypeCnode]
var local_vars: Array[HenTypeVariable]
var input_ref: HenTypeCnode
var output_ref: HenTypeCnode
