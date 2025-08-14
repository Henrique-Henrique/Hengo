class_name HenFactoryParam extends RefCounted

static func get_param_from_dict(_data: Dictionary) -> HenSaveCodeType.Param:
	var param: HenSaveCodeType.Param = HenSaveCodeType.Param.new()

	param.name = _data.name
	param.type = _data.type

	return param
