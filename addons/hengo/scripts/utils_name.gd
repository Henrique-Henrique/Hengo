@tool
extends Node

# imports
const _Global = preload('res://addons/hengo/scripts/global.gd')

# get unique name
static func get_unique_name() -> String:
    _Global.unique_id += 1
    return str(Time.get_unix_time_from_system()).replace('.', '') + str(_Global.unique_id)
