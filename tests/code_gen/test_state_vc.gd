extends GdUnitTestSuite


func test_state_init_generation() -> void:
	pass
	HenTest.clear_save_data()
	var save_data: HenSaveData = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
	save_data.add_state()

	var state: HenSaveState = save_data.states.get(0)

	state.name = 'state test'

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('func _init() -> void:\n\t_STATE_CONTROLLER.set_states({\n\t\tstate_test=StateTest.new(self),\n\t})')


func test_state_start_state() -> void:
	var save_data: HenSaveData = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
	HenTest.clear_save_data()
	save_data.add_state()
	save_data.add_state()
	var state: HenSaveState = save_data.states.get(0)
	var state2: HenSaveState = save_data.states.get(1)

	var first_output: HenSaveParam = HenSaveParam.new()
	first_output.name = 'first output'
	state.flow_outputs.append(first_output)

	state.name = 'state test'
	state2.name = 'state test 2'

	var start_state: HenVirtualCNode = HenTest.get_base_route().virtual_cnode_list.get(0)
	var state_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(state.get_cnode_data(''))
	var state2_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(state2.get_cnode_data(''))

	start_state.add_flow_connection(0, 0, state_vc).add()
	state_vc.add_flow_connection(state_vc.get_flow_outputs(save_data).get(0).id, state2_vc.get_flow_inputs(save_data).get(0).id, state2_vc).add()

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('func _ready() -> void:\n\tif not _STATE_CONTROLLER.current_state:\n\t\t_STATE_CONTROLLER.change_state("state_test")')


func test_state_double_state() -> void:
	HenTest.clear_save_data()
	var save_data: HenSaveData = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
	save_data.add_state()
	save_data.add_state()
	var state: HenSaveState = save_data.states.get(0)
	var state2: HenSaveState = save_data.states.get(1)

	state.name = 'state test'
	state2.name = 'state test 2'

	var code: String = HenTest.get_all_code()
	assert_str(code).contains('func _init() -> void:\n\t_STATE_CONTROLLER.set_states({\n\t\tstate_test=StateTest.new(self),\n\t\tstate_test_2=StateTest2.new(self),\n\t})')


# checks if new line and tab is corret for more than one state
func test_state_double_state_implementation() -> void:
	HenTest.clear_save_data()
	var save_data: HenSaveData = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
	save_data.add_state()
	save_data.add_state()
	var state: HenSaveState = save_data.states.get(0)
	var state2: HenSaveState = save_data.states.get(1)

	state.name = 'state test'
	state2.name = 'state test 2'

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('class StateTest extends HengoState:\n\tpass\n\nclass StateTest2 extends HengoState:\n\tpass')


func test_state_implementation_without_body() -> void:
	var save_data: HenSaveData = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
	save_data.states.clear()
	save_data.add_state()
	var state: HenSaveState = save_data.states.get(0)

	state.name = 'state test'

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('class StateTest extends HengoState:\n\tpass')


func test_state_implementation_with_body_enter() -> void:
	var save_data: HenSaveData = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
	save_data.states.clear()
	save_data.add_state()
	var state: HenSaveState = save_data.states.get(0)

	state.name = 'state test'

	var state_route: HenRouteData = state.get_route(save_data)

	var enter_vc: HenVirtualCNode = state_route.virtual_cnode_list.get(0)
	var void_vc: HenVirtualCNode = HenTest.get_void('test void', state_route)

	enter_vc.add_flow_connection(0, 0, void_vc).add()

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('class StateTest extends HengoState:\n\tfunc enter() -> void:\n\t\t_ref.test_void()')


func test_state_implementation_with_body_update() -> void:
	var save_data: HenSaveData = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
	save_data.states.clear()
	save_data.add_state()
	var state: HenSaveState = save_data.states.get(0)

	state.name = 'state test'

	var state_route: HenRouteData = state.get_route(save_data)

	var update_vc: HenVirtualCNode = state_route.virtual_cnode_list.get(1)
	var void_vc: HenVirtualCNode = HenTest.get_void('test void', state_route)

	update_vc.add_flow_connection(0, 0, void_vc).add()

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('class StateTest extends HengoState:\n\tfunc update(delta) -> void:\n\t\tsuper(delta)\n\t\t_ref.test_void()')


