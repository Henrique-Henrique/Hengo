extends GutTest


func test_func() -> void:
	HenTest.set_global_config()

	HenGlobal.SIDE_BAR_LIST.type = HenSideBar.AddType.FUNC
	HenGlobal.SIDE_BAR_LIST.add()

	var func_data: HenSideBar.FuncData = HenGlobal.SIDE_BAR_LIST.func_list[0]
	func_data.name = 'my func'

	var script_data: HenScriptData = HenSaver.generate_script_data()
	var code: String = HenCodeGeneration.get_code(script_data)

	assert_true(
		code.contains('\nfunc my_func():\n\tpass'),
		'Testing function empty'
	)

	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_void',
		sub_type = HenVirtualCNode.SubType.VOID,
		inputs = [],
		route = func_data.route
	})
	
	func_data.input_ref.add_flow_connection(0, 0, vc).add()

	var script_data_2: HenScriptData = HenSaver.generate_script_data()
	var code_2: String = HenCodeGeneration.get_code(script_data_2)

	assert_true(
		code_2.contains('\nfunc my_func():\n\ttest_void()'),
		'Testing function with vc connection'
	)

	# test macro
	HenGlobal.SIDE_BAR_LIST.type = HenSideBar.AddType.MACRO
	HenGlobal.SIDE_BAR_LIST.add()

	var macro_data: HenSideBar.MacroData = HenGlobal.SIDE_BAR_LIST.macro_list[0]
	macro_data.name = 'my macro'
	macro_data.create_flow(HenSideBar.ParamType.INPUT, 0)

	var macro_conf: Dictionary = macro_data.get_cnode_data()
	macro_conf.route = func_data.route

	var macro_inst: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(macro_conf)
	var macro_flow: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_void',
		sub_type = HenVirtualCNode.SubType.VOID,
		inputs = [],
		route = macro_data.route
	})

	macro_data.input_ref.add_flow_connection(0, 0, macro_flow).add()
	vc.add_flow_connection(0, 0, macro_inst).add()

	var script_data_3: HenScriptData = HenSaver.generate_script_data()
	var code_3: String = HenCodeGeneration.get_code(script_data_3)

	assert_true(
		code_3.contains('\nfunc my_func():\n\ttest_void()\n\ttest_void()'),
		'Testing function with macro'
	)