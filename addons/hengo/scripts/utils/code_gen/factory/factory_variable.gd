class_name HenFactoryVariable extends RefCounted

static func get_variable_from_dict(_data: Dictionary, _refs: HenSaveCodeType.References) -> HenSaveCodeType.Variable:
	var variable: HenSaveCodeType.Variable = HenSaveCodeType.Variable.new()
	
	variable.id = _data.id
	variable.name = _data.name
	variable.type = _data.type
	variable.export_var = _data.export

	_refs.side_bar_item_ref[variable.id] = variable

	return variable