extends GdUnitTestSuite

#
#
#
#
#
#

# Helper function that sets up and returns a basic signal configuration for testing
func base_signal() -> HenSignalCallbackData:
	HenTest.set_global_config()

	# Initialize a new signal and configure it with default test parameters
	HenGlobal.SIDE_BAR_LIST.type = HenSideBar.AddType.SIGNAL_CALLBACK
	HenGlobal.SIDE_BAR_LIST.add()

	var signal_data: HenSignalCallbackData = HenGlobal.SIDE_BAR_LIST.signal_callback_list[0]
	signal_data.name = 'my_signal'
	signal_data.set_signal_params('BaseButton', 'toggled')

	return signal_data


# Tests generation of an empty signal handler function with correct signature
func test_generates_empty_signal_handler() -> void:
	base_signal()

	var script_data: HenScriptData = HenSaver.generate_script_data()
	var code: String = HenCodeGeneration.get_code(script_data)

	var expected_code = '\nfunc _on_my_signal_signal_(toggled_on):\n\tpass'
	assert_bool(code.contains(expected_code)).is_true()


# Tests signal handler generation with a connected void function call
func test_generates_signal_handler_with_flow_connection() -> void:
	var signal_data: HenSignalCallbackData = base_signal()
	# Create a virtual node for a void function call
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_void',
		sub_type = HenVirtualCNode.SubType.VOID,
		inputs = [],
		route = signal_data.route
	})
	
	signal_data.signal_enter.add_flow_connection(0, 0, vc).add()

	var script_data: HenScriptData = HenSaver.generate_script_data()
	var code: String = HenCodeGeneration.get_code(script_data)

	var expected_code = '\nfunc _on_my_signal_signal_(toggled_on):\n\ttest_void()'
	assert_bool(code.contains(expected_code)).is_true()


# Tests signal handler with data flow to a function parameter
func test_generates_signal_handler_with_data_connection() -> void:
	var signal_data: HenSignalCallbackData = base_signal()
	# Create a virtual function node that accepts parameters
	var vc_input: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_void',
		sub_type = HenVirtualCNode.SubType.FUNC,
		inputs = [ {id = 0, name = 'content', type = 'Variant'}],
		route = signal_data.route
	})
	
	# Connect signal output to function input
	signal_data.signal_enter.add_flow_connection(0, 0, vc_input).add()
	var output_param_id = signal_data.signal_enter.io.outputs[0].id
	vc_input.get_new_input_connection_command(0, output_param_id, signal_data.signal_enter).add()

	var script_data: HenScriptData = HenSaver.generate_script_data()
	var code: String = HenCodeGeneration.get_code(script_data)

	var expected_code = '\nfunc _on_my_signal_signal_(toggled_on):\n\ttest_void(toggled_on)'
	assert_bool(code.contains(expected_code)).is_true()


# Tests the code generation for a simple signal connection without extra parameters.
func test_generates_basic_signal_connection_code() -> void:
	var refs: HenTypeReferences = HenTypeReferences.new()
	var signal_data: HenSignalCallbackData = HenGlobal.SIDE_BAR_LIST.signal_callback_list[0]
	var dt: Dictionary = signal_data.get_connect_cnode_data()
	var script_data: HenScriptData = HenScriptData.new()

	dt.route = HenTest.get_base_route()
	HenFactorySignalCallback.get_signal_from_dict(signal_data.get_save(script_data), refs)

	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(dt)
	
	# Assert that the standard connection code is generated correctly
	var expected_code = 'connect("toggled", _on_my_signal_signal_)'
	assert_str(HenTest.construct_and_get_code(vc, [], refs)).is_equal(expected_code)


# Tests the code generation for a signal connection that uses 'bind'
func test_generates_signal_connection_code_with_bind() -> void:
	var refs: HenTypeReferences = HenTypeReferences.new()
	var signal_data: HenSignalCallbackData = HenGlobal.SIDE_BAR_LIST.signal_callback_list[0]
	var dt: Dictionary = signal_data.get_connect_cnode_data()
	var script_data: HenScriptData = HenScriptData.new()

	dt.route = HenTest.get_base_route()
	HenFactorySignalCallback.get_signal_from_dict(signal_data.get_save(script_data), refs)
	
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(dt)

	# Add an extra parameter to force the use of 'bind'
	var param: HenParamData = signal_data.create_param()
	param.name = 'a'

	# Assert that 'bind' is added to the connection call
	var expected_code = 'connect("toggled", _on_my_signal_signal_.bind(null))'
	assert_str(HenTest.construct_and_get_code(vc, [], refs)).is_equal(expected_code)


# Tests the code generation for disconnecting a signal connection
# Verifies that the disconnect() call is generated with the correct signal name and handler function
func test_disconnection_code() -> void:
	var refs: HenTypeReferences = HenTypeReferences.new()
	var signal_data: HenSignalCallbackData = HenGlobal.SIDE_BAR_LIST.signal_callback_list[0]
	var dt: Dictionary = signal_data.get_diconnect_cnode_data()
	var script_data: HenScriptData = HenScriptData.new()
	
	# Configure the route and process the signal data
	dt.route = HenTest.get_base_route()
	HenFactorySignalCallback.get_signal_from_dict(signal_data.get_save(script_data), refs)

	# Create a virtual node for the disconnect operation
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(dt)
	
	# Verify the generated code matches the expected disconnect() call
	assert_str(HenTest.construct_and_get_code(vc, [], refs)).is_equal('disconnect("toggled", _on_my_signal_signal_)')
