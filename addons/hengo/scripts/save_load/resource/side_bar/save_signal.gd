@tool
class_name HenSaveSignal extends HenSaveResType

@export var inputs: Array[HenSaveParam]

static func create() -> HenSaveSignal:
    var v: HenSaveSignal = HenSaveSignal.new()
    v.id = (Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()
    return v


func get_inputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
    var arr: Array[Dictionary] = []

    for param: HenSaveParam in inputs:
        arr.append(param.get_data())

    return arr


func get_outputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
    return []