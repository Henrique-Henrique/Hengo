@tool
@abstract
class_name HenSaveResType extends HenSaveResToInspectType

func get_res_data(_type: HenSideBar.AddType, _save_data_id: StringName = '') -> Dictionary:
	var dt: Dictionary = {
		id = id,
		type = _type,
	}

	if _save_data_id:
		dt.save_data_id = _save_data_id

	return dt