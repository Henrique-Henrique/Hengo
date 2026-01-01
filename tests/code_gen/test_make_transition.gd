extends GdUnitTestSuite

func test_make_transition() -> void:
	HenTest.clear_save_data()
	var save_data: HenSaveData = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
	save_data.add_state()

	var state: HenSaveState = save_data.states.get(0)

	state.name = 'state test'

	var first_output: HenSaveParam = HenSaveParam.new()

	first_output.name = 'first output'
	state.flow_outputs.append(first_output)

	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'make_transition',
		sub_type = HenVirtualCNode.SubType.MAKE_TRANSITION,
		category = 'native',
		inputs = [
			{
				name = 'name',
				type = 'StringName',
				sub_type = '@dropdown',
				category = 'state_transition'
			}
		],
		route = state.get_route(save_data)
	})

	(vc.inputs.get(0) as HenVCInOutData).res_data = {
		id = state.id,
		type = HenSideBar.AddType.STATE,
		flow_id = first_output.id
	}

	var code: String = HenTest.get_vc_code(vc)
	assert_str(code).is_equal('make_transition(&"first_output")')