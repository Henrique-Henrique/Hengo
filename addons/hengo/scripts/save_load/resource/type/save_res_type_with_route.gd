@tool
@abstract
class_name HenSaveResTypeWithRoute extends HenSaveResType

@export var local_vars: Array[HenSaveParam]


func get_route(_save_data: HenSaveData) -> HenRouteData:
	return _save_data.get_route(str(id))


func create_route(_type: HenRouter.ROUTE_TYPE) -> HenRouteData:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	return global.SAVE_DATA.create_route(str(id), name, _type)


# hides the default resource section properties
func _validate_property(_property: Dictionary) -> void:
	super (_property)
	if _property.name in [&'virtual_cnode_list']:
		_property.usage = PROPERTY_USAGE_STORAGE