extends GdUnitTestSuite


func test_vcnode_instantiation() -> void:
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


	assert_bool(vc is HenVirtualCNode).is_true()
	assert_int((vc.io.inputs as Array[HenVCInOutData]).size()).is_equal(1)
	assert_int((vc.io.outputs as Array[HenVCInOutData]).size()).is_equal(0)


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

	assert_int((vc.io.connections as Array[HenVCConnectionData]).size()).is_equal(1)
	assert_int((vc2.io.connections as Array[HenVCConnectionData]).size()).is_equal(1)

	assert_int((vc.io.connections[0] as HenVCConnectionData).get_from().identity.id).is_equal(vc2.identity.id)
	assert_int((vc.io.connections[0] as HenVCConnectionData).get_to().identity.id).is_equal(vc.identity.id)

	connection_return.remove()

	assert_bool((vc.io.connections as Array[HenVCConnectionData]).is_empty()).is_true()
	assert_bool((vc2.io.connections as Array[HenVCConnectionData]).is_empty()).is_true()


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

	assert_bool((vc.flow.flow_connections_2 as Array[HenVCFlowConnectionData]).size() == 1).is_true()
	assert_bool((vc2.flow.flow_connections_2 as Array[HenVCFlowConnectionData]).size() == 1).is_true()

	assert_bool((vc.flow.flow_connections_2[0] as HenVCFlowConnectionData).get_from().identity.id == vc.identity.id).is_true()
	assert_bool((vc.flow.flow_connections_2[0] as HenVCFlowConnectionData).get_to().identity.id == vc2.identity.id).is_true()

	flow_connection_return.remove()

	assert_bool((vc.flow.flow_connections_2 as Array[HenVCFlowConnectionData]).is_empty()).is_true()
	assert_bool((vc2.flow.flow_connections_2 as Array[HenVCFlowConnectionData]).is_empty()).is_true()


func test_vcnode_add_delete() -> void:
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
	var vc3 = HenTest.get_void()

	vc.get_new_input_connection_command(0, 0, vc2).add()
	vc.add_flow_connection(0, 0, vc3).add()

	var vc_return = vc.get_history_obj()

	assert_bool(vc.state.is_deleted == false).is_true()
	assert_bool((vc.io.connections as Array[HenVCConnectionData]).size() == 1).is_true()
	assert_bool((vc.flow.flow_connections_2 as Array[HenVCFlowConnectionData]).size() == 1).is_true()

	vc_return.remove()

	assert_bool(vc.state.is_deleted == true).is_true()
	assert_bool((vc.io.connections as Array[HenVCConnectionData]).is_empty()).is_true()
	assert_bool((vc.flow.flow_connections_2 as Array[HenVCFlowConnectionData]).is_empty()).is_true()

	# add again to test history
	vc_return.add()

	assert_bool(vc.state.is_deleted == false).is_true()
	assert_bool((vc.io.connections as Array[HenVCConnectionData]).size() == 1).is_true()
	assert_bool((vc.flow.flow_connections_2 as Array[HenVCFlowConnectionData]).size() == 1).is_true()
