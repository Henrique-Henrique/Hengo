@tool
@abstract
class_name HenSaveResToInspectType extends Resource

@export var name: String
@export var id: int

@abstract func get_new_name() -> String

# hides the default resource section properties
func _validate_property(_property: Dictionary) -> void:
	if _property.name == &'id':
		_property.usage = PROPERTY_USAGE_STORAGE

	if _property.name in [&'resource_local_to_scene', &'resource_path', &'resource_name']:
		_property.usage = PROPERTY_USAGE_NONE
	

func _property_can_revert(property: StringName) -> bool:
	if property == &'name':
		return true
	return false
	

func _property_get_revert(_property: StringName) -> Variant:
	if _property == &'name':
		return get_new_name()
	return null