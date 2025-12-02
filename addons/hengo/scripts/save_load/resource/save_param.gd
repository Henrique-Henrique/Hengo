@tool
class_name HenSaveParam extends HenSaveResToInspectType

@export var type: StringName = &'Variant'


func _init() -> void:
	id = (Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()
	name = get_new_name()
	type = &'Variant'


static func create() -> HenSaveParam:
	var p: HenSaveParam = HenSaveParam.new()
	return p


func get_data() -> Dictionary:
	return {
		name = name,
		type = type,
		id = id
	}


func get_new_name() -> String:
	return 'param_' + str(id)