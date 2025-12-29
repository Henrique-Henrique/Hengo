@tool
class_name HenSaveState extends HenSaveResTypeWithRoute

@export var flow_outputs: Array[HenSaveParam]


static func create() -> HenSaveState:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var state: HenSaveState = HenSaveState.new()

	state.id = global.get_new_node_counter()
	state.name = state.get_new_name()

	var route: HenRouteData = state.create_route(HenRouter.ROUTE_TYPE.STATE)

	HenVirtualCNode.instantiate_virtual_cnode({
		name = 'enter',
		sub_type = HenVirtualCNode.SubType.VIRTUAL,
		route = route,
		position = Vector2.ZERO,
		can_delete = false
	})

	HenVirtualCNode.instantiate_virtual_cnode({
		name = 'update',
		sub_type = HenVirtualCNode.SubType.VIRTUAL,
		outputs = [ {
			name = 'delta',
			type = 'float'
		}],
		route = route,
		position = Vector2(400, 0),
		can_delete = false
	})

	return state


func get_new_name() -> String:
	return 'state_' + str(id)


func get_inputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	return []


func get_outputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	return []


func get_cnode_data(_save_data_id: StringName, _from_another_script: bool = false) -> Dictionary:
	var router: HenRouter = Engine.get_singleton(&'Router')

	return {
		name = name,
		type = HenVirtualCNode.Type.STATE,
		sub_type = HenVirtualCNode.SubType.STATE if not _from_another_script else HenVirtualCNode.SubType.STATE,
		route = router.current_route,
		res_data = get_res_data(HenSideBar.AddType.STATE, _save_data_id)
	}