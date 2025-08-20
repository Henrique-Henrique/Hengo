extends GdUnitTestSuite


# Asserts a direct function call for nodes on the base route
func test_code_generation_with_base_route() -> void:
	var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()
	var base_vc: HenVirtualCNode = HenTest.get_void()

	assert_str(HenTest.construct_and_get_code(base_vc, [], refs)).is_equal('test_void()')


# Asserts a referenced call for nodes on a different route
func test_code_generation_with_state_route() -> void:
	var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()
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

	assert_str(HenTest.construct_and_get_code(vc_flow, [], refs)).is_equal('_ref.test_void()')