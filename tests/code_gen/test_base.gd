extends HenTestSuite


# tests _draw override virtual code generation
func test_override_virtual_draw() -> void:
	var base_route: HenRouteData = save_data.get_base_route()

	var virtual_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = '_draw',
		route = base_route,
		sub_type = HenVirtualCNode.SubType.OVERRIDE_VIRTUAL
	})

	var virtual_flow_vc: HenVirtualCNode = HenTest.get_void('test_void')

	virtual_vc.add_flow_connection(0, 0, virtual_flow_vc).add()

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('func _draw() -> void:\n\ttest_void()')


# tests _enter_tree override virtual code generation
func test_override_virtual_enter_tree() -> void:
	var base_route: HenRouteData = save_data.get_base_route()

	var virtual_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = '_enter_tree',
		route = base_route,
		sub_type = HenVirtualCNode.SubType.OVERRIDE_VIRTUAL
	})

	var virtual_flow_vc: HenVirtualCNode = HenTest.get_void('my_enter_func')

	virtual_vc.add_flow_connection(0, 0, virtual_flow_vc).add()

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('func _enter_tree() -> void:\n\tmy_enter_func()')


# tests override virtual with params
func test_override_virtual_with_params() -> void:
	var base_route: HenRouteData = save_data.get_base_route()

	var virtual_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = '_input',
		route = base_route,
		sub_type = HenVirtualCNode.SubType.OVERRIDE_VIRTUAL,
		outputs = [
			{name = 'event', type = 'InputEvent'}
		]
	})

	var virtual_flow_vc: HenVirtualCNode = HenTest.get_void('handle_input')

	virtual_vc.add_flow_connection(0, 0, virtual_flow_vc).add()

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('func _input(event: InputEvent) -> void:\n\thandle_input()')
