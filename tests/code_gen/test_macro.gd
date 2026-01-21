extends HenTestSuite


var macro_data: HenSaveMacro


func before_test() -> void:
	super ()
	macro_data = save_data.add_macro()


func test_macro_without_body() -> void:
	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(macro_data.get_cnode_data(''))

	var code: String = HenTest.get_vc_code(macro_vc)

	assert_str(code).is_equal('pass')


func test_macro_flow_input_connection() -> void:
	var first_flow_input: HenSaveParam = HenSaveParam.new()
	macro_data.flow_inputs.append(first_flow_input)

	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(macro_data.get_cnode_data(''))
	var macro_input: HenVirtualCNode = HenVirtualCNodeCode.search_macro_input(save_data, macro_data)
	var macro_flow_vc: HenVirtualCNode = HenTest.get_void('test void', macro_data.get_route(save_data))

	macro_input.add_flow_connection(first_flow_input.id, 0, macro_flow_vc).add()

	var code: String = HenTest.get_vc_code(macro_vc, first_flow_input.id)

	assert_str(code).is_equal('test_void()')


func test_macro_flow_output_connection() -> void:
	var first_flow_input: HenSaveParam = HenSaveParam.new()
	var first_flow_output: HenSaveParam = HenSaveParam.new()

	macro_data.flow_inputs.append(first_flow_input)
	macro_data.flow_outputs.append(first_flow_output)

	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(macro_data.get_cnode_data(''))
	var macro_input: HenVirtualCNode = HenVirtualCNodeCode.search_macro_input(save_data, macro_data)
	var macro_output: HenVirtualCNode = HenVirtualCNodeCode.search_macro_output(save_data, macro_data)

	var macro_flow_vc: HenVirtualCNode = HenTest.get_void('test inside macro')

	macro_input.add_flow_connection(first_flow_input.id, 0, macro_flow_vc).add()
	macro_flow_vc.add_flow_connection(0, first_flow_output.id, macro_output).add()

	# creating if there to test flow output connection code
	var if_vc: HenVirtualCNode = HenTest.get_if_vc()
	var another_flow_vc: HenVirtualCNode = HenTest.get_void()

	if_vc.add_flow_connection(0, first_flow_input.id, macro_vc).add()
	macro_vc.add_flow_connection(first_flow_output.id, 0, another_flow_vc).add()

	var code: String = HenTest.get_vc_code(if_vc)

	assert_str(code).is_equal('if false:\n\ttest_inside_macro()\n\ttest_void()')


func test_macro_with_input_connection() -> void:
	var first_input: HenSaveParam = HenSaveParam.new()
	var first_flow_input: HenSaveParam = HenSaveParam.new()

	macro_data.inputs.append(first_input)
	macro_data.flow_inputs.append(first_flow_input)

	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(macro_data.get_cnode_data(''))
	var void_with_output: HenVirtualCNode = HenTest.get_const()

	macro_vc.get_new_input_connection_command(first_input.id, 0, void_with_output).add()

	var macro_input: HenVirtualCNode = HenVirtualCNodeCode.search_macro_input(save_data, macro_data)
	var macro_flow_vc: HenVirtualCNode = HenTest.get_void_with_input()

	macro_input.add_flow_connection(first_flow_input.id, 0, macro_flow_vc).add()
	macro_flow_vc.get_new_input_connection_command(0, first_input.id, macro_input).add()

	var code: String = HenTest.get_vc_code(macro_vc, first_flow_input.id)

	assert_str(code).is_equal('test_void(Test.CONST)')


func test_macro_with_output_connection() -> void:
	var first_output: HenSaveParam = HenSaveParam.new()
	var first_flow_input: HenSaveParam = HenSaveParam.new()

	macro_data.outputs.append(first_output)
	macro_data.flow_inputs.append(first_flow_input)

	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(macro_data.get_cnode_data(''))
	var void_with_input: HenVirtualCNode = HenTest.get_void_with_input()

	void_with_input.get_new_input_connection_command(0, first_output.id, macro_vc).add()

	var macro_output: HenVirtualCNode = HenVirtualCNodeCode.search_macro_output(save_data, macro_data)
	var macro_flow_vc: HenVirtualCNode = HenTest.get_const()

	macro_output.get_new_input_connection_command(first_output.id, 0, macro_flow_vc).add()

	var code: String = HenTest.get_vc_code(void_with_input)

	assert_str(code).is_equal('test_void(Test.CONST)')


func test_macro_local_var() -> void:
	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(macro_data.get_cnode_data(''))

	var local_var: HenSaveParam = HenSaveParam.new()
	local_var.name = 'my local var'
	local_var.type = 'int'
	macro_data.local_vars.append(local_var)

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('var my_local_var_' + str(macro_vc.id) + ' = int()')


func test_macro_local_var_usage() -> void:
	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(macro_data.get_cnode_data(''))

	var local_var: HenSaveParam = HenSaveParam.new()
	local_var.name = 'my local var'
	local_var.type = 'int'
	macro_data.local_vars.append(local_var)
	
	var macro_input: HenVirtualCNode = HenVirtualCNodeCode.search_macro_input(save_data, macro_data)

	var set_local_var: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Set ' + local_var.name,
		sub_type = HenVirtualCNode.SubType.SET_LOCAL_VAR,
		route = macro_data.get_route(save_data),
		res_data = {
			id = local_var.id,
			type = HenSideBar.AddType.LOCAL_VAR
		}
	})
	
	var const_vc: HenVirtualCNode = HenTest.get_const()

	# set value
	set_local_var.get_new_input_connection_command(0, 0, const_vc).add()

	var flow_input: HenSaveParam = HenSaveParam.new()
	macro_data.flow_inputs.append(flow_input)
	macro_input.add_flow_connection(flow_input.id, 0, set_local_var).add()

	var code: String = HenTest.get_vc_code(macro_vc, flow_input.id)

	assert_str(code).contains('my_local_var_' + str(macro_vc.id) + ' = Test.CONST')


