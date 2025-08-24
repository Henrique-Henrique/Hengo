class_name HenCheckerVar extends RefCounted


static func check_changes_var(_dict: Dictionary, _refs: HenRegenerateRefs) -> void:
	var output: Dictionary = _dict.outputs[0]
	var var_data: Dictionary

	# find sidebar var by id
	for _var_data: Dictionary in _refs.side_bar_list.var_list:
		if _var_data.id == _dict.from_side_bar_id:
			var_data = _var_data
			break

	# handle missing var: mark invalid once and request reload
	if not var_data:
		if not _dict.has('invalid') or (_dict.has('invalid') and not _dict.invalid):
			_dict.invalid = true
			_refs.reload = true
		return

	# detect changes
	var name_changed: bool = var_data.name != output.name
	var type_changed: bool = var_data.type != output.type

	if name_changed or type_changed:
		# keep original behavior of assigning name when any change happens
		output.name = var_data.name
		# ensure name_to_code follows the display name when it changes
		if name_changed:
			_dict.name_to_code = var_data.name

		if type_changed:
			output.type = var_data.type
			# remove any connections involving this variable's output id
			if _refs.connections is Array and not (_refs.connections as Array).is_empty():
				var filtered_conns: Array = []
				var connections_changed: bool = false
				for con: Dictionary in _refs.connections:
					# depending on how the edge is stored, the var output id may appear as from_id or to_id
					# also ensure the connection belongs to this cnode by checking *_vc_id
					var involves_var_output: bool = false
					if con.get('from_id') == output.id and con.get('from_vc_id') == _dict.id:
						involves_var_output = true
					if involves_var_output:
						connections_changed = true
					else:
						filtered_conns.append(con)
				if connections_changed:
					_refs.connections = filtered_conns
					_refs.reload = true

		_refs.reload = true