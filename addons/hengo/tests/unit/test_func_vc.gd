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
		HenTest.construct_and_get_code(func_vc_single_output, [], refs),
		'test_func()'
	)

	void_vc.get_new_input_connection_command(0, 0, func_vc).add()

	# input 1 value
	assert_eq(
		HenTest.construct_and_get_code(void_vc, [func_vc], refs),
		'test_void(test_func()[0])'
	)

	void_vc.io.remove_io_connection(void_vc.io.inputs[0])
	void_vc.get_new_input_connection_command(0, 1, func_vc).add()

	# input 2 value
	assert_eq(
		HenTest.construct_and_get_code(void_vc, [func_vc], refs),
		'test_void(test_func()[1])'
	)
