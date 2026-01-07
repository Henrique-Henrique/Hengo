extends HenTestSuite


func test_vcnode_instantiation() -> void:
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'print',
		sub_type = HenVirtualCNode.SubType.VOID,
		category = 'native',
		inputs = [
			{
				id = 0,
				name = 'content',
				type = 'Variant'
			}
		],
		route = HenTest.get_base_route()
	})

	assert_bool(vc is HenVirtualCNode).is_true()
	assert_int((vc.inputs as Array[HenVCInOutData]).size()).is_equal(1)
	assert_int((vc.outputs as Array[HenVCInOutData]).size()).is_equal(0)


func test_vcnode_io() -> void:
	var vc = HenVirtualCNode.instantiate_virtual_cnode({
			name = 'print',
			sub_type = HenVirtualCNode.SubType.VOID,
			category = 'native',
			inputs = [
				{
					id = 0,
					name = 'content',
					type = 'Variant'
				}
			],
			route = HenTest.get_base_route()
		})

	var vc2 = HenTest.get_const()
	var connection_return = vc.get_new_input_connection_command(0, 0, vc2)

	connection_return.add()

	assert_int((save_data.get_connection_from_vc(vc) as Array[HenVCConnectionData]).size()).is_equal(1)
	assert_int((save_data.get_connection_from_vc(vc2) as Array[HenVCConnectionData]).size()).is_equal(1)

	assert_int((save_data.get_connection_from_vc(vc)[0] as HenVCConnectionData).get_from(save_data).id).is_equal(vc2.id)
	assert_int((save_data.get_connection_from_vc(vc)[0] as HenVCConnectionData).get_to(save_data).id).is_equal(vc.id)

	connection_return.remove()

	assert_bool((save_data.get_connection_from_vc(vc) as Array[HenVCConnectionData]).is_empty()).is_true()
	assert_bool((save_data.get_connection_from_vc(vc2) as Array[HenVCConnectionData]).is_empty()).is_true()


func test_vcnode_flow() -> void:
	var vc = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'print',
		sub_type = HenVirtualCNode.SubType.VOID,
		category = 'native',
		inputs = [
			{
				id = 0,
				name = 'content',
				type = 'Variant'
			}
		],
		route = HenTest.get_base_route()
	})

	var vc2: HenVirtualCNode = HenTest.get_void()
	var flow_connection_return = vc.add_flow_connection(0, 0, vc2)


	flow_connection_return.add()

	assert_bool((save_data.get_flow_connection_from_vc(vc) as Array[HenVCFlowConnectionData]).size() == 1).is_true()
	assert_bool((save_data.get_flow_connection_from_vc(vc)[0] as HenVCFlowConnectionData).get_from(save_data).id == vc.id).is_true()
	flow_connection_return.remove()
	assert_bool((save_data.get_flow_connection_from_vc(vc) as Array[HenVCFlowConnectionData]).is_empty()).is_true()


func test_vcnode_add_delete() -> void:
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'print',
		sub_type = HenVirtualCNode.SubType.VOID,
		category = 'native',
		inputs = [
			{
				id = 0,
				name = 'content',
				type = 'Variant'
			}
		],
		route = HenTest.get_base_route()
	})

	var vc2: HenVirtualCNode = HenTest.get_const()
	var vc3: HenVirtualCNode = HenTest.get_void()

	vc.get_new_input_connection_command(0, 0, vc2).add()
	vc.add_flow_connection(0, 0, vc3).add()

	var global: HenGlobal = Engine.get_singleton(&'Global')
	var vc_return = vc.get_history_obj()

	assert_bool(vc.is_deleted == false).is_true()
	assert_bool(global.SAVE_DATA.get_connection_from_vc(vc).size() == 1).is_true()
	assert_bool(global.SAVE_DATA.get_flow_connection_from_vc(vc).size() == 1).is_true()

	vc_return.remove()

	assert_bool(vc.is_deleted == true).is_true()
	assert_bool(global.SAVE_DATA.get_connection_from_vc(vc).is_empty()).is_true()
	assert_bool(global.SAVE_DATA.get_flow_connection_from_vc(vc).is_empty()).is_true()

	vc_return.add()

	assert_bool(vc.is_deleted == false).is_true()
	assert_bool(global.SAVE_DATA.get_connection_from_vc(vc).size() == 1).is_true()
	assert_bool(global.SAVE_DATA.get_flow_connection_from_vc(vc).size() == 1).is_true()
