@tool
@abstract
class_name HenVirtualCNodeReference extends HenVirtualCNodeIdentity

@export var res_data: Dictionary

var cnode_instance: HenCnode = null


func get_res(_save_data: HenSaveData) -> Resource:
	return HenUtils.get_res(res_data, _save_data)