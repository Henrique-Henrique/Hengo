@tool
class_name HenSaveMacro extends HenSaveResTypeWithRoute

@export var inputs: Array[HenSaveParam]
@export var outputs: Array[HenSaveParam]
@export var flow_inputs: Array[HenSaveParam]
@export var flow_outputs: Array[HenSaveParam]


static func create() -> HenSaveMacro:
	var v: HenSaveMacro = HenSaveMacro.new()
	return v


func _init() -> void:
	id = (Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()
	name = get_new_name()

	route = HenRouteData.create(
        name,
        HenRouter.ROUTE_TYPE.MACRO,
        HenUtilsName.get_unique_name(),
    )

	HenVirtualCNode.instantiate_virtual_cnode({
		name = 'input',
		type = HenVirtualCNode.Type.MACRO_INPUT,
		sub_type = HenVirtualCNode.SubType.MACRO_INPUT,
		route = route,
		position = Vector2.ZERO,
		res = self,
		can_delete = false
	})

	HenVirtualCNode.instantiate_virtual_cnode({
		name = 'output',
		type = HenVirtualCNode.Type.MACRO_OUTPUT,
		sub_type = HenVirtualCNode.SubType.MACRO_OUTPUT,
		route = route,
		position = Vector2(400, 0),
		res = self,
		can_delete = false
	})


func get_data() -> Dictionary:
	return {}


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


func get_cnode_data() -> Dictionary:
	var router: HenRouter = Engine.get_singleton(&'Router')

	return {
			name = name,
			type = HenVirtualCNode.Type.MACRO,
			sub_type = HenVirtualCNode.SubType.MACRO,
			route = router.current_route,
			res = self
	}