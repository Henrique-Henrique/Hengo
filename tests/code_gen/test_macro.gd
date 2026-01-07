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