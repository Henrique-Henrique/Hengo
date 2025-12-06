@tool
@abstract
class_name HenSaveResTypeWithRoute extends HenSaveResType

@export var virtual_cnode_list: Array[Dictionary]
@export var local_vars: Array[HenSaveParam]

var route: HenRouteData

@abstract func get_data() -> Dictionary

# hides the default resource section properties
# func _validate_property(_property: Dictionary) -> void:
# 	super (_property)
# 	if _property.name in [&'virtual_cnode_list']:
# 		_property.usage = PROPERTY_USAGE_NONE