extends HenTestSuite


# helper to create the base FOR node (equivalent to _create_if_node).
# this removes duplication and cleans up the tests.
func _create_for_range_node() -> HenVirtualCNode:
	return HenVirtualCNode.instantiate_virtual_cnode({
		name = 'For -> Range',
		type = HenVirtualCNode.Type.FOR,
		sub_type = HenVirtualCNode.SubType.FOR,
		input_code_value_map = {
			2: {type = 'int', value = 1, code_value = '1'}
		},
		inputs = [
			{id = 0, name = 'start', type = 'int'},
			{id = 1, name = 'end', type = 'int'},
			{id = 2, name = 'step', type = 'int'}
		],
		outputs = [
			{id = 0, name = 'index', type = 'int'}
		],
		route = HenTest.get_base_route()
	})


# tests the default code generation for an unconnected FOR node.
func test_for_range_default_code() -> void:
	var for_vc: HenVirtualCNode = _create_for_range_node()
	var var_name: String = 'index_' + str(for_vc.id)
	var expected_code = 'for ' + var_name + ' in range(0, 0, 1):\n\tpass'
	assert_str(HenTest.get_vc_code(for_vc)).is_equal(expected_code)


# # tests a FOR node with the body flow connected.
func test_for_range_with_body_flow() -> void:
	var for_vc: HenVirtualCNode = _create_for_range_node()
	var vc_flow_body: HenVirtualCNode = HenTest.get_void()

	for_vc.add_flow_connection(StringName('0'), StringName('0'), vc_flow_body).add()

	var var_name: String = 'index_' + str(for_vc.id)
	var expected_code = 'for ' + var_name + ' in range(0, 0, 1):\n\ttest_void()'
	assert_str(HenTest.get_vc_code(for_vc)).is_equal(expected_code)


# # tests connecting the 'index' data output of the FOR to another node's input.
func test_for_range_with_index_output_connected() -> void:
	var for_vc: HenVirtualCNode = _create_for_range_node()
	var vc_with_input: HenVirtualCNode = HenTest.get_void_with_input()

	# Connect the execution flow (loop body -> function)
	for_vc.add_flow_connection(StringName('0'), StringName('0'), vc_with_input).add()
	# Connect the data flow ('index' output from the loop -> function input)
	vc_with_input.get_new_input_connection_command(StringName('0'), StringName('0'), for_vc).add()

	var var_name: String = 'index_' + str(for_vc.id)
	var expected_code = 'for ' + var_name + ' in range(0, 0, 1):\n\ttest_void(' + var_name + ')'

	assert_str(HenTest.get_vc_code(for_vc)).is_equal(expected_code)


# # tests a FOR node with both the body and "after" flows connected.
func test_for_range_with_after_flow() -> void:
	var for_vc: HenVirtualCNode = _create_for_range_node()
	var vc_flow_body: HenVirtualCNode = HenTest.get_void()
	var vc_flow_after: HenVirtualCNode = HenTest.get_void()

	# Body connection
	for_vc.add_flow_connection(StringName('0'), StringName('0'), vc_flow_body).add()
	# "After" connection
	for_vc.add_flow_connection(StringName('1'), StringName('0'), vc_flow_after).add()

	var var_name: String = 'index_' + str(for_vc.id)
	var expected_code = 'for ' + var_name + ' in range(0, 0, 1):\n\ttest_void()\ntest_void()'
	assert_str(HenTest.get_vc_code(for_vc)).is_equal(expected_code)