class_name HenFactoryIO extends RefCounted

static func get_inout_from_dict(_is_input: bool, _inout: Dictionary, _code_value_map: Dictionary = {}) -> HenTypeInout:
	var input: HenTypeInout = HenTypeInout.new()

	input.id = int(_inout.id)
	input.name = _inout.name
	input.type = _inout.type

	if _inout.has(&'sub_type'): input.sub_type = _inout.sub_type
	if _inout.has(&'category'): input.category = _inout.category
	if _inout.has(&'is_ref'): input.is_ref = _inout.is_ref
	if _inout.has(&'data'): input.data = _inout.data
	if _inout.has(&'is_prop'): input.is_prop = _inout.is_prop
	if _inout.has(&'is_static'): input.is_static = _inout.is_static

	if _is_input:
		if _code_value_map.has(&'code_value') and _code_value_map.get(&'type') == input.type:
			input.code_value = _code_value_map.code_value
		else:
			input.reset_input_value()

	if _is_input:
		if _code_value_map.has(&'value') and _code_value_map.get(&'type') == input.type:
			input.value = _code_value_map.value
		else:
			input.reset_input_value()

	return input
