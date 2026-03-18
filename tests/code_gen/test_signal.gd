extends HenTestSuite


var signal_data: HenSaveSignal


func before_test() -> void:
	super ()
	signal_data = save_data.add_signal(false)
	signal_data.name = 'my signal'


# Asserts a referenced call for nodes on a different route
func test_signal_generation() -> void:
	var code: String = HenTest.get_all_code()

	assert_str(code).contains('signal my_signal')