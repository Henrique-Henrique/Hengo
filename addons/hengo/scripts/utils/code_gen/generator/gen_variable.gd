class_name HenGeneratorVariable extends RefCounted

static func get_variables_code(_refs: HenTypeReferences) -> String:
	var var_code: String = ''

	for var_data: HenTypeVariable in _refs.variables:
		var_code += get_var_code(var_data)

	return var_code + ' \n' if var_code else ''


static func get_var_code(_var_data: HenTypeVariable, _custom_name: String = '', _preview_id: String = '') -> String:
	var var_code: String = ''
	var type_value: String = 'null'

	if HenEnums.VARIANT_TYPES.has(_var_data.type):
		if _var_data.type == 'Variant':
			type_value = 'null'
		else:
			type_value = _var_data.type + '()'
	elif ClassDB.can_instantiate(_var_data.type):
		type_value = _var_data.type + '.new()'

	var_code += ' {export_var} var {name} = {value} {id} \n'.format({
		name = _var_data.name.to_snake_case() if not _custom_name else _custom_name,
		value = type_value,
		export_var = '@export ' if _var_data.export_var else '',
		id = '#ID:' + _preview_id if _preview_id else ''
	})

	return var_code