extends GdUnitTestSuite


func base() -> HenFuncData:
	HenTest.set_global_config()

	# 1. Setup the function
	HenGlobal.SIDE_BAR_LIST.type = HenSideBar.AddType.FUNC
	HenGlobal.SIDE_BAR_LIST.add()
	var func_data: HenFuncData = HenGlobal.SIDE_BAR_LIST.func_list[0]
	func_data.name = 'my_func'
	return func_data


# Scenario 1: Test if an empty function is created correctly with 'pass'.
func test_creates_empty_function_with_pass_statement() -> void:
	base()
	# 2. Generate code and verify (without manual registration)
	var script_data: HenScriptData = HenSaver.generate_script_data()
	var code: String = HenCodeGeneration.get_code(script_data)

	assert_bool(code.contains('\nfunc my_func():\n\tpass')).is_true()


# Scenario 2: Test a function with a single flow node without parameters.
func test_function_with_single_void_node_call() -> void:
	var func_data: HenFuncData = base()
	var main_func_node := func_data.input_ref.get_ref() as HenVirtualCNode

	# 2. Create the child node
	var vc_node := HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_void',
		sub_type = HenVirtualCNode.SubType.VOID,
		inputs = [],
		route = func_data.route
	})
	
	# 3. Connect the nodes
	main_func_node.add_flow_connection(0, 0, vc_node).add()

	# 4. Generate code and verify
	var script_data: HenScriptData = HenSaver.generate_script_data()
	var code: String = HenCodeGeneration.get_code(script_data)

	assert_bool(code.contains('\nfunc my_func():\n\ttest_void()')).is_true()


# Scenario 3: Test a function with a parameter that is passed to a node.
func test_function_with_parameter_passed_to_node() -> void:
	var func_data: HenFuncData = base()
	var param: HenParamData = func_data.create_param(HenSideBar.ParamType.INPUT)
	param.name = 'name_0'
	var main_func_node := func_data.input_ref.get_ref() as HenVirtualCNode

	# 2. Create the child node that will receive the parameter
	var vc_input_node := HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_void',
		sub_type = HenVirtualCNode.SubType.FUNC,
		inputs = [ {id = 0, name = 'content', type = 'Variant'}],
		route = func_data.route
	})

	# 3. Connect the flow and the data
	main_func_node.add_flow_connection(0, 0, vc_input_node).add()
	vc_input_node.get_new_input_connection_command(0, main_func_node.io.outputs[0].id, main_func_node).add()

	# 4. Generate code and verify
	var script_data: HenScriptData = HenSaver.generate_script_data()
	var code: String = HenCodeGeneration.get_code(script_data)

	assert_bool(code.contains('\nfunc my_func(name_0):\n\ttest_void(name_0)')).is_true()


# Scenario 4: Test a function that instantiates and executes a macro.
func test_function_can_call_a_macro_containing_a_node() -> void:
	HenTest.set_global_config()

	# 1. Setup the Macro
	HenGlobal.SIDE_BAR_LIST.type = HenSideBar.AddType.MACRO
	HenGlobal.SIDE_BAR_LIST.add()
	var macro_data: HenMacroData = HenGlobal.SIDE_BAR_LIST.macro_list[0]
	macro_data.name = 'my_macro'
	macro_data.create_flow(HenSideBar.ParamType.INPUT, 0)
	var main_macro_node := macro_data.input_ref.get_ref() as HenVirtualCNode

	# 2. Create the node that exists INSIDE the macro
	var node_inside_macro := HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_void',
		sub_type = HenVirtualCNode.SubType.VOID,
		inputs = [],
		route = macro_data.route
	})
	main_macro_node.add_flow_connection(0, 0, node_inside_macro).add()

	# 3. Setup the Function that will call the macro
	HenGlobal.SIDE_BAR_LIST.type = HenSideBar.AddType.FUNC
	HenGlobal.SIDE_BAR_LIST.add()
	var func_data: HenFuncData = HenGlobal.SIDE_BAR_LIST.func_list[0]
	func_data.name = 'my_func'
	var main_func_node := func_data.input_ref.get_ref() as HenVirtualCNode

	# 4. Instantiate the Macro INSIDE the function
	var macro_conf: Dictionary = macro_data.get_cnode_data()
	macro_conf.route = func_data.route # The instance belongs to the function's route
	var macro_instance_node := HenVirtualCNode.instantiate_virtual_cnode(macro_conf)
	
	# 5. Connect the function's flow to the macro's instance
	main_func_node.add_flow_connection(0, 0, macro_instance_node).add()
	
	# 6. Generate code and verify
	var script_data: HenScriptData = HenSaver.generate_script_data()
	var code: String = HenCodeGeneration.get_code(script_data)

	# The expected result is the macro call, which in turn executes test_void()
	assert_bool(code.contains('\nfunc my_func():\n\ttest_void()')).is_true()