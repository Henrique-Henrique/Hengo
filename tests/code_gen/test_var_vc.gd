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
