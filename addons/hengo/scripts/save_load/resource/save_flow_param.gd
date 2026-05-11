@tool
class_name HenSaveFlowParam extends HenSaveParam


static func create(data: Dictionary = {}) -> HenSaveFlowParam:
	var p: HenSaveFlowParam = HenSaveFlowParam.new()
	if data:
		if data.has('name'): p.name = data.name
		if data.has('id'): p.id = str(data.id)
	return p


func get_data() -> Dictionary:
	return {
		name = name,
		id = id,
	}


func _validate_property(prop: Dictionary) -> void:
	super (prop)
	if prop.name == &'type' or prop.name == &'default_value':
		prop.usage = PROPERTY_USAGE_STORAGE


func get_new_name() -> String:
	return 'flow_' + str(id)