func test_state_implementation_with_body_enter_and_update() -> void:
	var save_data: HenSaveData = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
	HenTest.clear_save_data()
	save_data.add_state()
	var state: HenSaveState = save_data.states.get(0)

	state.name = 'state test'

	var state_route: HenRouteData = state.get_route(save_data)

	var enter_vc: HenVirtualCNode = state_route.virtual_cnode_list.get(0)
	var void_enter_vc: HenVirtualCNode = HenTest.get_void('test void', state_route)

	enter_vc.add_flow_connection(0, 0, void_enter_vc).add()

	var update_vc: HenVirtualCNode = state_route.virtual_cnode_list.get(1)
	var void_update_vc: HenVirtualCNode = HenTest.get_void('test void', state_route)

	update_vc.add_flow_connection(0, 0, void_update_vc).add()

	var code: String = HenTest.get_all_code()
	assert_str(code).contains('class StateTest extends HengoState:\n\tfunc enter() -> void:\n\t\t_ref.test_void()\n\n\tfunc update(delta) -> void:\n\t\tsuper(delta)\n\t\t_ref.test_void()')


func test_state_with_transition_data() -> void:
	var save_data: HenSaveData = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
	save_data.states.clear()
	save_data.add_state()
	var state: HenSaveState = save_data.states.get(0)

	state.name = 'state test'

	var transition_data: HenSaveParam = HenSaveParam.create()
	transition_data.name = 'transition data'
	transition_data.type = &'int'
	state.transition_data.append(transition_data)

	var state_route: HenRouteData = state.get_route(save_data)
	var enter_vc: HenVirtualCNode = state_route.virtual_cnode_list.get(0)
	var void_vc: HenVirtualCNode = HenTest.get_void('test void', state_route)

	enter_vc.add_flow_connection(0, 0, void_vc).add()

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('class StateTest extends HengoState:\n\tfunc enter(transition_data) -> void:\n\t\t_ref.test_void()')


func test_state_transition_data() -> void:
	var save_data: HenSaveData = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
	save_data.states.clear()
	save_data.add_state()
	save_data.add_state()
	var state: HenSaveState = save_data.states.get(0)
	var state2: HenSaveState = save_data.states.get(1)

	state.name = 'state test'
	state2.name = 'state test 2'

	var state_route: HenRouteData = state.get_route(save_data)
	var enter_vc: HenVirtualCNode = state_route.virtual_cnode_list.get(0)

	var router: HenRouter = Engine.get_singleton(&'Router')
	router.current_route = state.get_route(save_data)

	var transition_state_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(state2.get_transition_cnode_data(''))

	enter_vc.add_flow_connection(0, 0, transition_state_vc).add()

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('class StateTest extends HengoState:\n\tfunc enter() -> void:\n\t\t_ref._STATE_CONTROLLER.change_state("state_test_2")')


func test_state_transition_sub_state() -> void:
	var save_data: HenSaveData = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
	save_data.states.clear()
	save_data.add_state()

	var state: HenSaveState = save_data.states.get(0)

	state.add_state()
	var state2: HenSaveState = state.sub_states.get(0)

	state.name = 'state test'
	state2.name = 'state test 2'

	var state_route: HenRouteData = state.get_route(save_data)
	var enter_vc: HenVirtualCNode = state_route.virtual_cnode_list.get(0)
	var void_vc: HenVirtualCNode = HenTest.get_void()

	enter_vc.add_flow_connection(0, 0, void_vc).add()

	var router: HenRouter = Engine.get_singleton(&'Router')
	router.current_route = state.get_route(save_data)

	var transition_state_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(state2.get_transition_cnode_data(''))

	enter_vc.add_flow_connection(0, 0, transition_state_vc).add()

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('func enter() -> void:\n\t\t_ref._STATE_CONTROLLER.current_state.change_sub_state("state_test_2")')