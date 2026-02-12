@tool
class_name HenSaveParam extends HenSaveResType

@export_custom(PROPERTY_HINT_NONE, 'all_godot_classes')
var type: StringName = &'Variant'


func _init() -> void:
	id = StringName(str((Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()))
	name = get_new_name()
	type = &'Variant'


static func create(data: Dictionary = {}) -> HenSaveParam:
	var p: HenSaveParam = HenSaveParam.new()
	if data:
		if data.has('name'): p.name = data.name
		if data.has('type'): p.type = data.type
		if data.has('id'): p.id = str(data.id)
	return p


func get_data() -> Dictionary:
	return {
		name = name,
		type = type,
		id = id,
	}


func get_new_name() -> String:
	return 'param_' + str(id)


func get_inputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	match _type:
		HenVirtualCNode.SubType.SET_LOCAL_VAR:
			return [
				{
					id = 0,
					name = name,
					type = type,
				}
			]
	return []


func get_outputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	match _type:
		HenVirtualCNode.SubType.LOCAL_VAR:
			return [
				{
					id = 0,
					name = name,
					type = type,
				}
			]
	return []
