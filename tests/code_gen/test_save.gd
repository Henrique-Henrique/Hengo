extends GdUnitTestSuite


# This function runs before each test, ensuring a clean global state.
func before_each():
	HenTest.set_global_config()


# Helper to create the base state machine fixture used in all tests.
# It creates a 'Start' node and a 'State 1' node, then connects them.
# Returns the created state node for further manipulation in tests.
func _setup_base_state_machine() -> HenVirtualCNode:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	var start_state: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Start State',
		type = HenVirtualCNode.Type.STATE_START,
		sub_type = HenVirtualCNode.SubType.STATE_START,
		can_delete = false,
		route = global.BASE_ROUTE
	})

	var state: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'State 1',
		type = HenVirtualCNode.Type.STATE,
		sub_type = HenVirtualCNode.SubType.STATE,
		route = global.BASE_ROUTE
	})

	start_state.add_flow_connection(0, 0, state).add()
	return state


# Helper to reduce boilerplate for generating code from the current graph.
func _get_generated_code() -> String:
	var code_generation: HenCodeGeneration = Engine.get_singleton(&'CodeGeneration')

	var script_data: HenScriptData = HenSaver.generate_script_data()
	# The replacen is kept to match original test's behavior
	return code_generation.get_code(script_data).replacen(' \r\n', '\n')


# Tests the default code generated for a basic two-state machine.
func test_default_state_machine_code() -> void:
	_setup_base_state_machine()
	var code: String = _get_generated_code()

	assert_bool(code.contains('\nconst _EVENTS = {}')).is_true()
	assert_bool(code.contains('\nfunc _init() -> void:\n\t_STATE_CONTROLLER.set_states({\n\t\tstate_1=State1.new(self)\n\t})')).is_true()
	assert_bool(code.contains('\nfunc _ready() -> void:\n\tif not _STATE_CONTROLLER.current_state:\n\t\t_STATE_CONTROLLER.change_state("state_1")')).is_true()
	assert_bool(code.contains('\nclass State1 extends HengoState:\n\tpass')).is_true()


# Tests code generation when a flow is added to the state's 'enter' event.
func test_state_with_enter_flow() -> void:
	var state: HenVirtualCNode = _setup_base_state_machine()
	var enter_vc: HenVirtualCNode = state.children.virtual_cnode_list[0]
	var void_node: HenVirtualCNode = HenTest.get_void(state.route_info.route)

	enter_vc.add_flow_connection(0, 0, void_node).add()
	var code: String = _get_generated_code()

	var expected_class_body = '\nclass State1 extends HengoState:\n\tfunc enter() -> void:\n\t\t_ref.test_void()'
	assert_bool(code.contains(expected_class_body)).is_true()


# Tests code generation when flows are added to both 'enter' and 'update' events.
func test_state_with_enter_and_update_flows() -> void:
	var state: HenVirtualCNode = _setup_base_state_machine()

	# Add flow to the 'enter' node
	var enter_vc: HenVirtualCNode = state.children.virtual_cnode_list[0]
	var enter_flow_node: HenVirtualCNode = HenTest.get_void(state.route_info.route)
	enter_vc.add_flow_connection(0, 0, enter_flow_node).add()

	# Add flow to the 'update' node
	var update_vc: HenVirtualCNode = state.children.virtual_cnode_list[1]
	var update_flow_node: HenVirtualCNode = HenTest.get_void(state.route_info.route)
	update_vc.add_flow_connection(0, 0, update_flow_node).add()
	
	var code: String = _get_generated_code()
	var expected_class_body = '\nclass State1 extends HengoState:\n\tfunc enter() -> void:\n\t\t_ref.test_void()\n\n\tfunc update(delta) -> void:\n\t\t_ref.test_void()'
	assert_bool(code.contains(expected_class_body)).is_true()


# Tests using a custom macro within a state's 'enter' flow.
func test_state_with_macro_in_enter_flow() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var state: HenVirtualCNode = _setup_base_state_machine()
	
	# Setup an initial node in the enter flow
	var enter_vc: HenVirtualCNode = state.children.virtual_cnode_list[0]
	var initial_void_node: HenVirtualCNode = HenTest.get_void(state.route_info.route)
	enter_vc.add_flow_connection(0, 0, initial_void_node).add()

	# Create and configure the macro
	global.SIDE_BAR_LIST.type = HenSideBar.AddType.MACRO
	global.SIDE_BAR_LIST.add()
	var macro_data: HenMacroData = global.SIDE_BAR_LIST.macro_list[0]
	macro_data.name = 'my macro'
	macro_data.create_flow(HenSideBar.ParamType.INPUT, 0)

	# Add content to the macro's graph
	var macro_flow_node: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_void_2',
		sub_type = HenVirtualCNode.SubType.VOID,
		route = macro_data.route
	})
	var macro_input_node = macro_data.input_ref.get_ref() as HenVirtualCNode
	macro_input_node.add_flow_connection(0, 0, macro_flow_node).add()

	# Instantiate the macro inside the state's graph
	var macro_conf: Dictionary = macro_data.get_cnode_data()
	macro_conf.route = state.route_info.route
	var macro_instance: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(macro_conf)

	# Connect the macro instance to run after the initial node
	initial_void_node.add_flow_connection(0, 0, macro_instance).add()

	var code: String = _get_generated_code()
	var expected_class_body = '\nclass State1 extends HengoState:\n\tfunc enter() -> void:\n\t\t_ref.test_void()\n\t\t_ref.test_void_2()'
	assert_bool(code.contains(expected_class_body)).is_true()