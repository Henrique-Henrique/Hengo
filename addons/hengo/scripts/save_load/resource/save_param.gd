@tool
class_name HenSaveParam extends Resource

@export var id: int
@export var name: String
@export var type: StringName


static func create() -> HenSaveParam:
    var p: HenSaveParam = HenSaveParam.new()
    p.id = (Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()
    p.type = &'Variant'
    return p


func get_data() -> Dictionary:
    return {
        name = name,
        type = type,
        id = id
    }