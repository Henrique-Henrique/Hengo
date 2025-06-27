extends GutTest


func test_save() -> void:
	HenTest.set_global_config()

	var start_state: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Start State',
		type = HenVirtualCNode.Type.STATE_START,
		sub_type = HenVirtualCNode.SubType.STATE_START,
		position = Vector2(0, 0),
		can_delete = false,
		route = HenGlobal.BASE_ROUTE
	})

	var state: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'State 1',
		type = HenVirtualCNode.Type.STATE,
		sub_type = HenVirtualCNode.SubType.STATE,
		route = HenGlobal.BASE_ROUTE
	})

	start_state.add_flow_connection(0, 0, state).add()

	var script_data: HenScriptData = HenSaver.generate_script_data()
	var code: String = HenCodeGeneration.get_code(script_data)

	assert_true(code.contains('\nconst _EVENTS = {}'), 'Testing events constant declaration')
	assert_true(code.contains('\nfunc _init() -> void:\n\t_STATE_CONTROLLER.set_states({\n\t\tstate_1=State1.new(self)\n\t})'), 'Testing init function with state controller setup')
	assert_true(code.contains('\nfunc _ready() -> void:\n\tif not _STATE_CONTROLLER.current_state:\n\t\t_STATE_CONTROLLER.change_state("state_1")'), 'Testing ready function with start state name')
	assert_true(code.contains('\nclass State1 extends HengoState:\n\tpass'), 'Testing class creation')

	var enter_vc: HenVirtualCNode = state.virtual_cnode_list[0]
	var vc_flow_1: HenVirtualCNode = HenTest.get_void(state.route)

	enter_vc.add_flow_connection(0, 0, vc_flow_1).add()

	var new_script_data: HenScriptData = HenSaver.generate_script_data()
	var new_code: String = HenCodeGeneration.get_code(new_script_data)

	assert_true(new_code.contains('\nclass State1 extends HengoState:\n\tfunc enter() -> void:\n\t\t_ref.test_void()'), 'Testing enter function in state class with void call')

	# test macro
	HenGlobal.SIDE_BAR_LIST.type = HenSideBar.AddType.MACRO
	HenGlobal.SIDE_BAR_LIST.add()

	var macro_data: HenMacroData = HenGlobal.SIDE_BAR_LIST.macro_list[0]
	macro_data.name = 'my macro'
	macro_data.create_flow(HenSideBar.ParamType.INPUT, 0)

	var macro_conf: Dictionary = macro_data.get_cnode_data()
	macro_conf.route = state.route

	var macro_inst: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(macro_conf)
	var macro_flow: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_void_2',
		sub_type = HenVirtualCNode.SubType.VOID,
		inputs = [],
		route = macro_data.route
	})

	macro_data.input_ref.add_flow_connection(0, 0, macro_flow).add()
	vc_flow_1.add_flow_connection(0, 0, macro_inst).add()

	var script_data_2: HenScriptData = HenSaver.generate_script_data()
	var code_2: String = HenCodeGeneration.get_code(script_data_2)

	assert_true(code_2.contains('\nclass State1 extends HengoState:\n\tfunc enter() -> void:\n\t\t_ref.test_void()\n\t\t_ref.test_void_2()'), 'Testing enter function in state class with void call and macro')