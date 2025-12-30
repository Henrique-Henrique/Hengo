class_name HenTest extends RefCounted


class CNodeConnection:
	var from: HenVirtualCNode
	var to: HenVirtualCNode
	var from_id: int
	var to_id: int

	func _init(_from: HenVirtualCNode, _to: HenVirtualCNode, _from_id: int = 0, _to_id: int = 0) -> void:
		from = _from
		to = _to
		from_id = _from_id
		to_id = _to_id


static func get_base_route() -> HenRouteData:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	return global.SAVE_DATA.get_route(global.SAVE_DATA.identity.id)


static func set_global_config() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var router: HenRouter = Engine.get_singleton(&'Router')

	var save_data: HenSaveData = HenSaveData.new()
	var _class: StringName = 'Node'
	var id: int = ResourceUID.create_id()
	var identity: HenSaveDataIdentity = HenSaveDataIdentity.create(str(id), _class, 'Test')

	save_data.identity = identity
	save_data.counter = 1

	var base_route: HenRouteData = HenRouteData.create(
		'Base',
		HenRouter.ROUTE_TYPE.BASE,
		save_data.identity.id,
	)

	save_data.add_route(save_data.identity.id, base_route)

	global.SAVE_DATA = save_data
	global.IS_HEADLESS = true
	router.current_route = global.SAVE_DATA.get_base_route()

	var map_deps: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
	map_deps.ast_list.set(save_data.identity.id, HenUtils.get_current_ast_list())


static func get_void(_route: HenRouteData = null) -> HenVirtualCNode:
	return HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_void',
		sub_type = HenVirtualCNode.SubType.VOID,
		route = HenTest.get_base_route() if not _route else _route
	})


static func get_void_with_input(_id: int = -1) -> HenVirtualCNode:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	return HenVirtualCNode.instantiate_virtual_cnode({
		id = _id if _id >= 0 else global.get_new_node_counter(),
		name = 'test_void',
		sub_type = HenVirtualCNode.SubType.VOID,
		category = 'native',
		inputs = [
			{
				id = 0,
				name = 'content',
				type = 'Variant'
			}
		],
		route = HenTest.get_base_route()
	})


static func get_const(_id: int = -1) -> HenVirtualCNode:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	return HenVirtualCNode.instantiate_virtual_cnode({
		id = _id if _id >= 0 else global.get_new_node_counter(),
		name = 'Test',
		name_to_code = 'CONST',
		outputs = [
			{
				id = 0,
				name = 'CONST',
				type = 'Variant'
			}
		],
		sub_type = HenVirtualCNode.SubType.CONST,
		type = 0,
		route = HenTest.get_base_route()
	})


static func get_vc_code(_vc: HenVirtualCNode) -> String:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var save_data: HenSaveData = global.SAVE_DATA

	# this is a hack to make the tests errors accurate only for code generation
	global.SAVE_DATA = null
	var code: String = HenVirtualCNodeCode.get_virtual_cnode_code(save_data, _vc)
	global.SAVE_DATA = save_data
	return code


static func get_all_code() -> String:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var code_generation: HenCodeGeneration = Engine.get_singleton(&'CodeGeneration')
	var save_data: HenSaveData = global.SAVE_DATA

	# this is a hack to make the tests errors accurate only for code generation
	global.SAVE_DATA = null
	var code: String = code_generation.get_code(save_data)
	global.SAVE_DATA = save_data
	return code