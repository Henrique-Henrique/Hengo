extends SceneTree

func _init():
	# Load the test script
	var test_script = load("res://tests/code_gen/side_bar/test_var.gd")
	var test_instance = test_script.new()
	
	# Run the specific test
	test_instance.test_variable_with_multiple_spaces()
	
	# Exit
	quit()
