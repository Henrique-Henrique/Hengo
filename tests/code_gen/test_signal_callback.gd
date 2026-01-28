extends HenTestSuite


var signal_callback_data: HenSaveSignalCallback


func before_test() -> void:
	super ()
	signal_callback_data = save_data.add_signals_callback(false)

	signal_callback_data.name = 'my signal'
	signal_callback_data.type = &'BaseButton'
	signal_callback_data.signal_name = 'toggled_on'
	signal_callback_data.signal_name_to_code = 'toggled_on'

	var param4: HenSaveParam = HenSaveParam.create()

	param4.name = signal_callback_data.signal_name

	signal_callback_data.params.append(param4)


# tests generation of an empty signal handler function with correct signature
func test_generates_empty_signal_handler() -> void:
	var expected_code = 'func _on_my_signal_signal_(toggled_on):\n\tpass'

	assert_bool(HenTest.get_all_code().contains(expected_code)).is_true()


# tests signal handler generation with a connected void function call
func test_generates_signal_handler_with_flow_connection() -> void:
	# Createavirtualnode for a void functioncall
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_void',
		sub_type = HenVirtualCNode.SubType.VOID,
		inputs = [],
		route = signal_callback_data.get_route(save_data)
	})
	
	var signal_enter: HenVirtualCNode = HenGeneratorSignalCallback.search_signal_enter(save_data, signal_callback_data)
	signal_enter.add_flow_connection(StringName('0'), StringName('0'), vc).add()

	var expected_code = '\nfunc _on_my_signal_signal_(toggled_on):\n\ttest_void()'

	assert_bool(HenTest.get_all_code().contains(expected_code)).is_true()


# # tests signal handler with data flow to a function parameter
func test_generates_signal_handler_with_data_connection() -> void:
	# Create a virtual function node that accepts parameters
	var vc_input: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_func',
		sub_type = HenVirtualCNode.SubType.FUNC,
		inputs = [ {id = 0, name = 'content', type = 'Variant'}],
		route = signal_callback_data.get_route(save_data)
	})
	
	var signal_enter: HenVirtualCNode = HenGeneratorSignalCallback.search_signal_enter(save_data, signal_callback_data)
	# Connect signal output to function input
	signal_enter.add_flow_connection(StringName('0'), StringName('0'), vc_input).add()
	var output_param_id = (signal_enter.get_res(save_data) as HenSaveSignalCallback).get_outputs(signal_enter.sub_type)[0].id
	vc_input.get_new_input_connection_command(StringName('0'), output_param_id, signal_enter).add()


	var expected_code = '\nfunc _on_my_signal_signal_(toggled_on):\n\ttest_func(toggled_on)'
	assert_bool(HenTest.get_all_code().contains(expected_code)).is_true()


# tests the code generation for a simple signal connection without extra parameters.
func test_generates_basic_signal_connection_code() -> void:
	var dt: Dictionary = signal_callback_data.get_connect_cnode_data()
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(dt)
	
	var vc_input: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_func',
		sub_type = HenVirtualCNode.SubType.FUNC,
		outputs = [ {id = 0, name = 'content', type = 'Variant'}],
		route = HenTest.get_base_route()
	})
	
	vc.get_new_input_connection_command(StringName('0'), StringName('0'), vc_input).add()

	var expected_code = 'test_func().connect("toggled_on", _on_my_signal_signal_)'
	assert_str(HenTest.get_vc_code(vc)).is_equal(expected_code)


# tests the code generation for a signal connection that uses 'bind'
func test_generates_signal_connection_code_with_bind() -> void:
	var dt: Dictionary = signal_callback_data.get_connect_cnode_data()
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(dt)
	
	var vc_input: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_func',
		sub_type = HenVirtualCNode.SubType.FUNC,
		outputs = [ {id = 0, name = 'content', type = 'Variant'}],
		route = HenTest.get_base_route()
	})
	
	vc.get_new_input_connection_command(StringName('0'), StringName('0'), vc_input).add()

	var param: HenSaveParam = HenSaveParam.create()
	param.name = 'a'

	signal_callback_data.bind_params.append(param)

	var expected_code = 'test_func().connect("toggled_on", _on_my_signal_signal_.bind(null))'
	assert_str(HenTest.get_vc_code(vc)).is_equal(expected_code)


# tests the code generation for disconnecting a signal connection
# verifies that the disconnect() call is generated with the correct signal name and handler function
func test_disconnection_code() -> void:
	var dt: Dictionary = signal_callback_data.get_diconnect_cnode_data()
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(dt)
	
	var vc_input: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_func',
		sub_type = HenVirtualCNode.SubType.FUNC,
		outputs = [ {id = 0, name = 'content', type = 'Variant'}],
		route = HenTest.get_base_route()
	})
	
	vc.get_new_input_connection_command(StringName('0'), StringName('0'), vc_input).add()

	assert_str(HenTest.get_vc_code(vc)).is_equal('test_func().disconnect("toggled_on", _on_my_signal_signal_)')
