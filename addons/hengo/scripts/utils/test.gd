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


static func get_base_route() -> Dictionary:
	return {
		name = 'Base',
		type = HenRouter.ROUTE_TYPE.BASE,
		id = '0',
		ref = HenLoader.BaseRouteRef.new()
	}


static func get_virtual_cnode_code(_vc: HenVirtualCNode, _refs: HenSaveCodeType.References) -> CNodeDataCode:
	var data: HenSaveCodeType.CNode = HenCodeGeneration._get_cnode_from_dict(_vc.get_save(), _refs)
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

	return CNodeDataCode.new(data, HenCodeGeneration.parse_token_by_type(token))


static func get_virtual_cnode_with_connections(_base_vc: HenVirtualCNode, _refs: HenSaveCodeType.References, _input_connections: Array[CNodeConnection] = [], _connections: Array[CNodeConnection] = []) -> String:
	# input connections
	for connection in _input_connections:
		connection.from.create_connection(connection.from_id, connection.to_id, connection.to).add()

	# add connections
	for connection in _connections:
		connection.from.add_flow_connection(connection.from_id, connection.to_id, connection.to).add()
	
	# generate connections from dict
	for connection in _connections + _input_connections:
		get_virtual_cnode_code(connection.to, _refs)

	var data: CNodeDataCode = get_virtual_cnode_code(_base_vc, _refs)
	var code: String = ''

	HenCodeGeneration._parse_connections(_refs)

	for token in data.data.get_flow_tokens(0):
		code += HenCodeGeneration.parse_token_by_type(token)

	return code


static func get_void() -> HenVirtualCNode:
	return HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_void',
		sub_type = HenVirtualCNode.SubType.VOID,
		category = 'native',
		inputs = [],
		route = HenTest.get_base_route()
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


static func get_const() -> HenVirtualCNode:
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
