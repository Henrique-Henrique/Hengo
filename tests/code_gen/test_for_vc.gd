extends GdUnitTestSuite


# Helper to create the base FOR node (equivalent to _create_if_node).
# This removes duplication and cleans up the tests.
func _create_for_range_node() -> HenVirtualCNode:
	return HenVirtualCNode.instantiate_virtual_cnode({
		id = 2,
		name = 'For -> Range',
		type = HenVirtualCNode.Type.FOR,
		sub_type = HenVirtualCNode.SubType.FOR,
		inputs = [
			{name = 'start', type = 'int'},
			{name = 'end', type = 'int'},
			{name = 'step', type = 'int', value = 1, code_value = '1'}
		],
		outputs = [
			{id = 0, name = 'index', type = 'int'}
		],
		route = HenTest.get_base_route()
	})


# Tests the default code generation for an unconnected FOR node.
func test_for_range_default_code() -> void:
	var refs: HenTypeReferences = HenTypeReferences.new()
	var for_vc: HenVirtualCNode = _create_for_range_node()
	
	var expected_code = 'for index_2 in range(0, 0, 1):\n\tpass'
	assert_str(HenTest.construct_and_get_code(for_vc, [], refs)).is_equal(expected_code)


# Tests a FOR node with the body flow connected.
func test_for_range_with_body_flow() -> void:
	var refs: HenTypeReferences = HenTypeReferences.new()
	var for_vc: HenVirtualCNode = _create_for_range_node()
	var vc_flow_body: HenVirtualCNode = HenTest.get_void()

	for_vc.add_flow_connection(0, 0, vc_flow_body).add()

	var expected_code = 'for index_2 in range(0, 0, 1):\n\ttest_void()'
	assert_str(HenTest.construct_and_get_code(for_vc, [vc_flow_body], refs)).is_equal(expected_code)


# Tests connecting the 'index' data output of the FOR to another node's input.
func test_for_range_with_index_output_connected() -> void:
	var refs: HenTypeReferences = HenTypeReferences.new()
	var for_vc: HenVirtualCNode = _create_for_range_node()
	var vc_with_input: HenVirtualCNode = HenTest.get_void_with_input(3)

	# Connect the execution flow (loop body -> function)
	for_vc.add_flow_connection(0, 0, vc_with_input).add()
	# Connect the data flow ('index' output from the loop -> function input)
	vc_with_input.get_new_input_connection_command(0, 0, for_vc).add()

	var expected_code = 'for index_2 in range(0, 0, 1):\n\ttest_void(index_2)'
	assert_str(HenTest.construct_and_get_code(for_vc, [vc_with_input], refs)).is_equal(expected_code)


# Tests a FOR node with both the body and "after" flows connected.
func test_for_range_with_after_flow() -> void:
	var refs: HenTypeReferences = HenTypeReferences.new()
	var for_vc: HenVirtualCNode = _create_for_range_node()
	var vc_flow_body: HenVirtualCNode = HenTest.get_void()
	var vc_flow_after: HenVirtualCNode = HenTest.get_void()

	# Body connection
	for_vc.add_flow_connection(0, 0, vc_flow_body).add()
	# "After" connection
	for_vc.add_flow_connection(1, 0, vc_flow_after).add()

	var expected_code = 'for index_2 in range(0, 0, 1):\n\ttest_void()\ntest_void()'
	assert_str(HenTest.construct_and_get_code(for_vc, [vc_flow_body, vc_flow_after], refs)).is_equal(expected_code)