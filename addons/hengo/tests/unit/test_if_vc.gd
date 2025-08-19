extends GutTest

func test_if_code() -> void:
	var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'IF',
		type = HenVirtualCNode.Type.IF,
		sub_type = HenVirtualCNode.SubType.IF,
		inputs = [
			{
				id = 0,
				name = 'condition',
				type = 'bool'
			},
		],
		route = HenTest.get_base_route()
	})

	# test IF default
	assert_eq(
		HenTest.construct_and_get_code(vc, [], refs),
		'if false:\n\tpass\n'
	)

	var value: HenVirtualCNode = HenTest.get_const()

	vc.get_new_input_connection_command(0, 0, value).add()

	# testing IF input connection
	assert_eq(
		HenTest.construct_and_get_code(vc, [value], refs),
		'if Test.CONST:\n\tpass\n'
	)

	var vc_flow_1: HenVirtualCNode = HenTest.get_void()

	vc.add_flow_connection(0, 0, vc_flow_1).add()

	# test true flow
	assert_eq(
		HenTest.construct_and_get_code(vc, [vc_flow_1], refs),
		'if Test.CONST:\n\ttest_void()'
	)

	var vc_flow_2: HenVirtualCNode = HenTest.get_void()

	vc.add_flow_connection(1, 0, vc_flow_2).add()

	# test false flow
	assert_eq(
		HenTest.construct_and_get_code(vc, [vc_flow_2], refs),
		'if Test.CONST:\n\ttest_void()\nelse:\n\ttest_void()'
	)

	vc.add_flow_connection(2, 0, vc_flow_2).add()

	# test true, false and then flows
	assert_eq(
		HenTest.construct_and_get_code(vc, [vc_flow_2], refs),
		'if Test.CONST:\n\ttest_void()\nelse:\n\ttest_void()\ntest_void()'
	)

	vc.get_flow_output_connection(0).remove()
	vc.get_flow_output_connection(2).remove()

	vc.add_flow_connection(1, 0, vc_flow_2).add()

	# test false flow without true flow
	assert_eq(
		HenTest.construct_and_get_code(vc, [vc_flow_2], refs),
		'if not(Test.CONST):\n\ttest_void()'
	)
