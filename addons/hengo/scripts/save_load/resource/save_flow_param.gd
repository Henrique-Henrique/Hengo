@tool
class_name HenSaveFlowParam extends HenSaveParam


static func create(data: Dictionary = {}) -> HenSaveFlowParam:
	var p: HenSaveFlowParam = HenSaveFlowParam.new()
	if data:
		if data.has('name'): p.name = data.name
		if data.has('id'): p.id = str(data.id)
		if data.has('doc'): p.doc = str(data.doc)
	return p


func get_data() -> Dictionary:
	return {
		name = name,
		id = id,
		doc = doc,
	}


func _validate_property(prop: Dictionary) -> void:
	super (prop)
	if prop.name == &'type' or prop.name == &'default_value':
		prop.usage = PROPERTY_USAGE_STORAGE


func get_new_name() -> String:
	return 'flow_' + str(id)
