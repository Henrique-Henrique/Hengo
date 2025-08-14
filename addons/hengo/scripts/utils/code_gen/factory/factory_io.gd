class_name HenFactoryIO extends RefCounted

static func get_inout_from_dict(_inout: Dictionary) -> HenSaveCodeType.Inout:
	var input: HenSaveCodeType.Inout = HenSaveCodeType.Inout.new()

	input.id = int(_inout.id)
	input.name = _inout.name
	input.type = _inout.type

	if _inout.has('sub_type'): input.sub_type = _inout.sub_type
	if _inout.has('category'): input.category = _inout.category
	if _inout.has('is_ref'): input.is_ref = _inout.is_ref
	if _inout.has('code_value'): input.code_value = _inout.code_value
	if _inout.has('value'): input.value = _inout.value
	if _inout.has('data'): input.data = _inout.data
	if _inout.has('is_prop'): input.is_prop = _inout.is_prop
	if _inout.has('is_static'): input.is_static = _inout.is_static

	return input
