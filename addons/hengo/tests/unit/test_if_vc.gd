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
		HenTest.get_virtual_cnode_code(vc, refs).code,
		'if false:\n\tpass'
	)

	var value: HenVirtualCNode = HenTest.get_const()

	# testing IF input connection
	assert_eq(
		HenTest.get_virtual_cnode_with_connections(vc, refs, [
			HenTest.CNodeConnection.new(vc, value),
		]),
		'if Test.CONST:\n\tpass'
	)

	var vc_flow_1: HenVirtualCNode = HenTest.get_void()

	# test true flow
	assert_eq(
		HenTest.get_virtual_cnode_with_connections(vc, refs, [], [
			HenTest.CNodeConnection.new(vc, vc_flow_1),
		]),
		'if Test.CONST:\n\ttest_void()'
	)

	var vc_flow_2: HenVirtualCNode = HenTest.get_void()

	# test false flow
	assert_eq(
		HenTest.get_virtual_cnode_with_connections(vc, refs, [], [
			HenTest.CNodeConnection.new(vc, vc_flow_2, 1, 0),
		]),
		'if Test.CONST:\n\ttest_void()\nelse:\n\ttest_void()'
	)

	# test true, false and then flows
	assert_eq(
		HenTest.get_virtual_cnode_with_connections(vc, refs, [], [
			HenTest.CNodeConnection.new(vc, vc_flow_2, 2, 0),
		]),
		'if Test.CONST:\n\ttest_void()\nelse:\n\ttest_void()\ntest_void()'
	)

	vc.get_flow_connection(0).remove()
	vc.get_flow_connection(2).remove()

	# test false flow without true flow
	assert_eq(
		HenTest.get_virtual_cnode_with_connections(vc, refs, [], [
			HenTest.CNodeConnection.new(vc, vc_flow_2, 1, 0),
		]),
		'if not(Test.CONST):\n\ttest_void()'
	)
