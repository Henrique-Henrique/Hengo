class_name HenTest extends RefCounted


class CNodeDataCode:
	var data: HenSaveCodeType.CNode
	var code: String

	func _init(_data: HenSaveCodeType.CNode, _code: String) -> void:
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
	if not HenGlobal.BASE_ROUTE_REF:
		HenGlobal.BASE_ROUTE_REF = HenLoader.BaseRouteRef.new()
	
	return HenRouteData.new(
		'Base',
		HenRouter.ROUTE_TYPE.BASE,
		'0',
		weakref(HenGlobal.BASE_ROUTE_REF)
	)


static func set_global_config() -> void:
	# setting global
	var global_script_data := HenGlobal.ScriptData.new()

	global_script_data.id = 0
	global_script_data.path = 'res://hengo/test.gd'
	global_script_data.type = 'Sprite2D'

	HenGlobal.script_config = global_script_data
	HenGlobal.SIDE_BAR_LIST = HenSideBar.SideBarList.new()
	HenGlobal.BASE_ROUTE_REF = HenLoader.BaseRouteRef.new()
	HenGlobal.BASE_ROUTE = HenRouteData.new(
		'Base',
		HenRouter.ROUTE_TYPE.BASE,
		'0',
		weakref(HenGlobal.BASE_ROUTE_REF)
	)


static func get_virtual_cnode_code(_vc: HenVirtualCNode, _refs: HenSaveCodeType.References) -> CNodeDataCode:
	var ref

	if _vc.route_info.route_ref.ref.get_ref() is HenVirtualCNode:
		ref = HenFactoryCNode.get_cnode_from_dict((_vc.route_info.route_ref.ref.get_ref() as HenVirtualCNode).get_save(_refs.script_data), _refs)
	else:
		ref = _vc.route_info.route_ref.ref

	var data: HenSaveCodeType.CNode = HenFactoryCNode.get_cnode_from_dict(_vc.get_save(_refs.script_data), _refs, ref)
	var token: Dictionary

	match data.sub_type:
		HenVirtualCNode.SubType.IF:
			token = data.get_if_token([])
		HenVirtualCNode.SubType.FOR, HenVirtualCNode.SubType.FOR_ARR:
			token = data.get_for_token([])
		HenVirtualCNode.SubType.MACRO:
			token = data.get_macro_token(0, data)
		_:
			token = data.get_token()

	return CNodeDataCode.new(data, HenGeneratorByToken.get_code_by_token(token))


static func get_virtual_cnode_with_connections(_base_vc: HenVirtualCNode, _refs: HenSaveCodeType.References, _input_connections: Array[CNodeConnection] = [], _connections: Array[CNodeConnection] = []) -> String:
	# input connections
	for connection in _input_connections:
		connection.from.get_new_input_connection_command(connection.from_id, connection.to_id, connection.to).add()

	# add connections
	for connection in _connections:
		connection.from.add_flow_connection(connection.from_id, connection.to_id, connection.to).add()

	# generate connections from dict
	for connection in _connections + _input_connections:
		get_virtual_cnode_code(connection.to, _refs)

	var data: CNodeDataCode = get_virtual_cnode_code(_base_vc, _refs)
	var code: String = ''

	HenFactoryCNode.parse_connections(_refs)

	for conn in _base_vc.io.connections:
		prints(conn.from_id, conn.to_id)

	for token in data.data.get_flow_tokens(0):
		code += HenGeneratorByToken.get_code_by_token(token)

	return code


static func get_void(_route: HenRouteData = null) -> HenVirtualCNode:
	return HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_void',
		sub_type = HenVirtualCNode.SubType.VOID,
		inputs = [],
		route = HenTest.get_base_route() if not _route else _route
	})


static func get_void_with_input() -> HenVirtualCNode:
	return HenVirtualCNode.instantiate_virtual_cnode({
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
	return HenVirtualCNode.instantiate_virtual_cnode({
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
