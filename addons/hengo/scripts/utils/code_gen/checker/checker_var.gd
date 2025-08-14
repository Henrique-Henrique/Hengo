class_name HenCheckerVar extends RefCounted

static func check_changes_var(_dict: Dictionary, _refs: HenRegenerateRefs) -> void:
	var output: Dictionary = _dict.outputs[0]
	var var_data: Dictionary

	for _var_data: Dictionary in _refs.side_bar_list.var_list:
		if _var_data.id == _dict.from_side_bar_id:
			var_data = _var_data
			break


	if var_data:
		if var_data.name != output.name or var_data.type != output.type:
			output.name = var_data.name

			if output.type != var_data.type:
				output.type = var_data.type

				_refs.disconnect_list.append({
					id=_dict.id,
					output_id=output.id,
				})

			_refs.reload = true
	else:
		if not _dict.has('invalid') or _dict.has('invalid') and not _dict.invalid:
			_dict.invalid = true
			_refs.reload = true