extends GdUnitTestSuite


# tests the default code generation for an unconnected IF node
func test_if_default_code() -> void:
	var vc: HenVirtualCNode = HenTest.get_if_vc()
	
	var expected_code = 'if false:\n\tpass\n'
	assert_str(HenTest.get_vc_code(vc)).is_equal(expected_code)


# tests an IF node with its condition input connected
func test_if_with_input_connection() -> void:
	var vc: HenVirtualCNode = HenTest.get_if_vc()
	var value: HenVirtualCNode = HenTest.get_const()
	
	vc.get_new_input_connection_command(0, 0, value).add()
	
	var expected_code = 'if Test.CONST:\n\tpass\n'
	assert_str(HenTest.get_vc_code(vc)).is_equal(expected_code)


# tests an IF node with the "true" flow connected
func test_if_with_true_flow() -> void:
	var vc: HenVirtualCNode = HenTest.get_if_vc()
	var value: HenVirtualCNode = HenTest.get_const()
	var vc_flow_1: HenVirtualCNode = HenTest.get_void()

	vc.get_new_input_connection_command(0, 0, value).add()
	vc.add_flow_connection(0, 0, vc_flow_1).add()
	
	var expected_code = 'if Test.CONST:\n\ttest_void()'
	assert_str(HenTest.get_vc_code(vc)).is_equal(expected_code)


# tests an IF node with both "true" and "false" flows connected
func test_if_with_false_flow() -> void:
	var vc: HenVirtualCNode = HenTest.get_if_vc()
	var vc_flow_0: HenVirtualCNode = HenTest.get_const()
	var vc_flow_1: HenVirtualCNode = HenTest.get_void()
	var vc_flow_2: HenVirtualCNode = HenTest.get_void()

	vc.get_new_input_connection_command(0, 0, vc_flow_0).add()
	vc.add_flow_connection(0, 0, vc_flow_1).add()
	vc.add_flow_connection(1, 0, vc_flow_2).add()
	
	var expected_code = 'if Test.CONST:\n\ttest_void()\nelse:\n\ttest_void()'
	assert_str(HenTest.get_vc_code(vc)).is_equal(expected_code)


# tests an IF node with "true", "false", and "after" flows connected
func test_if_with_all_flows() -> void:
	var vc: HenVirtualCNode = HenTest.get_if_vc()
	var vc_flow_0: HenVirtualCNode = HenTest.get_const()
	var vc_flow_1: HenVirtualCNode = HenTest.get_void()
	var vc_flow_2: HenVirtualCNode = HenTest.get_void()

	vc.get_new_input_connection_command(0, 0, vc_flow_0).add()
	vc.add_flow_connection(0, 0, vc_flow_1).add()
	vc.add_flow_connection(1, 0, vc_flow_2).add()
	vc.add_flow_connection(2, 0, vc_flow_2).add()

	var expected_code = 'if Test.CONST:\n\ttest_void()\nelse:\n\ttest_void()\ntest_void()'
	assert_str(HenTest.get_vc_code(vc)).is_equal(expected_code)


# tests that an IF with only the "false" flow inverts the condition
func test_if_with_false_flow_only() -> void:
	var vc: HenVirtualCNode = HenTest.get_if_vc()
	var vc_flow_0: HenVirtualCNode = HenTest.get_const()
	var vc_flow_2: HenVirtualCNode = HenTest.get_void()

	vc.get_new_input_connection_command(0, 0, vc_flow_0).add()
	vc.add_flow_connection(1, 0, vc_flow_2).add()

	var expected_code = 'if not(Test.CONST):\n\ttest_void()'
	assert_str(HenTest.get_vc_code(vc)).is_equal(expected_code)