@tool
class_name HenScriptDataCache extends RefCounted


static var SCRIPT_DATA_CACHE: Dictionary = {}


# getting script data from cache
static func try_get_script_data(_id: StringName) -> HenScriptData:
	if SCRIPT_DATA_CACHE.has(_id):
		return SCRIPT_DATA_CACHE.get(_id)
	
	return null


# checking if script data is in cache
static func has_script_data(_id: StringName) -> bool:
	return SCRIPT_DATA_CACHE.has(_id)


# adding script data to cache
static func add_script_data(_id: StringName, _script_data: HenScriptData) -> void:
	if not HenCheckerScriptData.is_script_data_valid(_script_data):
		push_error("Tried to add invalid script data to cache: " + str(_id))
		return
	
	SCRIPT_DATA_CACHE.set(_id, _script_data)
	HenMapObjects.map_script_data(_id, HenScriptData.load(_script_data.get_save().duplicate(true)))


# removing script data from cache
static func remove_script_data(_id: StringName) -> void:
	SCRIPT_DATA_CACHE.erase(_id)


# clearing script data cache
static func clear() -> void:
	SCRIPT_DATA_CACHE.clear()
