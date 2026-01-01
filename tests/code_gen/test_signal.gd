extends GdUnitTestSuite


# Asserts a referenced call for nodes on a different route
func test_signal_generation() -> void:
	HenTest.clear_save_data()
	var save_data: HenSaveData = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
	save_data.add_signal()

	var signal_data: HenSaveSignal = save_data.signals.get(0)

	signal_data.name = 'my signal'

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('signal my_signal')