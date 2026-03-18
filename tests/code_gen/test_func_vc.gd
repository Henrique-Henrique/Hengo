extends HenTestSuite


# helper to make func nodes with any number of outputs
func _create_func_node(outputs: Array) -> HenVirtualCNode:
	return HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test func',
		outputs = outputs,
		sub_type = HenVirtualCNode.SubType.FUNC,
		route = HenTest.get_base_route()
	})


# a single output func should be a direct call, no index needed
func test_single_output_function_call() -> void:
	var func_node: HenVirtualCNode = _create_func_node([
		{id = 0, name = 'output', type = 'Variant'}
	])

	assert_str(HenTest.get_vc_code(func_node)).is_equal('test_func()')


# using the first output from a multi-return func should add a [0]
func test_multi_output_function_first_return_as_input() -> void:
	var func_node: HenVirtualCNode = _create_func_node([
		{id = 0, name = 'return_1', type = 'Variant'},
		{id = 1, name = 'return_2', type = 'Variant'}
	])
	var void_node: HenVirtualCNode = HenTest.get_void_with_input()

	# connect the func's first output to the void's input
	void_node.get_new_input_connection_command(StringName('0'), StringName('0'), func_node).add()

	assert_str(HenTest.get_vc_code(void_node)).is_equal('test_void(test_func()[0])')


# using the second output from a multi-return func should add a [1]
func test_multi_output_function_second_return_as_input() -> void:
	var func_node: HenVirtualCNode = _create_func_node([
		{id = 0, name = 'return_1', type = 'Variant'},
		{id = 1, name = 'return_2', type = 'Variant'}
	])
	var void_node: HenVirtualCNode = HenTest.get_void_with_input()
	
	# connect the func's second output to the void's input
	void_node.get_new_input_connection_command(StringName('0'), StringName('1'), func_node).add()

	assert_str(HenTest.get_vc_code(void_node)).is_equal('test_void(test_func()[1])')
