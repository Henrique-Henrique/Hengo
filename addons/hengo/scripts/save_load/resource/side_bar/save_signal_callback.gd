@tool
class_name HenSaveSignalCallback extends HenSaveResTypeWithRoute

@export var params: Array[HenSaveParam]
@export var bind_params: Array[HenSaveParam]
@export var type: StringName
@export var signal_name: StringName
@export var signal_name_to_code: StringName


static func create() -> HenSaveSignalCallback:
	var signal_callback: HenSaveSignalCallback = HenSaveSignalCallback.new()

	signal_callback.id = (Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()
	signal_callback.name = signal_callback.get_new_name()
	signal_callback.type = &'Variant'

	var route: HenRouteData = signal_callback.create_route(HenRouter.ROUTE_TYPE.SIGNAL)

	HenVirtualCNode.instantiate_virtual_cnode({
		name = 'signal',
		sub_type = HenVirtualCNode.SubType.SIGNAL_ENTER,
		route = route,
		position = Vector2.ZERO,
		res_data = signal_callback.get_res_data(HenSideBar.AddType.SIGNAL_CALLBACK),
		can_delete = false
	})

	return signal_callback


func get_new_name() -> String:
	return 'signal_callback_' + str(id)


func get_inputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	match _type:
		HenVirtualCNode.SubType.SIGNAL_CONNECTION:
			var arr: Array[Dictionary] = [
				{
					id = 0,
					name = type,
					type = type,
					is_ref = true
				}
			]

			for param: HenSaveParam in bind_params:
				arr.append(param.get_data())
			
			return arr
		HenVirtualCNode.SubType.SIGNAL_DISCONNECTION:
			return [ {id = 0, name = type, type = type, is_ref = true}]

	return []


func get_outputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	var arr: Array[Dictionary] = []

	match _type:
		HenVirtualCNode.SubType.SIGNAL_ENTER:
			for param: HenSaveParam in params:
				arr.append(param.get_data())
			
			for param: HenSaveParam in bind_params:
				arr.append(param.get_data())

	return arr


func get_connect_cnode_data() -> Dictionary:
	var router: HenRouter = Engine.get_singleton(&'Router')

	return {
		name = name,
		fantasy_name = 'Signal -> ' + name,
		sub_type = HenVirtualCNode.SubType.SIGNAL_CONNECTION,
		route = router.current_route,
		res_data = get_res_data(HenSideBar.AddType.SIGNAL_CALLBACK)
	}


func get_diconnect_cnode_data() -> Dictionary:
	var router: HenRouter = Engine.get_singleton(&'Router')

	return {
			name = name,
			fantasy_name = 'Dis Signal -> ' + name,
			sub_type = HenVirtualCNode.SubType.SIGNAL_DISCONNECTION,
			route = router.current_route,
			res_data = get_res_data(HenSideBar.AddType.SIGNAL_CALLBACK)
	}