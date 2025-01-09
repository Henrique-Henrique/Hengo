@tool
class_name HenApiGenerator


static func _generate_native_api() -> void:
	var file: FileAccess = FileAccess.open('res://extension_api.json', FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text())

	var native_api: Dictionary = {}
	var const_api: Dictionary = {}
	var singleton_api: Array = []
	var singleton_names: Array = []
	var native_props: Dictionary = {}
	var math_utility_names: Array = []

	for dict: Dictionary in (data['utility_functions'] as Array):
		if dict.category == 'math':
			math_utility_names.append(dict.name)


	for dict: Dictionary in (data['builtin_classes'] as Array):
		if HenEnums.VARIANT_TYPES.has(dict.name):
			if dict.has('members'):
				native_props[dict.name] = dict.members

			if dict.has('methods'):
				var arr: Array = []
				
				for method: Dictionary in dict['methods']:
					# static
					if method.is_static:
						var dt: Dictionary = {
							name = '',
							sub_type = 'singleton',
						}

						if method.has('arguments'):
							dt.inputs = _parse_arguments(method)
						
						if method.has('return_type'):
							dt['outputs'] = [ {
								name = '',
								type = _parse_enum_return(method.return_type)
							}]

						singleton_api.append({
							name = dict.name + '.' + method.name,
							data = dt
						})
					else:
						var dt: Dictionary = {
							name = method.name,
							sub_type = 'func',
							inputs = [ {
								name = dict.name,
								type = dict.name,
								ref = true
							}]
						}
						
						if method.has('arguments'):
							dt.inputs += _parse_arguments(method)
						
						if method.has('return_type'):
							dt['outputs'] = [ {
								name = '',
								type = _parse_enum_return(method.return_type)
							}]

						arr.append({
							name = method.name,
							data = dt
						})


				if not arr.is_empty():
					native_api[dict.name] = arr

			if dict.has('constants'):
				var arr: Array = []

				for constant: Dictionary in dict['constants']:
					var dt: Dictionary = {
						name = constant.name,
						type = constant.type
					}

					arr.append(dt)
				
				const_api[dict.name] = _generate_consts(dict)


	# parsing singleton names
	for dict: Dictionary in (data['singletons'] as Array):
		singleton_names.append(dict.name)

	# parsing classes const, enums...
	for dict: Dictionary in (data['classes'] as Array):
		if dict.has('methods'):
			for method: Dictionary in dict['methods']:
				# static
				if method.is_static or singleton_names.has(dict.name):
					var dt: Dictionary = {
						name = dict.name + '.' + method.name,
						fantasy_name = dict.name + ' -> ' + method.name,
						sub_type = 'singleton',
					}

					if method.has('arguments'):
						dt.inputs = _parse_arguments(method)
					
					if method.has('return_value'):
						dt['outputs'] = [ {
							name = '',
							type = _parse_enum_return(method.return_value.type)
						}]

					# if dict.name.contains('is_action_pressed'):
					print({
						name = dict.name + ' -> ' + method.name,
						data = dt
					})

					singleton_api.append({
						name = dict.name + ' -> ' + method.name,
						data = dt
					})

		if dict.has('constants'):
			const_api[dict.name] = _generate_consts(dict)
		
		if dict.has('enums'):
			if const_api.has(dict.name):
				const_api[dict.name] += _generate_enums(dict)
			else:
				const_api[dict.name] = _generate_enums(dict)

	var file_json: FileAccess = FileAccess.open(HenEnums.NATIVE_API_PATH, FileAccess.WRITE)

	file_json.store_string(
		JSON.stringify({
			native_api = native_api,
			const_api = const_api,
			singleton_api = singleton_api,
			native_props = native_props,
			math_utility_names = math_utility_names
		})
	)

	file_json.close()

	print('HENGO NATIVE API GENERATED!!')


static func _parse_enum_return(_type: String) -> String:
	return _type.split('.')[-1] if _type.begins_with('enum::') else _type


static func _parse_arguments(_dict: Dictionary) -> Array:
	var arr: Array = []

	for arg in _dict.arguments:
		var arg_dt: Dictionary = {
			name = arg.name
		}

		# parsing enums
		if arg.type.begins_with('enum::'):
			var enum_name: String = arg.type.split('.')[-1]

			arg_dt.type = enum_name
			arg_dt.sub_type = '@dropdown'
			arg_dt.category = 'enum_list'
			arg_dt.data = [_dict.name, enum_name]
		else:
			arg_dt.type = arg.type
		
		arr.append(arg_dt)

	return arr


static func _generate_consts(_dict: Dictionary) -> Array:
	var arr: Array = []

	for constant: Dictionary in _dict['constants']:
		var dt: Dictionary = {
			name = constant.name,
			type = constant.type if constant.has('type') else 'Variant'
		}

		arr.append(dt)

	return arr


static func _generate_enums(_dict: Dictionary) -> Array:
	var arr: Array = []

	for enum_value in _dict.enums:
		arr += enum_value.values.map(func(x: Dictionary) -> Dictionary: return {
			name = x.name,
			type = enum_value.name
		})
	
	return arr
