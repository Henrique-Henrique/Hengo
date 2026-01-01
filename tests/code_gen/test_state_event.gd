extends GdUnitTestSuite


func test_state_event_transition() -> void:
    HenTest.clear_save_data()
    var save_data: HenSaveData = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
    save_data.add_state_event(false)
    save_data.add_state()

    var state_event: HenSaveStateEvent = save_data.state_events.get(0)
    var state: HenSaveState = save_data.states.get(0)

    state_event.name = 'state event test'
    state.name = 'state test'
    
    var state_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(state.get_cnode_data(''))
    var state_event_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(state_event.get_cnode_data())

    state_event_vc.add_flow_connection(0, 0, state_vc).add()

    var code: String = HenTest.get_all_code()
    assert_str(code).contains('const _EVENTS =  {\n\tstate_event_test="state_test"\n}')
