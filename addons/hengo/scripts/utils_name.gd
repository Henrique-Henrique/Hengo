@tool
class_name HenUtilsName extends Node

# get unique name
static func get_unique_name() -> String:
    var global: HenGlobal = Engine.get_singleton(&'Global')
    global.unique_id += 1
    return str(Time.get_unix_time_from_system()).replace('.', '') + str(global.unique_id)
