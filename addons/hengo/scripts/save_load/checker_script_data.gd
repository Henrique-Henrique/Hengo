class_name HenCheckerScriptData extends RefCounted

const SCRIPT_DATA_SCHEMA = preload('res://addons/hengo/assets/data/script_data_schema.json')


static func is_script_data_valid(_script_data: HenScriptData) -> bool:
	if not _script_data:
		return false
	
	var errors: Array = HenJSONSchema.validate(_script_data.get_save(), SCRIPT_DATA_SCHEMA.get_data())
	
	if not errors.is_empty():
		push_error("Script data is invalid: " + _script_data.path)
		return false
	
	return true
