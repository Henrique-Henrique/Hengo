class_name HenFactoryVariable extends RefCounted

static func get_variable_from_dict(_data: Dictionary, _refs: HenTypeReferences) -> HenTypeVariable:
	var variable: HenTypeVariable = HenTypeVariable.new()
	
	variable.id = _data.id
	variable.name = _data.name
	variable.type = _data.type
	variable.export_var = _data.get('export', false)

	_refs.side_bar_item_ref[variable.id] = variable

	return variable