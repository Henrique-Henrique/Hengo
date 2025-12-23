@tool
class_name HenSaveFunc extends HenSaveResTypeWithRoute

@export var inputs: Array[HenSaveParam]
@export var outputs: Array[HenSaveParam]


static func create() -> HenSaveFunc:
	var v: HenSaveFunc = HenSaveFunc.new()
	return v


func _init() -> void:
	id = (Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()
	name = get_new_name()

	route = HenRouteData.create(
		name,
		HenRouter.ROUTE_TYPE.FUNC,
		HenUtilsName.get_unique_name(),
	)

	HenVirtualCNode.instantiate_virtual_cnode({
		name = 'input',
		sub_type = HenVirtualCNode.SubType.FUNC_INPUT,
		route = route,
		position = Vector2.ZERO,
		can_delete = false,
		res_data = get_res_data()
	})

	HenVirtualCNode.instantiate_virtual_cnode({
		name = 'output',
		sub_type = HenVirtualCNode.SubType.FUNC_OUTPUT,
		route = route,
		position = Vector2(400, 0),
		can_delete = false,
		res_data = get_res_data()
	})


func get_res_data(_save_data_id: StringName = '') -> Dictionary:
	var dt: Dictionary = {
		id = id,
		type = HenSideBar.AddType.FUNC,
	}

	if _save_data_id:
		dt.save_data_id = _save_data_id

	return dt


func get_new_name() -> String:
	return 'function_' + str(id)


func get_inputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	var arr: Array[Dictionary] = []

	print(983)

	match _type:
		HenVirtualCNode.SubType.FUNC_OUTPUT:
			for param: HenSaveParam in outputs:
				arr.append(param.get_data())
		HenVirtualCNode.SubType.FUNC_INPUT:
			pass
		HenVirtualCNode.SubType.FUNC_FROM:
			arr.append({
				id = 0,
				name = name,
				type = &'Variant',
				is_ref = true
			})
			
			for param: HenSaveParam in inputs:
				arr.append(param.get_data())
		_:
			for param: HenSaveParam in inputs:
				arr.append(param.get_data())

	return arr


func get_outputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	var arr: Array[Dictionary] = []

	match _type:
		HenVirtualCNode.SubType.FUNC_INPUT:
			for param: HenSaveParam in inputs:
				arr.append(param.get_data())
		HenVirtualCNode.SubType.FUNC_OUTPUT:
			pass
		_:
			for param: HenSaveParam in outputs:
				arr.append(param.get_data())

	return arr


func get_cnode_data(_save_data_id: StringName, _from_another_script: bool = false) -> Dictionary:
	var router: HenRouter = Engine.get_singleton(&'Router')

	return {
		name = name,
		sub_type = HenVirtualCNode.SubType.USER_FUNC if not _from_another_script else HenVirtualCNode.SubType.FUNC_FROM,
		route = router.current_route,
		res_data = get_res_data(_save_data_id)
	}
