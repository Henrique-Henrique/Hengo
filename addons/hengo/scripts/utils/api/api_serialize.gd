class_name HenApiSerialize extends RefCounted


static func get_utility_data(_name: String, _dict: Dictionary) -> Dictionary:
	var obj: Dictionary = {
		name = _name,
		sub_type = HenVirtualCNode.SubType.VOID,
		category = 'native',
	}


	if _dict.has(&'params'):
		obj.inputs = (_dict.params as Array).duplicate()
	
	if _dict.has(&'return_type'):
		obj.sub_type = HenVirtualCNode.SubType.FUNC

		obj.outputs = [
			{
				name = '',
				type = _dict.return_type
			}
		]


	return obj


static func get_func_void_hengo_data(_dict: Dictionary) -> Dictionary:
	var router: HenRouter = Engine.get_singleton(&'Router')
	var _class_name = _dict.get(&'_class_name', 'Variant')

	var obj: Dictionary = {
		name = _dict.name,
		sub_type = HenVirtualCNode.SubType.FUNC if _dict.has(&'return_type') else HenVirtualCNode.SubType.VOID,
		route = router.current_route
	}

	if _dict.get(&'is_virtual', false):
		obj.outputs = _dict.get(&'params', [])
		obj.sub_type = HenVirtualCNode.SubType.OVERRIDE_VIRTUAL
	else:
		obj.inputs = []

		if _dict.get(&'is_static', false):
			obj.singleton_class = _class_name
		elif not _dict.get(&'is_utility', false):
			(obj.inputs as Array).append({
				name = _class_name,
				type = _class_name,
				is_ref = true
			})

		obj.inputs += _dict.get(&'params', [])
			

	if _dict.has(&'return_type'):
		obj.outputs = [
			{
				name = '',
				type = _dict.return_type
			}
		]

	return obj
