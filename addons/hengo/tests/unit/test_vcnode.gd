extends GutTest


func test_vcnode_instantiation() -> void:
	var vc = HenVirtualCNode.instantiate_virtual_cnode({
			name='print',
			sub_type=HenVirtualCNode.SubType.VOID,
			category='native',
			inputs=[
				{
					id=0,
					name='content',
					type='Variant'
				}
			],
			route=HenTest.get_base_route()
		})
	
	assert_true(vc is HenVirtualCNode)
	assert_true((vc.io.inputs as Array[HenVCInOutData]).size() == 1, 'It has one input')
	assert_true((vc.io.outputs as Array[HenVCInOutData]).size() == 0, 'It has no outputs')


func test_vcnode_io() -> void:
	var vc = HenVirtualCNode.instantiate_virtual_cnode({
			name='print',
			sub_type=HenVirtualCNode.SubType.VOID,
			category='native',
			inputs=[
				{
					id=0,
					name='content',
					type='Variant'
				}
			],
			route=HenTest.get_base_route()
		})

	var vc2 = HenTest.get_const()
	var connection_return = vc.get_new_input_connection_command(0, 0, vc2)
	
	connection_return.add()

	assert_true((vc.io.connections as Array[HenVCConnectionData]).size() == 1, 'Vc has the connection')
	assert_true((vc2.io.connections as Array[HenVCConnectionData]).size() == 1, 'Vc2 has the connection')

	assert_true((vc.io.connections[0] as HenVCConnectionData).get_from().identity.id == vc2.identity.id, 'The connection is from vc2')
	assert_true((vc.io.connections[0] as HenVCConnectionData).get_to().identity.id == vc.identity.id, 'The connection is to vc')

	connection_return.remove()

	assert_true((vc.io.connections as Array[HenVCConnectionData]).is_empty(), 'Vc has no connections after removing the connection')
	assert_true((vc2.io.connections as Array[HenVCConnectionData]).is_empty(), 'Vc2 has no connections after removing the connection')


func test_vcnode_flow() -> void:
	var vc = HenVirtualCNode.instantiate_virtual_cnode({
		name='print',
		sub_type=HenVirtualCNode.SubType.VOID,
		category='native',
		inputs=[
			{
				id=0,
				name='content',
				type='Variant'
			}
		],
		route=HenTest.get_base_route()
	})

	var vc2: HenVirtualCNode = HenTest.get_void()
	var flow_connection_return = vc.add_flow_connection(0, 0, vc2)

	flow_connection_return.add()

	assert_true((vc.flow.flow_connections_2 as Array[HenVCFlowConnectionData]).size() == 1, 'Vc has the flow connection')
	assert_true((vc2.flow.flow_connections_2 as Array[HenVCFlowConnectionData]).size() == 1, 'Vc2 has the flow connection')

	assert_true((vc.flow.flow_connections_2[0] as HenVCFlowConnectionData).get_from().identity.id == vc.identity.id, 'The flow connection is from vc')
	assert_true((vc.flow.flow_connections_2[0] as HenVCFlowConnectionData).get_to().identity.id == vc2.identity.id, 'The flow connection is to vc2')

	flow_connection_return.remove()

	assert_true((vc.flow.flow_connections_2 as Array[HenVCFlowConnectionData]).is_empty(), 'Vc has no flow connections after removing the connection')
	assert_true((vc2.flow.flow_connections_2 as Array[HenVCFlowConnectionData]).is_empty(), 'Vc2 has no flow connections after removing the connection')


func test_vcnode_add_delete() -> void:
	var vc = HenVirtualCNode.instantiate_virtual_cnode({
		name='print',
		sub_type=HenVirtualCNode.SubType.VOID,
		category='native',
		inputs=[
			{
				id=0,
				name='content',
				type='Variant'
			}
		],
		route=HenTest.get_base_route()
	})

	var vc2 = HenTest.get_const()
	var vc3 = HenTest.get_void()

	vc.get_new_input_connection_command(0, 0, vc2).add()
	vc.add_flow_connection(0, 0, vc3).add()

	var vc_return = vc.get_history_obj()

	assert_true(vc.state.is_deleted == false, 'Vc is not deleted')
	assert_true((vc.io.connections as Array[HenVCConnectionData]).size() == 1, 'Vc has one connection')
	assert_true((vc.flow.flow_connections_2 as Array[HenVCFlowConnectionData]).size() == 1, 'Vc has one flow connection')

	vc_return.remove()

	assert_true(vc.state.is_deleted == true, 'Vc is deleted')
	assert_true((vc.io.connections as Array[HenVCConnectionData]).is_empty(), 'Vc has no connections after removing the connection')
	assert_true((vc.flow.flow_connections_2 as Array[HenVCFlowConnectionData]).is_empty(), 'Vc has no flow connections after removing the connection')

	# add again to test history
	vc_return.add()

	assert_true(vc.state.is_deleted == false, 'Vc is not deleted')
	assert_true((vc.io.connections as Array[HenVCConnectionData]).size() == 1, 'Vc has one connection')
	assert_true((vc.flow.flow_connections_2 as Array[HenVCFlowConnectionData]).size() == 1, 'Vc has one flow connection')
