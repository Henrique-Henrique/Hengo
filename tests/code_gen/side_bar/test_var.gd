extends GdUnitTestSuite


func base() -> HenVarData:
	HenTest.set_global_config()

	# setup the variable
	HenGlobal.SIDE_BAR_LIST.type = HenSideBar.AddType.VAR
	HenGlobal.SIDE_BAR_LIST.add()
	var var_data: HenVarData = HenGlobal.SIDE_BAR_LIST.var_list[0]
	var_data.name = 'my var'
	var_data.type = 'int'
	return var_data


# test if a basic variable is created with default value
func test_creates_basic_variable() -> void:
	base()
	
	var script_data: HenScriptData = HenSaver.generate_script_data()
	var code: String = HenCodeGeneration.get_code(script_data)

	assert_bool(code.contains('var my_var')).is_true()


# test variable with default value based on type
func test_creates_variable_with_type_default() -> void:
	base()
	var script_data: HenScriptData = HenSaver.generate_script_data()
	var code: String = HenCodeGeneration.get_code(script_data)

	assert_bool(code.contains('var my_var = int()')).is_true()


# test variable with space at the beginning
func test_variable_with_leading_space() -> void:
	base()
	var script_data: HenScriptData = HenSaver.generate_script_data()
	var code: String = HenCodeGeneration.get_code(script_data)
	assert_bool(code.contains('var  my_var')).is_false() # should not have double space


# test variable with space at the end
func test_variable_with_trailing_space() -> void:
	base()
	var script_data: HenScriptData = HenSaver.generate_script_data()
	var code: String = HenCodeGeneration.get_code(script_data)
	assert_bool(code.contains('var my_var  ')).is_false() # should not have trailing spaces


# test variable with space in the middle
func test_variable_with_middle_space() -> void:
	base()
	var script_data: HenScriptData = HenSaver.generate_script_data()
	var code: String = HenCodeGeneration.get_code(script_data)
	assert_bool(code.contains('var my var')).is_false() # should not have spaces in variable name


# test for spaces before 'var' keyword
func test_no_spaces_before_var_keyword() -> void:
	base()
	var script_data: HenScriptData = HenSaver.generate_script_data()
	var code: String = HenCodeGeneration.get_code(script_data)
	
	# check that the line starts with 'var' without leading spaces
	for line in code.split('\n'):
		if 'var ' in line:
			assert_bool(line.begins_with('var ')).is_true()
