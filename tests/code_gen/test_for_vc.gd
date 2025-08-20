extends GdUnitTestSuite


func test_for_range_code() -> void:
	var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()
	var for_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		id = 2,
		name = 'For -> Range',
		type = HenVirtualCNode.Type.FOR,
		sub_type = HenVirtualCNode.SubType.FOR,
		inputs = [
			{
				name = 'start',
				type = 'int'
			},
			{
				name = 'end',
				type = 'int',
			},
			{
				name = 'step',
				type = 'int',
				value = 1,
				code_value = '1'
			}
		],
		outputs = [
			{
				id = 0,
				name = 'index',
				type = 'int'
			}
		],
		route = HenTest.get_base_route()
	})

	var vc_flow_void: HenVirtualCNode = HenTest.get_void_with_input(3)

	vc_flow_void.get_new_input_connection_command(0, 0, for_vc).add()

	# test base
	assert_str(HenTest.construct_and_get_code(for_vc, [], refs)).is_equal('for index_2 in range(0, 0, 1):\n\tpass')

	for_vc.add_flow_connection(0, 0, vc_flow_void).add()

	# test id connection
	assert_str(HenTest.construct_and_get_code(for_vc, [vc_flow_void], refs)).is_equal('for index_2 in range(0, 0, 1):\n\ttest_void(index_2)')

	for_vc.get_flow_output_connection(0).remove()

	var vc_flow_1: HenVirtualCNode = HenTest.get_void()

	for_vc.add_flow_connection(0, 0, vc_flow_1).add()

	# test body flow
	assert_str(HenTest.construct_and_get_code(for_vc, [vc_flow_1], refs)).is_equal('for index_2 in range(0, 0, 1):\n\ttest_void()')

	var vc_flow_2: HenVirtualCNode = HenTest.get_void()

	for_vc.add_flow_connection(1, 0, vc_flow_2).add()

	# test then flow
	assert_str(HenTest.construct_and_get_code(for_vc, [vc_flow_1, vc_flow_2], refs)).is_equal('for index_2 in range(0, 0, 1):\n\ttest_void()\ntest_void()')
