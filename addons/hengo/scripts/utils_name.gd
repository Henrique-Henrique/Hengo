@tool
class_name HenUtilsName extends Node

# get unique name
static func get_unique_name() -> String:
    HenGlobal.unique_id += 1
    return str(Time.get_unix_time_from_system()).replace('.', '') + str(HenGlobal.unique_id)
