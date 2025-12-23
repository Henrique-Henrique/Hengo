extends GdUnitTestSuite


# helper function that sets up and returns a basic signal configuration for testing
func base_signal() -> HenSaveSignalCallback:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var first_signal_callback: HenSaveSignalCallback = HenSaveSignalCallback.create()

	first_signal_callback.name = 'my signal'
	first_signal_callback.type = &'BaseButton'
	first_signal_callback.signal_name = 'toggled_on'
	first_signal_callback.signal_name_to_code = 'toggled_on'

	var param4: HenSaveParam = HenSaveParam.create()

	param4.name = first_signal_callback.signal_name

	first_signal_callback.params.append(param4)
	global.SAVE_DATA.signals_callback.append(first_signal_callback)

	return first_signal_callback


# tests generation of an empty signal handler function with correct signature
func test_generates_empty_signal_handler() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	base_signal()

	var code_generation: HenCodeGeneration = Engine.get_singleton(&'CodeGeneration')
	var code: String = code_generation.get_code(global.SAVE_DATA)

	var expected_code = 'func _on_my_signal_signal_(toggled_on):\n\tpass'

	assert_bool(code.contains(expected_code)).is_true()


# tests signal handler generation with a connected void function call
func test_generates_signal_handler_with_flow_connection() -> void:
	var signal_data: HenSaveSignalCallback = base_signal()
	# Create a virtual node for a void function call
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_void',
		sub_type = HenVirtualCNode.SubType.VOID,
		inputs = [],
		route = signal_data.route
	})
	
	var signal_enter: HenVirtualCNode = HenGeneratorSignalCallback.search_signal_enter(signal_data)
	signal_enter.add_flow_connection(0, 0, vc).add()

	var code_generation: HenCodeGeneration = Engine.get_singleton(&'CodeGeneration')
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var code: String = code_generation.get_code(global.SAVE_DATA)

	var expected_code = '\nfunc _on_my_signal_signal_(toggled_on):\n\ttest_void()'

	assert_bool(code.contains(expected_code)).is_true()


# tests signal handler with data flow to a function parameter
func test_generates_signal_handler_with_data_connection() -> void:
	var code_generation: HenCodeGeneration = Engine.get_singleton(&'CodeGeneration')
	var signal_data: HenSaveSignalCallback = base_signal()
	# Create a virtual function node that accepts parameters
	var vc_input: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_func',
		sub_type = HenVirtualCNode.SubType.FUNC,
		inputs = [ {id = 0, name = 'content', type = 'Variant'}],
		route = signal_data.route
	})
	
	var signal_enter: HenVirtualCNode = HenGeneratorSignalCallback.search_signal_enter(signal_data)
	var global: HenGlobal = Engine.get_singleton(&'Global')
	# Connect signal output to function input
	signal_enter.add_flow_connection(0, 0, vc_input).add()
	var output_param_id = (signal_enter.res as HenSaveSignalCallback).get_outputs(signal_enter.sub_type)[0].id
	vc_input.get_new_input_connection_command(0, output_param_id, signal_enter).add()
	var code: String = code_generation.get_code(global.SAVE_DATA)

	var expected_code = '\nfunc _on_my_signal_signal_(toggled_on):\n\ttest_func(toggled_on)'
	assert_bool(code.contains(expected_code)).is_true()


# tests the code generation for a simple signal connection without extra parameters.
func test_generates_basic_signal_connection_code() -> void:
	var signal_data: HenSaveSignalCallback = base_signal()
	var dt: Dictionary = signal_data.get_connect_cnode_data()
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(dt)
	
	var vc_input: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_func',
		sub_type = HenVirtualCNode.SubType.FUNC,
		outputs = [ {id = 0, name = 'content', type = 'Variant'}],
		route = HenTest.get_base_route()
	})
	
	vc.get_new_input_connection_command(0, 0, vc_input).add()

	var expected_code = 'test_func().connect("toggled_on", _on_my_signal_signal_)'
	assert_str(HenVirtualCNodeCode.get_virtual_cnode_code(vc)).is_equal(expected_code)


# tests the code generation for a signal connection that uses 'bind'
func test_generates_signal_connection_code_with_bind() -> void:
	var signal_data: HenSaveSignalCallback = base_signal()
	var dt: Dictionary = signal_data.get_connect_cnode_data()
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(dt)
	
	var vc_input: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_func',
		sub_type = HenVirtualCNode.SubType.FUNC,
		outputs = [ {id = 0, name = 'content', type = 'Variant'}],
		route = HenTest.get_base_route()
	})
	
	vc.get_new_input_connection_command(0, 0, vc_input).add()

	var param: HenSaveParam = HenSaveParam.create()
	param.name = 'a'

	signal_data.bind_params.append(param)

	var expected_code = 'test_func().connect("toggled_on", _on_my_signal_signal_.bind(null))'
	assert_str(HenVirtualCNodeCode.get_virtual_cnode_code(vc)).is_equal(expected_code)


# tests the code generation for disconnecting a signal connection
# verifies that the disconnect() call is generated with the correct signal name and handler function
func test_disconnection_code() -> void:
	var signal_data: HenSaveSignalCallback = base_signal()
	var dt: Dictionary = signal_data.get_diconnect_cnode_data()
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(dt)
	
	var vc_input: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_func',
		sub_type = HenVirtualCNode.SubType.FUNC,
		outputs = [ {id = 0, name = 'content', type = 'Variant'}],
		route = HenTest.get_base_route()
	})
	
	vc.get_new_input_connection_command(0, 0, vc_input).add()

	assert_str(HenVirtualCNodeCode.get_virtual_cnode_code(vc)).is_equal('test_func().disconnect("toggled_on", _on_my_signal_signal_)')
