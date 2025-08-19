extends GutTest


func test_route() -> void:
	var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()
	var base_vc: HenVirtualCNode = HenTest.get_void()

	assert_eq(
		HenTest.construct_and_get_code(base_vc, [], refs),
		'test_void()',
	)

	var state_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'State 1',
		type = HenVirtualCNode.Type.STATE,
		sub_type = HenVirtualCNode.SubType.STATE,
		route = HenTest.get_base_route()
	})

	var vc_flow: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_void',
		sub_type = HenVirtualCNode.SubType.VOID,
		inputs = [],
		route = state_vc.route_info.route
	})

	prints(state_vc.route_info.route.type)

	assert_eq(
		HenTest.construct_and_get_code(vc_flow, [], refs),
		'_ref.test_void()',
	)