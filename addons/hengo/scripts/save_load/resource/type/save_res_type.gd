@tool
@abstract
class_name HenSaveResType extends Resource

@export var name: String
@export var id: int

@abstract func get_inputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]
@abstract func get_outputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]