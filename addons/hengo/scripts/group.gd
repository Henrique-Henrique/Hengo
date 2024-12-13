@tool
extends RefCounted

var group: Dictionary = {}

func _init() -> void:
    group.clear()

func add_to_group(_group: StringName, _ref) -> void:
    if not group.has(_group):
        group[_group] = []
    
    print('t-> ----')
    group[_group].append(_ref)


func remove_from_group(_group: StringName, _ref) -> void:
    print('t-> ----')
    group[_group].erase(_ref)


func get_nodes_from_group(_group: StringName) -> Array:
    return group[_group] if group.has(_group) else []


func call_group(_group: StringName, _callback_name: StringName, _params: Array):
    if not group.has(_group):
        return
    
    for ref in group[_group]:
        ref.callv(_callback_name, _params)