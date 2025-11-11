extends GdUnitTestSuite


func base() -> HenSignalData:
	HenTest.set_global_config()

	var global: HenGlobal = Engine.get_singleton(&'Global')
	# setup the variable
	global.SIDE_BAR_LIST.type = HenSideBar.AddType.SIGNAL
	global.SIDE_BAR_LIST.add()
	var signal_data: HenSignalData = global.SIDE_BAR_LIST.signal_list[0]
	signal_data.name = 'my signal'
	return signal_data


func base_2() -> HenSignalData:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	# setup the variable
	global.SIDE_BAR_LIST.type = HenSideBar.AddType.SIGNAL
	global.SIDE_BAR_LIST.add()
	var signal_data: HenSignalData = global.SIDE_BAR_LIST.signal_list[1]
	signal_data.name = 'my signal 2'
	return signal_data


# test if a basic signal is created with default value
func test_creates_basic_signal() -> void:
	base()
	
	var code_generation: HenCodeGeneration = Engine.get_singleton(&'CodeGeneration')
	var script_data: HenScriptData = HenSaver.generate_script_data()
	var code: String = code_generation.get_code(script_data)

	assert_bool(code.contains('signal my_signal')).is_true()


# test if a basic signal is created with default value
func test_create_two_signals() -> void:
	base_2()
	
	var code_generation: HenCodeGeneration = Engine.get_singleton(&'CodeGeneration')
	var script_data: HenScriptData = HenSaver.generate_script_data()
	var code: String = code_generation.get_code(script_data)

	assert_bool(code.contains('signal my_signal\nsignal my_signal_2')).is_true()