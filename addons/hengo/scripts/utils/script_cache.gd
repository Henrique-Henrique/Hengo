@tool
class_name HenScriptDataCache extends Node


var SCRIPT_DATA_CACHE: Dictionary = {}


# getting script data from cache
func try_get_script_data(_id: StringName) -> HenScriptData:
	if SCRIPT_DATA_CACHE.has(_id):
		return SCRIPT_DATA_CACHE.get(_id)
	
	return null


# checking if script data is in cache
func has_script_data(_id: StringName) -> bool:
	return SCRIPT_DATA_CACHE.has(_id)


# adding script data to cache
func add_script_data(_id: StringName, _script_data: HenScriptData) -> bool:
	if not HenCheckerScriptData.is_script_data_valid(_script_data):
		(Engine.get_singleton(&'ToastContainer') as HenToast).notify.call_deferred("Tried to add invalid script data to cache: " + str(_id), HenToast.MessageType.ERROR)
		return false
	
	SCRIPT_DATA_CACHE.set(_id, _script_data)
	var map_objects: HenMapObjects = Engine.get_singleton(&'MapObjects')
	map_objects.map_script_data(_id, HenScriptData.load(_script_data.get_save().duplicate(true)))
	return true


# removing script data from cache
func remove_script_data(_id: StringName) -> void:
	SCRIPT_DATA_CACHE.erase(_id)


# clearing script data cache
func clear() -> void:
	SCRIPT_DATA_CACHE.clear()
