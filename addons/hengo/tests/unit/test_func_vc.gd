extends GutTest


func test_func_code() -> void:
	var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()
	var func_vc_single_output: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test func',
		outputs = [
			{
				id = 0,
				name = 'input 1',
				type = 'Variant'
			}
		],
		sub_type = HenVirtualCNode.SubType.FUNC,
		type = 0,
		route = HenTest.get_base_route()
	})

	var func_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test func',
		outputs = [
			{
				id = 0,
				name = 'input 1',
				type = 'Variant'
			},
			{
				id = 1,
				name = 'input 2',
				type = 'Variant'
			},
		],
		sub_type = HenVirtualCNode.SubType.FUNC,
		type = 0,
		route = HenTest.get_base_route()
	})

	var void_vc: HenVirtualCNode = HenTest.get_void_with_input()

	# base func
	assert_eq(
		HenTest.get_virtual_cnode_code(func_vc_single_output, refs).code,
		'test_func()'
	)

	# input 1 value
	assert_eq(
		HenTest.get_virtual_cnode_with_connections(void_vc, refs, [
			HenTest.CNodeConnection.new(void_vc, func_vc)
		]),
		'test_void(test_func()[0])'
	)

	void_vc.remove_inout_connection(void_vc.inputs[0])

	# input 2 value
	assert_eq(
		HenTest.get_virtual_cnode_with_connections(void_vc, refs, [
			HenTest.CNodeConnection.new(void_vc, func_vc, 0, 1)
		]),
		'test_void(test_func()[1])'
	)