func test_macro_override_virtual() -> void:
	HenVirtualCNode.instantiate_virtual_cnode(macro_data.get_cnode_data(''))

	var virtual_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = '_ready',
		route = macro_data.get_route(save_data),
		sub_type = HenVirtualCNode.SubType.OVERRIDE_VIRTUAL
	})

	var virtual_flow_vc: HenVirtualCNode = HenTest.get_void('test virtual')

	virtual_vc.add_flow_connection(0, 0, virtual_flow_vc).add()

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('func _ready() -> void:\n\tif not _STATE_CONTROLLER.current_state:\n\t\t_STATE_CONTROLLER.change_state("")\n\ttest_virtual()')


# tests that void calls inside a macro on base route generate test_void() not _ref.test_void()
func test_macro_void_call_on_base_route_uses_direct_call() -> void:
	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(macro_data.get_cnode_data(''))

	var flow_input: HenSaveParam = HenSaveParam.new()
	macro_data.flow_inputs.append(flow_input)

	var macro_input: HenVirtualCNode = HenVirtualCNodeCode.search_macro_input(save_data, macro_data)
	var void_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_void',
		sub_type = HenVirtualCNode.SubType.VOID,
		route = macro_data.get_route(save_data)
	})

	macro_input.add_flow_connection(flow_input.id, 0, void_vc).add()

	var code: String = HenTest.get_vc_code(macro_vc, flow_input.id)

	assert_str(code).is_equal('test_void()')


# tests that void calls inside a macro on state route generate _ref.test_void() not test_void()
func test_macro_void_call_on_state_route_uses_ref_prefix() -> void:
	var state: HenSaveState = HenSaveState.create()
	var state_macro: HenSaveMacro = save_data.add_macro()

	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = state_macro.name,
		type = HenVirtualCNode.Type.MACRO,
		sub_type = HenVirtualCNode.SubType.MACRO,
		route = state.get_route(save_data),
		res_data = state_macro.get_res_data(HenSideBar.AddType.MACRO, '')
	})

	var flow_input: HenSaveParam = HenSaveParam.new()
	state_macro.flow_inputs.append(flow_input)

	var macro_input: HenVirtualCNode = HenVirtualCNodeCode.search_macro_input(save_data, state_macro)
	var void_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_void',
		sub_type = HenVirtualCNode.SubType.VOID,
		route = state_macro.get_route(save_data)
	})

	macro_input.add_flow_connection(flow_input.id, 0, void_vc).add()

	var code: String = HenTest.get_vc_code(macro_vc, flow_input.id)

	assert_str(code).is_equal('_ref.test_void()')


# tests that local var usage inside a macro on base route uses my_var_id not _ref.my_var_id
func test_macro_local_var_on_base_route_without_ref() -> void:
	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(macro_data.get_cnode_data(''))

	var local_var: HenSaveParam = HenSaveParam.new()
	local_var.name = 'my var'
	local_var.type = 'int'
	macro_data.local_vars.append(local_var)

	var flow_input: HenSaveParam = HenSaveParam.new()
	macro_data.flow_inputs.append(flow_input)

	var macro_input: HenVirtualCNode = HenVirtualCNodeCode.search_macro_input(save_data, macro_data)

	var set_local_var: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Set ' + local_var.name,
		sub_type = HenVirtualCNode.SubType.SET_LOCAL_VAR,
		route = macro_data.get_route(save_data),
		res_data = {
			id = local_var.id,
			type = HenSideBar.AddType.LOCAL_VAR
		}
	})

	var const_vc: HenVirtualCNode = HenTest.get_const()
	set_local_var.get_new_input_connection_command(0, 0, const_vc).add()

	macro_input.add_flow_connection(flow_input.id, 0, set_local_var).add()

	var code: String = HenTest.get_vc_code(macro_vc, flow_input.id)

	assert_str(code).contains('my_var_' + str(macro_vc.id) + ' = Test.CONST')


# tests that local var usage inside a macro on state route uses _ref.my_var_id
func test_macro_local_var_on_state_route_with_ref() -> void:
	var state: HenSaveState = HenSaveState.create()
	var state_macro: HenSaveMacro = save_data.add_macro()

	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = state_macro.name,
		type = HenVirtualCNode.Type.MACRO,
		sub_type = HenVirtualCNode.SubType.MACRO,
		route = state.get_route(save_data),
		res_data = state_macro.get_res_data(HenSideBar.AddType.MACRO, '')
	})

	var local_var: HenSaveParam = HenSaveParam.new()
	local_var.name = 'my var'
	local_var.type = 'int'
	state_macro.local_vars.append(local_var)

	var flow_input: HenSaveParam = HenSaveParam.new()
	state_macro.flow_inputs.append(flow_input)

	var macro_input: HenVirtualCNode = HenVirtualCNodeCode.search_macro_input(save_data, state_macro)

	var set_local_var: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Set ' + local_var.name,
		sub_type = HenVirtualCNode.SubType.SET_LOCAL_VAR,
		route = state_macro.get_route(save_data),
		res_data = {
			id = local_var.id,
			type = HenSideBar.AddType.LOCAL_VAR
		}
	})

	var const_vc: HenVirtualCNode = HenTest.get_const()
	set_local_var.get_new_input_connection_command(0, 0, const_vc).add()

	macro_input.add_flow_connection(flow_input.id, 0, set_local_var).add()

	var code: String = HenTest.get_vc_code(macro_vc, flow_input.id)

	assert_str(code).contains('_ref.my_var_' + str(macro_vc.id) + ' = Test.CONST')