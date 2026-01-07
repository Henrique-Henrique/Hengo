extends HenTestSuite


var func_data: HenSaveFunc

func before_test() -> void:
	super ()
	func_data = save_data.add_func(false)
	func_data.name = 'test func'


func test_func_code() -> void:
	var func_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(func_data.get_cnode_data(''))
	var code: String = HenTest.get_vc_code(func_vc)

	assert_str(code).is_equal('test_func()')


func test_func_code_with_output() -> void:
	var func_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(func_data.get_cnode_data(''))
	var void_vc: HenVirtualCNode = HenTest.get_void_with_input()

	var first_output: HenSaveParam = HenSaveParam.new()
	var first_output_2: HenSaveParam = HenSaveParam.new()

	func_data.outputs.append(first_output)
	func_data.outputs.append(first_output_2)

	void_vc.get_new_input_connection_command(0, first_output.id, func_vc).add()

	var code: String = HenTest.get_vc_code(void_vc)

	assert_str(code).is_equal('test_void(test_func()[0])')


func test_func_code_with_output_index() -> void:
	var func_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(func_data.get_cnode_data(''))
	var void_vc: HenVirtualCNode = HenTest.get_void_with_input()

	var first_output: HenSaveParam = HenSaveParam.new()
	var first_output_2: HenSaveParam = HenSaveParam.new()

	func_data.outputs.append(first_output)
	func_data.outputs.append(first_output_2)

	void_vc.get_new_input_connection_command(0, first_output_2.id, func_vc).add()

	var code: String = HenTest.get_vc_code(void_vc)

	assert_str(code).is_equal('test_void(test_func()[1])')


func test_func_code_with_input() -> void:
	var func_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(func_data.get_cnode_data(''))
	var first_input: HenSaveParam = HenSaveParam.new()
	
	first_input.type = &'int'
	func_data.inputs.append(first_input)

	var code: String = HenTest.get_vc_code(func_vc)

	assert_str(code).is_equal('test_func(0)')


func test_func_body_generation() -> void:
	HenVirtualCNode.instantiate_virtual_cnode(func_data.get_cnode_data(''))
	var code: String = HenTest.get_all_code()
	assert_str(code).contains('func test_func():\n\tpass')


func test_func_body_generation_with_local_var() -> void:
	HenVirtualCNode.instantiate_virtual_cnode(func_data.get_cnode_data(''))

	var local_var: HenSaveParam = HenSaveParam.new()
	local_var.name = 'my var'
	local_var.type = &'int'
	func_data.local_vars.append(local_var)

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('func test_func():\n\tvar my_var = int()')


func test_func_generation_with_one_output() -> void:
	HenVirtualCNode.instantiate_virtual_cnode(func_data.get_cnode_data(''))

	var output: HenSaveParam = HenSaveParam.new()
	output.type = &'int'
	func_data.outputs.append(output)

	var code: String = HenTest.get_all_code()
	assert_str(code).contains('func test_func():\n\treturn 0')


func test_func_generation_with_more_than_one_output() -> void:
	HenVirtualCNode.instantiate_virtual_cnode(func_data.get_cnode_data(''))

	var output: HenSaveParam = HenSaveParam.new()
	output.type = &'int'
	func_data.outputs.append(output)

	var output_2: HenSaveParam = HenSaveParam.new()
	output_2.type = &'int'
	func_data.outputs.append(output_2)

	var code: String = HenTest.get_all_code()
	assert_str(code).contains('func test_func():\n\treturn [0, 0]')


func test_func_generation_with_more_than_one_output_and_connections() -> void:
	HenVirtualCNode.instantiate_virtual_cnode(func_data.get_cnode_data(''))

	var output: HenSaveParam = HenSaveParam.new()
	output.type = &'int'
	func_data.outputs.append(output)

	var output_2: HenSaveParam = HenSaveParam.new()
	output_2.type = &'int'
	func_data.outputs.append(output_2)

	var first_con_vc: HenVirtualCNode = HenTest.get_const()
	var second_con_vc: HenVirtualCNode = HenTest.get_const()

	var output_ref = HenGeneratorFunc.search_output_ref(save_data, func_data)

	output_ref.get_new_input_connection_command(output.id, 0, first_con_vc).add()
	output_ref.get_new_input_connection_command(output_2.id, 0, second_con_vc).add()
	
	var code: String = HenTest.get_all_code()
	assert_str(code).contains('func test_func():\n\treturn [Test.CONST, Test.CONST]')
