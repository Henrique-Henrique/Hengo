class_name HenGeneratorVariable extends RefCounted

static func get_variables_code(_save_data: HenSaveData) -> String:
	var var_code: String = ''

	for var_data: HenSaveVar in _save_data.variables:
		var_code += get_var_code_from_var(var_data)

	return var_code + ' \n' if var_code else ''


static func _is_node_type(_type: StringName) -> bool:
	return ClassDB.class_exists(_type) and ClassDB.is_parent_class(_type, &'Node')


static func get_var_code_base(_type: StringName, _export: bool, _custom_name: String = '', _preview_id: String = '', _default_value: Variant = null, _holds_instance: bool = false) -> String:
	var var_code: String = ''
	var type_value: String = 'null'
	var starts_empty: bool = _holds_instance or _is_node_type(_type)
	# a variable holding another node starts empty; instancing its base would only
	# create a stray node, so the type is declared instead (an export needs one)
	var type_hint: String = ': ' + _type if starts_empty and _export else ''

	if starts_empty:
		type_value = 'null'
	elif _default_value != null:
		type_value = var_to_str(_default_value)
	else:
		if HenEnums.VARIANT_TYPES.has(_type):
			if _type == 'Variant':
				type_value = 'null'
			else:
				type_value = _type + '()'
		elif ClassDB.can_instantiate(_type):
			type_value = _type + '.new()'

	var_code += '{export_var}var {name}{type_hint} = {value} {id} \n'.format({
		name = _custom_name.to_snake_case(),
		type_hint = type_hint,
		value = type_value,
		export_var = '@export ' if _export else '',
		id = '#ID:' + _preview_id if _preview_id else ''
	})

	return var_code


static func get_var_code_from_param(_var_data: HenSaveParam, _custom_name: String, _preview_id: String = '') -> String:
	return get_var_code_base(_var_data.type, false, _custom_name, _preview_id, _var_data.default_value)


static func get_var_code_from_var(_var_data: HenSaveVar) -> String:
	return get_var_code_base(_var_data.type, _var_data.is_export, _var_data.name, '', _var_data.default_value, not _var_data.script_id.is_empty())