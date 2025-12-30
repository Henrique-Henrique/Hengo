extends GdUnitTestSuite


func get_var_data() -> HenSaveVar:
	var save_data: HenSaveData = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
	save_data.variables.clear()
	save_data.add_var(false)

	var var_data: HenSaveVar = save_data.variables.get(0)

	var_data.name = 'test var'
	var_data.type = &'int'

	return var_data


func test_var_getter_from_without_io() -> void:
	var save_data: HenSaveData = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
	var var_data: HenSaveVar = get_var_data()
	var var_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(
		var_data.get_getter_cnode_data(save_data.identity.id, true)
	)

	assert_bool(
		not var_vc.get_inputs(save_data).is_empty() and (var_vc.get_inputs(save_data).get(0) as HenVCInOutData).is_ref
	).is_true()


func test_var_setter_from_without_io() -> void:
	var save_data: HenSaveData = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
	var var_data: HenSaveVar = get_var_data()
	var var_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(
		var_data.get_setter_cnode_data(save_data.identity.id, true)
	)

	assert_bool(
		not var_vc.get_inputs(save_data).is_empty() and (var_vc.get_inputs(save_data).get(0) as HenVCInOutData).is_ref
	).is_true()


func test_var_getter_from_without_ref_connections() -> void:
	var save_data: HenSaveData = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
	var var_data: HenSaveVar = get_var_data()
	var var_get_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(var_data.get_getter_cnode_data(save_data.identity.id, true))
	var code: String = HenTest.get_vc_code(var_get_vc)

	assert_str(code).is_equal('HengoState.INVALID_PLACEHOLDER')


func test_var_setter_from_without_ref_connections() -> void:
	var save_data: HenSaveData = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
	var var_data: HenSaveVar = get_var_data()
	var var_set_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(var_data.get_setter_cnode_data(save_data.identity.id, true))
	var code: String = HenTest.get_vc_code(var_set_vc)

	assert_str(code).is_equal('HengoState.INVALID_PLACEHOLDER')


func test_var_getter_from_with_ref_connection() -> void:
	var save_data: HenSaveData = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
	var var_data: HenSaveVar = get_var_data()
	var var_get_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(var_data.get_getter_cnode_data(save_data.identity.id, true))
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

	var_get_vc.get_new_input_connection_command(0, 0, ref_func_vc).add()

	var code: String = HenTest.get_vc_code(var_get_vc)

	assert_str(code).is_equal('test_func().test_var')


func test_var_setter_from_with_ref_connection() -> void:
	var save_data: HenSaveData = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
	var var_data: HenSaveVar = get_var_data()

	var var_set_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(var_data.get_setter_cnode_data(save_data.identity.id, true))

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

	var_set_vc.get_new_input_connection_command(0, 0, ref_func_vc).add()

	var code: String = HenTest.get_vc_code(var_set_vc)

	assert_str(code).is_equal('test_func().test_var = 0')