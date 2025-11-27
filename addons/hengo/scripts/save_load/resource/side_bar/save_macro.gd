@tool
class_name HenSaveMacro extends HenSaveResTypeWithRoute

@export var inputs: Array[HenSaveParam]
@export var outputs: Array[HenSaveParam]
@export var flow_inputs: Array[HenSaveParam]
@export var flow_outputs: Array[HenSaveParam]

var input_ref: WeakRef
var output_ref: WeakRef


static func create() -> HenSaveMacro:
    var v: HenSaveMacro = HenSaveMacro.new()
    v.id = (Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()
    return v


func get_inputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
    var arr: Array[Dictionary] = []

    for param: HenSaveParam in inputs:
        arr.append(param.get_data())

    return arr


func get_outputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
    var arr: Array[Dictionary] = []

    for param: HenSaveParam in outputs:
        arr.append(param.get_data())

    return arr


func get_cnode_data() -> Dictionary:
    var router: HenRouter = Engine.get_singleton(&'Router')

    return {
            name = name,
            type = HenVirtualCNode.Type.MACRO,
            sub_type = HenVirtualCNode.SubType.MACRO,
            route = router.current_route,
            res = self
    }