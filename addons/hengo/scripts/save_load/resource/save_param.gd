@tool
class_name HenSaveParam extends HenSaveResType

@export_custom(PROPERTY_HINT_NONE, 'all_godot_classes')
var type: StringName = &'Variant':
	set(v):
		type = v
		default_value = null
		notify_property_list_changed()

var default_value: Variant = null


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
		if data.has('default_value'): p.default_value = data.default_value
	return p


func get_data() -> Dictionary:
	return {
		name = name,
		type = type,
		id = id,
		default_value = default_value
	}


func _get_property_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	var variant_type_int: int = HenUtils.get_variant_type_from_string(type)
	
	if variant_type_int != TYPE_NIL or type == &'Variant':
		list.append({
			name = 'default_value',
			type = variant_type_int if variant_type_int != TYPE_NIL else TYPE_STRING,
			usage = PROPERTY_USAGE_DEFAULT
		})
	
	return list


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
