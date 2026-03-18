extends HenTestSuite


# Asserts a direct function call for nodes on the base route
func test_code_generation_with_base_route() -> void:
	var base_vc: HenVirtualCNode = HenTest.get_void()

	assert_str(HenTest.get_vc_code(base_vc)).is_equal('test_void()')


# Asserts a referenced call for nodes on a different route
func test_code_generation_with_state_route() -> void:
	var state: HenSaveState = HenSaveState.create()

	var vc_flow: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_void',
		sub_type = HenVirtualCNode.SubType.VOID,
		route = state.get_route(save_data)
	})

	assert_str(HenTest.get_vc_code(vc_flow)).is_equal('_ref.test_void()')


# Asserts that default values (unconnected inputs) use _ref inside a state
func test_code_generation_default_value_ref_with_state_route() -> void:
	var state: HenSaveState = HenSaveState.create()

	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'set_prop',
		sub_type = HenVirtualCNode.SubType.SET_PROP,
		inputs = [
			{id = 0, name = 'ref', type = 'Node', is_ref = true},
			{id = 1, name = 'value', type = 'int'}
		],
		route = state.get_route(save_data)
	})

	assert_str(HenTest.get_vc_code(vc)).is_equal('_ref.value = 0')


# Asserts that default values (unconnected inputs) use self outside a state
func test_code_generation_default_value_self_with_base_route() -> void:
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'set_prop',
		sub_type = HenVirtualCNode.SubType.SET_PROP,
		inputs = [
			{id = 0, name = 'ref', type = 'Node', is_ref = true},
			{id = 1, name = 'value', type = 'int'}
		],
		route = save_data.get_base_route()
	})

	assert_str(HenTest.get_vc_code(vc)).is_equal('self.value = 0')