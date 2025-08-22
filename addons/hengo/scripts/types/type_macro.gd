@tool
class_name HenTypeMacro extends RefCounted

var id: int
var name: String
var input_ref: HenTypeCnode
var output_ref: HenTypeCnode
var flow_inputs: Array[HenTypeFlow]
var flow_outputs: Array[HenTypeFlow]
var virtual_cnode_list: Array[HenTypeCnode]
var local_vars: Array[HenTypeVariable]
var macro_ref_list: Array[HenTypeCnode]