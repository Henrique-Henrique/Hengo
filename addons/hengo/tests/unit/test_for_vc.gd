extends GutTest


func test_for_range_code() -> void:
	var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()
	var for_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		id = 3,
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

	var vc_flow_void: HenVirtualCNode = HenTest.get_void_with_input()

	# test id connection
	assert_eq(
		HenTest.get_virtual_cnode_with_connections(for_vc, refs, [
			HenTest.CNodeConnection.new(vc_flow_void, for_vc),
		], [
			HenTest.CNodeConnection.new(for_vc, vc_flow_void),
		]),
		'for index_3 in range(0, 0, 1):\n\ttest_void(index_3)'
	)

	for_vc.get_flow_connection(0).remove()

	# test base
	assert_eq(
		HenTest.get_virtual_cnode_code(for_vc, refs).code,
		'for index_3 in range(0, 0, 1):\n\tpass'
	)

	var vc_flow_1: HenVirtualCNode = HenTest.get_void()

	# test body flow
	assert_eq(
		HenTest.get_virtual_cnode_with_connections(for_vc, refs, [], [
			HenTest.CNodeConnection.new(for_vc, vc_flow_1),
		]),
		'for index_3 in range(0, 0, 1):\n\ttest_void()'
	)

	var vc_flow_2: HenVirtualCNode = HenTest.get_void()

	# test then flow
	assert_eq(
		HenTest.get_virtual_cnode_with_connections(for_vc, refs, [], [
			HenTest.CNodeConnection.new(for_vc, vc_flow_1),
			HenTest.CNodeConnection.new(for_vc, vc_flow_2, 1),
		]),
		'for index_3 in range(0, 0, 1):\n\ttest_void()\ntest_void()'
	)
