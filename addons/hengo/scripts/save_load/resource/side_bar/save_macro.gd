@tool
class_name HenSaveMacro extends HenSaveResTypeWithRoute

@export var inputs: Array[HenSaveParam]
@export var outputs: Array[HenSaveParam]
@export var flow_inputs: Array[HenSaveParam]
@export var flow_outputs: Array[HenSaveParam]


static func create() -> HenSaveMacro:
	var macro: HenSaveMacro = HenSaveMacro.new()

	macro.id = (Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()
	macro.name = macro.get_new_name()

	var route: HenRouteData = macro.create_route(HenRouter.ROUTE_TYPE.MACRO)

	HenVirtualCNode.instantiate_virtual_cnode({
		name = 'input',
		type = HenVirtualCNode.Type.MACRO_INPUT,
		sub_type = HenVirtualCNode.SubType.MACRO_INPUT,
		route = route,
		position = Vector2.ZERO,
		res_data = macro.get_res_data(HenSideBar.AddType.MACRO),
		can_delete = false
	})

	HenVirtualCNode.instantiate_virtual_cnode({
		name = 'output',
		type = HenVirtualCNode.Type.MACRO_OUTPUT,
		sub_type = HenVirtualCNode.SubType.MACRO_OUTPUT,
		route = route,
		position = Vector2(400, 0),
		res_data = macro.get_res_data(HenSideBar.AddType.MACRO),
		can_delete = false
	})

	return macro


func get_new_name() -> String:
	return 'macro_' + str(id)


func get_inputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	var arr: Array[Dictionary] = []

	match _type:
		HenVirtualCNode.SubType.MACRO_OUTPUT:
			for param: HenSaveParam in outputs:
				arr.append(param.get_data())

	return arr


func get_outputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	var arr: Array[Dictionary] = []

	match _type:
		HenVirtualCNode.SubType.MACRO_INPUT:
			for param: HenSaveParam in inputs:
				arr.append(param.get_data())

	return arr


func get_cnode_data(_save_data_id: StringName, _from_another_script: bool = false) -> Dictionary:
	var router: HenRouter = Engine.get_singleton(&'Router')

	return {
			name = name,
			type = HenVirtualCNode.Type.MACRO,
			sub_type = HenVirtualCNode.SubType.MACRO,
			route = router.current_route,
			res_data = get_res_data(HenSideBar.AddType.MACRO, _save_data_id)
	}