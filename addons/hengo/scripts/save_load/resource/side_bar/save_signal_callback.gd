@tool
class_name HenSaveSignalCallback extends HenSaveResTypeWithRoute

@export var params: Array[HenSaveParam]
@export var bind_params: Array[HenSaveParam]
@export var type: StringName
@export var signal_name: StringName
@export var signal_name_to_code: StringName


static func create() -> HenSaveSignalCallback:
	var v: HenSaveSignalCallback = HenSaveSignalCallback.new()
	return v


func _init() -> void:
	id = (Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()
	name = get_new_name()
	type = &'Variant'

	route = HenRouteData.create(
		name,
		HenRouter.ROUTE_TYPE.SIGNAL,
		HenUtilsName.get_unique_name(),
	)

	HenVirtualCNode.instantiate_virtual_cnode({
		name = 'signal',
		sub_type = HenVirtualCNode.SubType.SIGNAL_ENTER,
		route = route,
		position = Vector2.ZERO,
		res = self,
		can_delete = false
	})


func get_new_name() -> String:
	return 'signal_callback_' + str(id)


func get_data() -> Dictionary:
	var param_data: Array[Dictionary] = []
	var bind_param_data: Array[Dictionary] = []
	var lvars: Array[Dictionary] = []
	var vc_list: Array[Dictionary] = []

	for param: HenSaveParam in params:
		param_data.append(param.get_data())

	for param: HenSaveParam in bind_params:
		bind_param_data.append(param.get_data())

	for lv: HenSaveParam in local_vars:
		lvars.append(lv.get_data())

	for cnode: HenVirtualCNode in route.virtual_cnode_list:
		vc_list.append(cnode.get_save(null))

	return {
		name = name,
		id = id,
		params = param_data,
		bind_params = bind_param_data,
		type = type,
		signal_name = signal_name,
		signal_name_to_code = signal_name_to_code,
		local_vars = lvars,
		virtual_cnode_list = vc_list,
	}


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
		res = self
	}


func get_diconnect_cnode_data() -> Dictionary:
	var router: HenRouter = Engine.get_singleton(&'Router')

	return {
			name = name,
			fantasy_name = 'Dis Signal -> ' + name,
			sub_type = HenVirtualCNode.SubType.SIGNAL_DISCONNECTION,
			route = router.current_route,
			res = self
	}