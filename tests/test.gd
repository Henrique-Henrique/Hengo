class_name HenTest extends RefCounted


class CNodeDataCode:
	var data: HenTypeCnode
	var code: String

	func _init(_data: HenTypeCnode, _code: String) -> void:
		data = _data
		code = _code


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
	return HenRouteData.create(
		'Base',
		HenRouter.ROUTE_TYPE.BASE,
		'0',
	)


static func set_global_config() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var router: HenRouter = Engine.get_singleton(&'Router')

	var save_data: HenSaveData = HenSaveData.new()
	var _class: StringName = 'Node'
	var id: int = ResourceUID.create_id()
	var identity: HenSaveDataIdentity = HenSaveDataIdentity.create(str(id), _class, 'Test')

	save_data.identity = identity
	save_data.counter = 1
	save_data.virtual_cnode_list.append(
		{
			can_delete = false,
			id = 1,
			name = 'Stat State',
			position = 'Vector2(0, 0)',
			size = 'Vector2(99, 63)',
			sub_type = 37,
			type = 6
		}
	)

	var base_route: HenRouteData = HenRouteData.create(
		'Base',
		HenRouter.ROUTE_TYPE.BASE,
		HenUtilsName.get_unique_name(),
	)

	save_data.base_route = base_route
	global.SAVE_DATA = save_data
	router.current_route = global.SAVE_DATA.base_route


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
