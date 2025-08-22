class_name HenFactoryParam extends RefCounted

static func get_param_from_dict(_data: Dictionary) -> HenTypeParam:
	var param: HenTypeParam = HenTypeParam.new()

	param.name = _data.name
	param.type = _data.type

	return param
