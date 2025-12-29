@tool
@abstract
class_name HenSaveResType extends HenSaveResToInspectType

func get_inputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
    return []

func get_outputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
    return []

func get_flow_inputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
    return [ {id = 0}]

func get_flow_outputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
    return [ {id = 0}]