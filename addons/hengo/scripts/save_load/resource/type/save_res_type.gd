@tool
@abstract
class_name HenSaveResType extends HenSaveResToInspectType

@abstract func get_inputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]
@abstract func get_outputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]