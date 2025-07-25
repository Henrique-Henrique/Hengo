extends GutTest


func test_func() -> void:
	HenTest.set_global_config()

	HenGlobal.SIDE_BAR_LIST.type = HenSideBar.AddType.FUNC
	HenGlobal.SIDE_BAR_LIST.add()

	var func_data: HenFuncData = HenGlobal.SIDE_BAR_LIST.func_list[0]
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

	# with input
	var param: HenParamData = func_data.create_param(HenSideBar.ParamType.INPUT)
	param.name = 'name_0'

	var vc_input: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_void',
		sub_type = HenVirtualCNode.SubType.FUNC,
		inputs = [
			{
				id = 0,
				name = 'content',
				type = 'Variant'
			}
		],
		route = func_data.route
	})
	
	func_data.input_ref.add_flow_connection(0, 0, vc_input).add()
	vc_input.add_input_connection(0, func_data.input_ref.outputs[0].id, func_data.input_ref)

	var script_input_data: HenScriptData = HenSaver.generate_script_data()
	var code_input: String = HenCodeGeneration.get_code(script_input_data)

	assert_true(
		code_input.contains('\nfunc my_func(name_0):\n\ttest_void(name_0)'),
		'Testing function with vc connection and param input'
	)

	# test macro
	HenGlobal.SIDE_BAR_LIST.type = HenSideBar.AddType.MACRO
	HenGlobal.SIDE_BAR_LIST.add()

	var macro_data: HenMacroData = HenGlobal.SIDE_BAR_LIST.macro_list[0]
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
	func_data.input_ref.add_flow_connection(0, 0, vc).add()
	vc.add_flow_connection(0, 0, macro_inst).add()

	var script_data_3: HenScriptData = HenSaver.generate_script_data()
	var code_3: String = HenCodeGeneration.get_code(script_data_3)

	assert_true(
		code_3.contains('\nfunc my_func(name_0):\n\ttest_void()\n\ttest_void()'),
		'Testing function with macro'
	)