extends HenTestSuite

var state: HenSaveState


func before_test() -> void:
	super ()
	state = save_data.add_state(false)


func test_get_prop_inside_state() -> void:
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Get -> value',
		sub_type = HenVirtualCNode.SubType.GET_PROP,
		inputs = [
			{id = 0, name = 'Node', type = 'Node', is_ref = true},
		],
		outputs = [
			{id = 0, name = 'value', type = 'int'}
		],
		route = state.get_route(save_data)
	})

	assert_str(HenTest.get_vc_code(vc)).is_equal('_ref.value')


func test_set_prop_inside_state() -> void:
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Set -> value',
		sub_type = HenVirtualCNode.SubType.SET_PROP,
		inputs = [
			{id = 0, name = 'Node', type = 'Node', is_ref = true},
			{id = 1, name = 'value', type = 'int'}
		],
		route = state.get_route(save_data)
	})

	assert_str(HenTest.get_vc_code(vc)).is_equal('_ref.value = 0')


func test_get_prop_outside_state() -> void:
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Get -> value',
		sub_type = HenVirtualCNode.SubType.GET_PROP,
		inputs = [
			{id = 0, name = 'Node', type = 'Node', is_ref = true},
		],
		outputs = [
			{id = 0, name = 'value', type = 'int'}
		],
		route = save_data.get_base_route()
	})

	assert_str(HenTest.get_vc_code(vc)).is_equal('self.value')


func test_set_prop_outside_state() -> void:
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Set -> value',
		sub_type = HenVirtualCNode.SubType.SET_PROP,
		inputs = [
			{id = 0, name = 'Node', type = 'Node', is_ref = true},
			{id = 1, name = 'value', type = 'int'}
		],
		route = save_data.get_base_route()
	})

	assert_str(HenTest.get_vc_code(vc)).is_equal('self.value = 0')


func test_get_nested_prop_inside_state() -> void:
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Get -> position.x',
		sub_type = HenVirtualCNode.SubType.GET_PROP,
		inputs = [
			{id = 0, name = 'Node', type = 'Node', is_ref = true},
		],
		outputs = [
			{id = 0, name = 'position.x', type = 'float'}
		],
		route = state.get_route(save_data)
	})

	assert_str(HenTest.get_vc_code(vc)).is_equal('_ref.position.x')


func test_set_nested_prop_inside_state() -> void:
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Set -> position.x',
		sub_type = HenVirtualCNode.SubType.SET_PROP,
		inputs = [
			{id = 0, name = 'Node', type = 'Node', is_ref = true},
			{id = 1, name = 'position.x', type = 'float'}
		],
		route = state.get_route(save_data)
	})

	assert_str(HenTest.get_vc_code(vc)).is_equal('_ref.position.x = 0.')


func test_get_nested_prop_outside_state() -> void:
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Get -> position.x',
		sub_type = HenVirtualCNode.SubType.GET_PROP,
		inputs = [
			{id = 0, name = 'Node', type = 'Node', is_ref = true},
		],
		outputs = [
			{id = 0, name = 'position.x', type = 'float'}
		],
		route = save_data.get_base_route()
	})

	assert_str(HenTest.get_vc_code(vc)).is_equal('self.position.x')


func test_set_nested_prop_outside_state() -> void:
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Set -> position.x',
		sub_type = HenVirtualCNode.SubType.SET_PROP,
		inputs = [
			{id = 0, name = 'Node', type = 'Node', is_ref = true},
			{id = 1, name = 'position.x', type = 'float'}
		],
		route = save_data.get_base_route()
	})

	assert_str(HenTest.get_vc_code(vc)).is_equal('self.position.x = 0.')
