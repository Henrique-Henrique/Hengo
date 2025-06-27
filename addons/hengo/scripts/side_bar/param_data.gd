class_name HenParamData extends RefCounted

var id: int = HenGlobal.get_new_node_counter()
var name: String: set = on_change_name
var type: String = &'Variant': set = on_change_type

signal moved
signal deleted

# used in inOut virtual cnode
signal data_changed(_property: String, _value)

func on_change_name(_name) -> void:
    data_changed.emit('name', _name)
    name = _name

func on_change_type(_type) -> void:
    data_changed.emit('type', _type)
    type = _type


func get_data() -> Dictionary:
    return {name = name, type = type, ref = self}
    
func get_data_with_id() -> Dictionary:
    return {id = id, name = name, type = type, ref = self}


func get_save() -> Dictionary:
    return {
        name = name,
        type = type,
        id = id
    }

func get_save_without_id() -> Dictionary:
    return {
        name = name,
        type = type
    }

func get_save_with_from_id() -> Dictionary:
    return {
        name = name,
        type = type,
        from_id = id
    }

func load_save(_data: Dictionary) -> void:
    id = _data.id
    
    HenGlobal.SIDE_BAR_LIST_CACHE[id] = self

    name = _data.name
    type = _data.type
