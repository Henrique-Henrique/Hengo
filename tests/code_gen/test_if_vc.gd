extends GdUnitTestSuite


# Helper function to create the base IF node
func _create_if_node() -> HenVirtualCNode:
	return HenVirtualCNode.instantiate_virtual_cnode({
		name = 'IF',
		type = HenVirtualCNode.Type.IF,
		sub_type = HenVirtualCNode.SubType.IF,
		inputs = [ {id = 0, name = 'condition', type = 'bool'}],
		route = HenTest.get_base_route()
	})


# Tests the default code generation for an unconnected IF node
func test_if_default_code() -> void:
	var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()
	
	var vc: HenVirtualCNode = _create_if_node()
	HenFactoryCNode.get_cnode_from_dict(vc.get_save(refs.script_data), refs)
	
	var expected_code = 'if false:\n\tpass\n'
	assert_str(HenTest.construct_and_get_code(vc, [], refs)).is_equal(expected_code)


# Tests an IF node with its condition input connected
func test_if_with_input_connection() -> void:
	var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()

	var vc: HenVirtualCNode = _create_if_node()
	HenFactoryCNode.get_cnode_from_dict(vc.get_save(refs.script_data), refs)

	var value: HenVirtualCNode = HenTest.get_const()
	HenFactoryCNode.get_cnode_from_dict(value.get_save(refs.script_data), refs)
	
	vc.get_new_input_connection_command(0, 0, value).add()
	
	var expected_code = 'if Test.CONST:\n\tpass\n'
	assert_str(HenTest.construct_and_get_code(vc, [value], refs)).is_equal(expected_code)


# Tests an IF node with the "true" flow connected
func test_if_with_true_flow() -> void:
	var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()
	
	var vc: HenVirtualCNode = _create_if_node()
	HenFactoryCNode.get_cnode_from_dict(vc.get_save(refs.script_data), refs)
	
	var value: HenVirtualCNode = HenTest.get_const()
	HenFactoryCNode.get_cnode_from_dict(value.get_save(refs.script_data), refs)

	var vc_flow_1: HenVirtualCNode = HenTest.get_void()
	HenFactoryCNode.get_cnode_from_dict(vc_flow_1.get_save(refs.script_data), refs)

	vc.get_new_input_connection_command(0, 0, value).add()
	vc.add_flow_connection(0, 0, vc_flow_1).add()
	
	var expected_code = 'if Test.CONST:\n\ttest_void()'
	assert_str(HenTest.construct_and_get_code(vc, [vc_flow_1], refs)).is_equal(expected_code)


# Tests an IF node with both "true" and "false" flows connected
func test_if_with_false_flow() -> void:
	var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()

	var vc: HenVirtualCNode = _create_if_node()
	HenFactoryCNode.get_cnode_from_dict(vc.get_save(refs.script_data), refs)
	
	var vc_flow_0: HenVirtualCNode = HenTest.get_const()
	HenFactoryCNode.get_cnode_from_dict(vc_flow_0.get_save(refs.script_data), refs)

	var vc_flow_1: HenVirtualCNode = HenTest.get_void()
	HenFactoryCNode.get_cnode_from_dict(vc_flow_1.get_save(refs.script_data), refs)

	var vc_flow_2: HenVirtualCNode = HenTest.get_void()
	HenFactoryCNode.get_cnode_from_dict(vc_flow_2.get_save(refs.script_data), refs)

	vc.get_new_input_connection_command(0, 0, vc_flow_0).add()
	vc.add_flow_connection(0, 0, vc_flow_1).add()
	vc.add_flow_connection(1, 0, vc_flow_2).add()
	
	var expected_code = 'if Test.CONST:\n\ttest_void()\nelse:\n\ttest_void()'
	assert_str(HenTest.construct_and_get_code(vc, [vc_flow_2], refs)).is_equal(expected_code)


# Tests an IF node with "true", "false", and "after" flows connected
func test_if_with_all_flows() -> void:
	var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()

	var vc: HenVirtualCNode = _create_if_node()
	HenFactoryCNode.get_cnode_from_dict(vc.get_save(refs.script_data), refs)

	var vc_flow_0: HenVirtualCNode = HenTest.get_const()
	HenFactoryCNode.get_cnode_from_dict(vc_flow_0.get_save(refs.script_data), refs)
	
	var vc_flow_1: HenVirtualCNode = HenTest.get_void()
	HenFactoryCNode.get_cnode_from_dict(vc_flow_1.get_save(refs.script_data), refs)

	var vc_flow_2: HenVirtualCNode = HenTest.get_void()
	HenFactoryCNode.get_cnode_from_dict(vc_flow_2.get_save(refs.script_data), refs)

	vc.get_new_input_connection_command(0, 0, vc_flow_0).add()
	vc.add_flow_connection(0, 0, vc_flow_1).add()
	vc.add_flow_connection(1, 0, vc_flow_2).add()
	vc.add_flow_connection(2, 0, vc_flow_2).add()

	var expected_code = 'if Test.CONST:\n\ttest_void()\nelse:\n\ttest_void()\ntest_void()'
	assert_str(HenTest.construct_and_get_code(vc, [vc_flow_2], refs)).is_equal(expected_code)


# Tests that an IF with only the "false" flow inverts the condition
func test_if_with_false_flow_only() -> void:
	var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()

	var vc: HenVirtualCNode = _create_if_node()
	HenFactoryCNode.get_cnode_from_dict(vc.get_save(refs.script_data), refs)

	var vc_flow_0: HenVirtualCNode = HenTest.get_const()
	HenFactoryCNode.get_cnode_from_dict(vc_flow_0.get_save(refs.script_data), refs)

	var vc_flow_2: HenVirtualCNode = HenTest.get_void()
	HenFactoryCNode.get_cnode_from_dict(vc_flow_2.get_save(refs.script_data), refs)

	vc.get_new_input_connection_command(0, 0, vc_flow_0).add()
	vc.add_flow_connection(1, 0, vc_flow_2).add()

	var expected_code = 'if not(Test.CONST):\n\ttest_void()'
	assert_str(HenTest.construct_and_get_code(vc, [vc_flow_2], refs)).is_equal(expected_code)