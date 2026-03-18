@tool
@abstract
class_name HenSaveResType extends HenSaveResToInspectType

func get_inputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	return []

func get_outputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	return []

func get_flow_inputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	return [ {id = 0}]

func get_flow_outputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	return [ {id = 0}]


func get_res_data(_type: HenSideBar.AddType, _save_data_id: StringName = '') -> Dictionary:
	var dt: Dictionary = {
		id = id,
		type = _type,
	}

	if _save_data_id:
		dt.save_data_id = _save_data_id

	return dt