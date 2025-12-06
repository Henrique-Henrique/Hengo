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
	return HenRouteData.new(
		'Base',
		HenRouter.ROUTE_TYPE.BASE,
		'0',
	)


static func set_global_config() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var router: HenRouter = Engine.get_singleton(&'Router')

	global.SAVE_DATA = HenSaveData.new()
	global.SAVE_DATA.identity = HenSaveDataIdentity.create(str(ResourceUID.create_id()), 'Node', 'JustTest')

	global.BASE_ROUTE = HenRouteData.new(
		'Base',
		HenRouter.ROUTE_TYPE.BASE,
		'0',
	)

	router.current_route = global.BASE_ROUTE


static func get_parent_ref(_vc: HenVirtualCNode, _refs: HenTypeReferences) -> RefCounted:
	var parent_ref

	# if _vc.route_info.route_ref.ref.get_ref() is HenVirtualCNode:
	# 	parent_ref = HenFactoryCNode.get_cnode_from_dict((_vc.route_info.route_ref.ref.get_ref() as HenVirtualCNode).get_save(_refs.save_data), _refs)
	# else:
	# 	parent_ref = _vc.route_info.route_ref.ref
	
	return parent_ref


static func construct_and_get_code(_base_vc: HenVirtualCNode, _vc_dependencies: Array[HenVirtualCNode], _refs: HenTypeReferences) -> String:
	for vc: HenVirtualCNode in _vc_dependencies:
		HenFactoryCNode.get_cnode_from_dict(vc.get_save(_refs.save_data), _refs, get_parent_ref(vc, _refs))

	var vc: HenTypeCnode = HenFactoryCNode.get_cnode_from_dict(_base_vc.get_save(_refs.save_data), _refs, get_parent_ref(_base_vc, _refs))
	var code: String = ''

	HenFactoryCNode.parse_connections(_refs)

	for token in vc.get_flow_tokens(0):
		code += HenGeneratorByToken.get_code_by_token(token)

	return code


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
