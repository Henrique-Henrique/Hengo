extends GdUnitTestSuite


# Asserts a direct function call for nodes on the base route
func test_code_generation_with_base_route() -> void:
	var base_vc: HenVirtualCNode = HenTest.get_void()

	assert_str(HenVirtualCNodeCode.get_virtual_cnode_code(base_vc)).is_equal('test_void()')


# Asserts a referenced call for nodes on a different route
func test_code_generation_with_state_route() -> void:
	var state_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'State 1',
		type = HenVirtualCNode.Type.STATE,
		sub_type = HenVirtualCNode.SubType.STATE,
		route = HenTest.get_base_route()
	})

	var vc_flow: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_void',
		sub_type = HenVirtualCNode.SubType.VOID,
		route = state_vc.get_route()
	})

	assert_str(HenVirtualCNodeCode.get_virtual_cnode_code(vc_flow)).is_equal('_ref.test_void()')