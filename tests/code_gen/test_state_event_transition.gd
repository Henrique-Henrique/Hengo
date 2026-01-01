extends GdUnitTestSuite


func test_state_event_transition() -> void:
    HenTest.clear_save_data()
    var save_data: HenSaveData = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
    save_data.add_state_event(false)

    var state_event: HenSaveStateEvent = save_data.state_events.get(0)

    state_event.name = 'state event test'
    
    var transition_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(state_event.get_event_transition_cnode_data(''))
    var code: String = HenTest.get_vc_code(transition_vc)

    assert_str(code).is_equal('trigger_event(&"state_event_test")')
