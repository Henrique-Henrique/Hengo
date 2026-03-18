extends HenTestSuite


var var_data: HenSaveVar


func before_test() -> void:
	super ()
	var_data = save_data.add_var(false)
	var_data.name = 'test var'
	var_data.type = &'int'


func test_get_var_code_generation() -> void:
	var code: String = HenTest.get_all_code()

	assert_str(code).contains('var test_var = int()')


func test_var_getter() -> void:
	var var_get_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(var_data.get_getter_cnode_data(''))
	var code: String = HenTest.get_vc_code(var_get_vc)

	assert_str(code).is_equal('test_var')


func test_var_setter() -> void:
	var var_get_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(var_data.get_setter_cnode_data(''))
	var code: String = HenTest.get_vc_code(var_get_vc)

	assert_str(code).is_equal('test_var = 0')


func test_get_var_code_generation_default_string() -> void:
	var_data.type = &'String'
	var_data.default_value = 'hello world'
	var code: String = HenTest.get_all_code()

	assert_str(code).contains('var test_var = "hello world"')


func test_get_var_code_generation_default_float() -> void:
	var_data.type = &'float'
	var_data.default_value = 10.5
	var code: String = HenTest.get_all_code()

	assert_str(code).contains('var test_var = 10.5')
