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

	route = HenRouteData.new(
		name,
		HenRouter.ROUTE_TYPE.FUNC,
		HenUtilsName.get_unique_name(),
	)

	HenVirtualCNode.instantiate_virtual_cnode({
		name = 'input',
		sub_type = HenVirtualCNode.SubType.FUNC_INPUT,
		route = route,
		position = Vector2.ZERO,
		ref = self,
		can_delete = false,
		res = self,
	})

	HenVirtualCNode.instantiate_virtual_cnode({
		name = 'output',
		sub_type = HenVirtualCNode.SubType.FUNC_OUTPUT,
		route = route,
		position = Vector2(400, 0),
		ref = self,
		can_delete = false,
		res = self,
	})


func get_new_name() -> String:
	return 'function_' + str(id)


func get_data() -> Dictionary:
	var input_data: Array[Dictionary] = []
	var output_data: Array[Dictionary] = []
	var lvars: Array[Dictionary] = []
	var vc_list: Array[Dictionary] = []

	for param: HenSaveParam in inputs:
		input_data.append(param.get_data())

	for param: HenSaveParam in outputs:
		output_data.append(param.get_data())

	for lv: HenSaveParam in local_vars:
		lvars.append(lv.get_data())

	for cnode: HenVirtualCNode in route.virtual_cnode_list:
		vc_list.append(cnode.get_save(null))

	return {
		name = name,
		id = id,
		inputs = input_data,
		outputs = output_data,
		local_vars = lvars,
		virtual_cnode_list = vc_list,
	}


func get_inputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	var arr: Array[Dictionary] = []

	match _type:
		HenVirtualCNode.SubType.FUNC_OUTPUT:
			for param: HenSaveParam in outputs:
				arr.append(param.get_data())
		HenVirtualCNode.SubType.FUNC_INPUT:
			pass
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


func get_cnode_data() -> Dictionary:
	var router: HenRouter = Engine.get_singleton(&'Router')

	return {
		name = name,
		sub_type = HenVirtualCNode.SubType.USER_FUNC,
		route = router.current_route,
		res = self,
	}
