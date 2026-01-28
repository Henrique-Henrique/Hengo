extends HenTestSuite


var func_data: HenSaveFunc


func before_test() -> void:
	super ()
	func_data = save_data.add_func(false)
	func_data.name = 'my func'


func test_func_from_without_io() -> void:
	var func_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(
		func_data.get_cnode_data(save_data.identity.id, true)
	)

	assert_bool(
		not func_vc.get_inputs(save_data).is_empty() and (func_vc.get_inputs(save_data).get(0) as HenVCInOutData).is_ref
	).is_true()


func test_func_from_with_io() -> void:
	func_data.inputs.append(HenSaveParam.new())
	func_data.outputs.append(HenSaveParam.new())

	var func_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(
		func_data.get_cnode_data(save_data.identity.id, true)
	)

	assert_bool(func_vc.get_inputs(save_data).size() == 2).is_true()
	assert_bool(func_vc.get_outputs(save_data).size() == 1).is_true()


func test_func_from_without_ref_connections() -> void:
	func_data.inputs.append(HenSaveParam.new())
	func_data.outputs.append(HenSaveParam.new())

	var func_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(
		func_data.get_cnode_data(save_data.identity.id, true)
	)

	var code: String = HenTest.get_vc_code(func_vc)

	assert_str(code).is_equal('HengoState.INVALID_PLACEHOLDER')


func test_func_from_with_ref_connection() -> void:
	func_data.inputs.append(HenSaveParam.new())
	func_data.outputs.append(HenSaveParam.new())

	func_data.inputs.get(0).type = &'int'

	var func_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(
		func_data.get_cnode_data(save_data.identity.id, true)
	)

	var ref_func_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test func',
		outputs = [
			{
				id = 0,
				name = 'test',
				type = &'Variant'
			}
		],
		sub_type = HenVirtualCNode.SubType.FUNC,
		route = HenTest.get_base_route()
	})

	func_vc.get_new_input_connection_command(StringName('0'), StringName('0'), ref_func_vc).add()

	var code: String = HenTest.get_vc_code(func_vc)

	assert_str(code).is_equal('test_func().my_func(0)')