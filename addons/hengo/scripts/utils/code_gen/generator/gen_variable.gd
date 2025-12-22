class_name HenGeneratorVariable extends RefCounted

static func get_variables_code(_save_data: HenSaveData) -> String:
	var var_code: String = ''

	for var_data: HenSaveVar in _save_data.variables:
		var_code += get_var_code_from_var(var_data)

	return var_code + ' \n' if var_code else ''


static func get_var_code_base(_type: StringName, _export: bool, _custom_name: String = '', _preview_id: String = '') -> String:
	var var_code: String = ''
	var type_value: String = 'null'

	if HenEnums.VARIANT_TYPES.has(_type):
		if _type == 'Variant':
			type_value = 'null'
		else:
			type_value = _type + '()'
	elif ClassDB.can_instantiate(_type):
		type_value = _type + '.new()'

	var_code += '{export_var}var {name} = {value} {id} \n'.format({
		name = _custom_name,
		value = type_value,
		export_var = '@export ' if _export else '',
		id = '#ID:' + _preview_id if _preview_id else ''
	})

	return var_code


static func get_var_code_from_param(_var_data: HenSaveParam, _custom_name: String = '', _preview_id: String = '') -> String:
	return get_var_code_base(_var_data.type, false, _custom_name, _preview_id)


static func get_var_code_from_var(_var_data: HenSaveVar, _custom_name: String = '', _preview_id: String = '') -> String:
	return get_var_code_base(_var_data.type, _var_data.is_export, _custom_name, _preview_id)