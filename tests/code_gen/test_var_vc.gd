extends GdUnitTestSuite


func get_var_data() -> HenSaveVar:
	var save_data: HenSaveData = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
	save_data.variables.clear()
	save_data.add_var(false)

	var var_data: HenSaveVar = save_data.variables.get(0)

	var_data.name = 'test var'
	var_data.type = &'int'

	return var_data


func test_get_var_code_generation() -> void:
	get_var_data()

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('var test_var = int()')


func test_var_getter() -> void:
	var var_data: HenSaveVar = get_var_data()
	var var_get_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(var_data.get_getter_cnode_data(''))
	var code: String = HenTest.get_vc_code(var_get_vc)

	assert_str(code).is_equal('test_var')


func test_var_setter() -> void:
	var var_data: HenSaveVar = get_var_data()
	
	var var_get_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(var_data.get_setter_cnode_data(''))
	var code: String = HenTest.get_vc_code(var_get_vc)

	assert_str(code).is_equal('test_var = 0')
