class_name HenRegenerateRefs

var reload: bool = false: set = can_reload
var cnode_list: Dictionary = {}
var disconnect_list: Array
var connections: Array
var counter: int
var side_bar_list: Dictionary
var side_bar_from_id: StringName
var ref_data: Dictionary

func get_new_node_counter() -> int:
    counter += 1
    return counter

func can_reload(_can: bool) -> void:
    if reload == true:
        return
    
    reload = _can
