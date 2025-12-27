@tool
class_name HenSaveFunc extends HenSaveResTypeWithRoute

@export var inputs: Array[HenSaveParam]
@export var outputs: Array[HenSaveParam]


static func create() -> HenSaveFunc:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var my_func: HenSaveFunc = HenSaveFunc.new()

	my_func.id = global.get_new_node_counter()
	my_func.name = my_func.get_new_name()

	var route: HenRouteData = my_func.create_route(HenRouter.ROUTE_TYPE.FUNC)

	HenVirtualCNode.instantiate_virtual_cnode({
		name = 'input',
		sub_type = HenVirtualCNode.SubType.FUNC_INPUT,
		route = route,
		position = Vector2.ZERO,
		can_delete = false,
		res_data = my_func.get_res_data(HenSideBar.AddType.FUNC)
	})

	HenVirtualCNode.instantiate_virtual_cnode({
		name = 'output',
		sub_type = HenVirtualCNode.SubType.FUNC_OUTPUT,
		route = route,
		position = Vector2(400, 0),
		can_delete = false,
		res_data = my_func.get_res_data(HenSideBar.AddType.FUNC)
	})

	return my_func


func get_new_name() -> String:
	return 'function_' + str(id)


func get_inputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	var arr: Array[Dictionary] = []

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
		res_data = get_res_data(HenSideBar.AddType.FUNC, _save_data_id)
	}
