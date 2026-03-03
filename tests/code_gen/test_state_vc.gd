extends HenTestSuite


var state: HenSaveState


func before_test() -> void:
	super ()
	state = save_data.add_state(false)
	state.name = 'state test'


func test_state_init_generation() -> void:
	var code: String = HenTest.get_all_code()

	assert_str(code).contains('func _init() -> void:\n\t_STATE_CONTROLLER.set_states({\n\t\tstate_test=StateTest.new(self),\n\t})')


func test_state_start_state() -> void:
	var state2: HenSaveState = save_data.add_state(false)

	var first_output: HenSaveParam = HenSaveParam.new()
	first_output.name = 'first output'
	state.flow_outputs.append(first_output)

	state2.name = 'state test 2'
	state.start = true

	var state_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(state.get_cnode_data(''))
	var state2_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(state2.get_cnode_data(''))

	state_vc.add_flow_connection(state_vc.get_flow_outputs(save_data).get(0).id, state2_vc.get_flow_inputs(save_data).get(0).id, state2_vc).add()

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('func _ready() -> void:\n\tif not _STATE_CONTROLLER.current_state:\n\t\t_STATE_CONTROLLER.change_state("state_test")')


func test_state_double_state() -> void:
	var state2: HenSaveState = save_data.add_state(false)

	state2.name = 'state test 2'


	var code: String = HenTest.get_all_code()
	assert_str(code).contains('func _init() -> void:\n\t_STATE_CONTROLLER.set_states({\n\t\tstate_test=StateTest.new(self),\n\t\tstate_test_2=StateTest2.new(self),\n\t})')


# check if new line and tab is correct for more than one state


func test_state_double_state_implementation() -> void:
	var state2: HenSaveState = save_data.add_state(false)

	state2.name = 'state test 2'


	var code: String = HenTest.get_all_code()

	assert_str(code).contains('class StateTest extends HengoState:\n\tpass\n\nclass StateTest2 extends HengoState:\n\tpass')


func test_state_implementation_without_body() -> void:
	var code: String = HenTest.get_all_code()


	assert_str(code).contains('class StateTest extends HengoState:\n\tpass')


func test_state_implementation_with_body_enter() -> void:
	var state_route: HenRouteData = state.get_route(save_data)

	var enter_vc: HenVirtualCNode = state_route.virtual_cnode_list.get(0)
	var void_vc: HenVirtualCNode = HenTest.get_void('test void', state_route)

	enter_vc.add_flow_connection(StringName('0'), StringName('0'), void_vc).add()

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('class StateTest extends HengoState:\n\tfunc enter() -> void:\n\t\t_ref.test_void()')


func test_state_implementation_with_body_update() -> void:
	var state_route: HenRouteData = state.get_route(save_data)

	var update_vc: HenVirtualCNode = state_route.virtual_cnode_list.get(1)
	var void_vc: HenVirtualCNode = HenTest.get_void('test void', state_route)

	update_vc.add_flow_connection(StringName('0'), StringName('0'), void_vc).add()

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('class StateTest extends HengoState:\n\tfunc update(delta) -> void:\n\t\tsuper(delta)\n\t\t_ref.test_void()')


func test_state_implementation_with_body_enter_and_update() -> void:
	var state_route: HenRouteData = state.get_route(save_data)


	var enter_vc: HenVirtualCNode = state_route.virtual_cnode_list.get(0)
	var void_enter_vc: HenVirtualCNode = HenTest.get_void('test void', state_route)

	enter_vc.add_flow_connection(StringName('0'), StringName('0'), void_enter_vc).add()

	var update_vc: HenVirtualCNode = state_route.virtual_cnode_list.get(1)
	var void_update_vc: HenVirtualCNode = HenTest.get_void('test void', state_route)

	update_vc.add_flow_connection(StringName('0'), StringName('0'), void_update_vc).add()

	var code: String = HenTest.get_all_code()
	assert_str(code).contains('class StateTest extends HengoState:\n\tfunc enter() -> void:\n\t\t_ref.test_void()\n\n\tfunc update(delta) -> void:\n\t\tsuper(delta)\n\t\t_ref.test_void()')


func test_state_with_transition_data() -> void:
	var transition_data: HenSaveParam = HenSaveParam.create()
	transition_data.name = 'transition data'
	transition_data.type = &'int'
	state.transition_data.append(transition_data)

	var state_route: HenRouteData = state.get_route(save_data)
	var enter_vc: HenVirtualCNode = state_route.virtual_cnode_list.get(0)
	var void_vc: HenVirtualCNode = HenTest.get_void('test void', state_route)

	enter_vc.add_flow_connection(StringName('0'), StringName('0'), void_vc).add()

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('class StateTest extends HengoState:\n\tfunc enter(transition_data) -> void:\n\t\t_ref.test_void()')


