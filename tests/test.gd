class_name HenTest extends RefCounted


static func get_base_route() -> HenRouteData:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	return global.SAVE_DATA.get_route(global.SAVE_DATA.identity.id)


static func get_void(_name: String = 'test_void', _route: HenRouteData = null) -> HenVirtualCNode:
	return HenVirtualCNode.instantiate_virtual_cnode({
		name = _name,
		sub_type = HenVirtualCNode.SubType.VOID,
		route = HenTest.get_base_route() if not _route else _route
	})


static func get_void_with_input(_id: StringName = '') -> HenVirtualCNode:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	return HenVirtualCNode.instantiate_virtual_cnode({
		id = _id if _id else global.get_new_node_counter(),
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


static func get_const(_id: StringName = '') -> HenVirtualCNode:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	return HenVirtualCNode.instantiate_virtual_cnode({
		id = _id if _id else global.get_new_node_counter(),
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


static func get_vc_code(_vc: HenVirtualCNode, _flow_id: StringName = '') -> String:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var save_data: HenSaveData = global.SAVE_DATA

	# this is a hack to make the tests errors accurate only for code generation
	global.SAVE_DATA = null
	ProjectSettings.set_setting(HenSettings.DEBUG_COMPILATION_PATH, false)
	var code: String = HenVirtualCNodeCode.get_virtual_cnode_code(save_data, _vc, _flow_id)
	global.SAVE_DATA = save_data
	return code


static func get_all_code() -> String:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var code_generation: HenCodeGeneration = Engine.get_singleton(&'CodeGeneration')
	var save_data: HenSaveData = global.SAVE_DATA

	# this is a hack to make the tests errors accurate only for code generation
	global.SAVE_DATA = null
	ProjectSettings.set_setting(HenSettings.DEBUG_COMPILATION_PATH, false)
	var code: String = code_generation.get_code(save_data)
	global.SAVE_DATA = save_data
	return code


static func get_if_vc() -> HenVirtualCNode:
	return HenVirtualCNode.instantiate_virtual_cnode({
		name = 'IF',
		type = HenVirtualCNode.Type.IF,
		sub_type = HenVirtualCNode.SubType.IF,
		inputs = [ {id = 0, name = 'condition', type = 'bool'}],
		route = HenTest.get_base_route()
	})