func test_state_transition_data() -> void:
	var state2: HenSaveState = save_data.add_state(false)

	state2.name = 'state test 2'


	var state_route: HenRouteData = state.get_route(save_data)
	var enter_vc: HenVirtualCNode = state_route.virtual_cnode_list.get(0)

	var router: HenRouter = Engine.get_singleton(&'Router')
	router.current_route = state.get_route(save_data)

	var transition_state_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(state2.get_transition_cnode_data(''))

	enter_vc.add_flow_connection(StringName('0'), StringName('0'), transition_state_vc).add()

	var code: String = HenTest.get_all_code()

	router.current_route = HenTest.get_base_route()
	assert_str(code).contains('class StateTest extends HengoState:\n\tfunc enter() -> void:\n\t\t_ref._STATE_CONTROLLER.change_state("state_test_2")')


func test_state_transition_sub_state() -> void:
	state.add_sub_state(save_data)
	var state2: HenSaveState = state.get_sub_states(save_data).get(0)

	state2.name = 'state test 2'

	var state_route: HenRouteData = state.get_route(save_data)
	var enter_vc: HenVirtualCNode = state_route.virtual_cnode_list.get(0)
	var void_vc: HenVirtualCNode = HenTest.get_void()

	enter_vc.add_flow_connection(StringName('0'), StringName('0'), void_vc).add()

	var router: HenRouter = Engine.get_singleton(&'Router')
	router.current_route = state.get_route(save_data)

	var transition_state_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(state2.get_transition_cnode_data(''))

	enter_vc.add_flow_connection(StringName('0'), StringName('0'), transition_state_vc).add()

	var code: String = HenTest.get_all_code()
	router.current_route = HenTest.get_base_route()
	assert_str(code).contains('func enter() -> void:\n\t\t_ref._STATE_CONTROLLER.current_state.change_sub_state("state_test_2")')


func test_state_with_local_var() -> void:
	var local_var: HenSaveParam = HenSaveParam.new()
	local_var.name = 'my var'
	local_var.type = &'int'
	state.local_vars.append(local_var)

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('class StateTest extends HengoState:\n\tvar my_var = int()')


func test_state_local_var_usage() -> void:
	var local_var: HenSaveParam = HenSaveParam.new()
	local_var.name = 'my var'
	local_var.type = &'int'
	state.local_vars.append(local_var)

	var state_route: HenRouteData = state.get_route(save_data)
	var enter_vc: HenVirtualCNode = state_route.virtual_cnode_list.get(0)

	var set_local_var: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Set ' + local_var.name,
		sub_type = HenVirtualCNode.SubType.SET_LOCAL_VAR,
		route = state_route,
		res_data = {
			id = local_var.id,
			type = HenSideBar.AddType.LOCAL_VAR
		}
	})

	var const_vc: HenVirtualCNode = HenTest.get_const()
	set_local_var.get_new_input_connection_command(StringName('0'), StringName('0'), const_vc).add()

	enter_vc.add_flow_connection(StringName('0'), StringName('0'), set_local_var).add()

	var code: String = HenTest.get_all_code()
	
	assert_str(code).contains('func enter() -> void:\n\t\tmy_var = Test.CONST')


func test_state_base_var_usage() -> void:
	var base_var: HenSaveVar = save_data.add_var(false)
	base_var.name = 'my base var'
	base_var.type = &'int'

	var state_route: HenRouteData = state.get_route(save_data)
	var enter_vc: HenVirtualCNode = state_route.virtual_cnode_list.get(0)

	var set_base_var: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Set ' + base_var.name,
		sub_type = HenVirtualCNode.SubType.SET_VAR,
		route = state_route,
		res_data = {
			id = base_var.id,
			type = HenSideBar.AddType.VAR
		}
	})

	var const_vc: HenVirtualCNode = HenTest.get_const()
	set_base_var.get_new_input_connection_command(StringName('0'), StringName('0'), const_vc).add()

	enter_vc.add_flow_connection(StringName('0'), StringName('0'), set_base_var).add()

	var code: String = HenTest.get_all_code()
	
	assert_str(code).contains('func enter() -> void:\n\t\t_ref.my_base_var = Test.CONST')


func test_state_local_var_as_reference() -> void:
	var local_var: HenSaveParam = HenSaveParam.new()
	local_var.name = 'my var'
	local_var.type = &'int'
	state.local_vars.append(local_var)

	var state_route: HenRouteData = state.get_route(save_data)
	var update_vc: HenVirtualCNode = state_route.virtual_cnode_list.get(1)

	var get_local_var: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Get ' + local_var.name,
		sub_type = HenVirtualCNode.SubType.LOCAL_VAR,
		route = state_route,
		res_data = {
			id = local_var.id,
			type = HenSideBar.AddType.LOCAL_VAR
		}
	})

	var void_with_input: HenVirtualCNode = HenTest.get_void_with_input('void with input')
	void_with_input.get_new_input_connection_command(StringName('0'), StringName('0'), get_local_var).add()

	update_vc.add_flow_connection(StringName('0'), StringName('0'), void_with_input).add()

	var code: String = HenTest.get_all_code()
	
	assert_str(code).contains('func update(delta) -> void:\n\t\tsuper(delta)\n\t\ttest_void(my_var)')