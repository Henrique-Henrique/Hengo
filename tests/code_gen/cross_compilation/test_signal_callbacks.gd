extends GdUnitTestSuite

const SIGNAL_CALLBACK = preload("res://tests/assets/cross_compilation/signal_callback.json")
const SCRIPT_DATA_COMPLETE = preload("res://tests/assets/script_data_complete.json")


func test_signal_name_changed() -> void:
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var signal_callback_data: Dictionary = (SIGNAL_CALLBACK.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_COMPLETE.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections
	
	HenCheckerSignal.check_changes_signal(signal_callback_data, refs)

	assert_bool(signal_callback_data.signal_name == script_data.side_bar_list.signal_list[0].name).is_true()
	assert_bool(signal_callback_data.signal_name_to_code == script_data.side_bar_list.signal_list[0].name).is_true()


func test_signal_size_changed() -> void:
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var signal_callback_data: Dictionary = (SIGNAL_CALLBACK.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_COMPLETE.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections
	
	HenCheckerSignal.check_changes_signal(signal_callback_data, refs)

	assert_int((signal_callback_data.outputs as Array).size()).is_equal((script_data.side_bar_list.signal_list[0].inputs as Array).size())
	assert_int((signal_callback_data.virtual_cnode_list[0].outputs as Array).size()).is_equal((script_data.side_bar_list.signal_list[0].inputs as Array).size())


func test_should_sync_signal_params() -> void:
	# ensures signal parameters are synchronized with the sidebar
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var signal_callback_data: Dictionary = (SIGNAL_CALLBACK.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_COMPLETE.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections
	
	HenCheckerSignal.check_changes_signal(signal_callback_data, refs)

	var signal_data: Dictionary = refs.side_bar_list.signal_list[0] as Dictionary
	var params: Array = signal_callback_data.params as Array
	var inputs: Array = signal_data.inputs as Array
	
	print(params)

	if params.size() != inputs.size():
		assert_bool(false).is_true()
		return
	
	var params_match: bool = true
	for i in range(inputs.size()):
		var param: Dictionary = params[i] as Dictionary
		var input: Dictionary = inputs[i] as Dictionary
		
		if param.name != input.name or param.type != input.type:
			params_match = false
			break

	assert_bool(params_match).is_true()


func test_should_sync_virtual_cnode_outputs() -> void:
	# ensures virtual cnode outputs are synchronized with signal parameters
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var signal_callback_data: Dictionary = (SIGNAL_CALLBACK.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_COMPLETE.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections

	HenCheckerSignal.check_changes_signal(signal_callback_data, refs)

	var vcnode: Dictionary = (signal_callback_data.virtual_cnode_list as Array)[0] as Dictionary
	var signal_data: Dictionary = (refs.side_bar_list.signal_list as Array)[0] as Dictionary
	var vcnode_outputs: Array = vcnode.outputs as Array
	var inputs: Array = signal_data.inputs as Array

	if vcnode_outputs.size() != inputs.size():
		assert_bool(false).is_true()
		return
	
	var outputs_match: bool = true
	for i in range(inputs.size()):
		var output: Dictionary = vcnode_outputs[i] as Dictionary
		var param: Dictionary = inputs[i] as Dictionary
		
		if output.name != param.name or output.type != param.type or output.ref_id != param.id:
			outputs_match = false
			break
	
	assert_bool(outputs_match).is_true()


func test_should_handle_empty_params() -> void:
	# ensures the function handles signals with no parameters
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var signal_callback_data: Dictionary = (SIGNAL_CALLBACK.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_COMPLETE.get_data() as Dictionary).duplicate(true))

	script_data.side_bar_list.signal_list[0].inputs = []
	
	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections

	HenCheckerSignal.check_changes_signal(signal_callback_data, refs)

	var params: Array = signal_callback_data.params as Array
	assert_bool(params.is_empty()).is_true()
	
	var vcnode: Dictionary = (signal_callback_data.virtual_cnode_list as Array)[0] as Dictionary
	var vcnode_outputs: Array = vcnode.outputs as Array
	assert_bool(vcnode_outputs.is_empty()).is_true()


func test_should_remove_connections_to_deleted_outputs() -> void:
	# ensures connections to deleted outputs are removed
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var signal_callback_data: Dictionary = (SIGNAL_CALLBACK.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_COMPLETE.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections

	var vcnode: Dictionary = (signal_callback_data.virtual_cnode_list as Array)[0] as Dictionary
	var test_connection = {
		from_vc_id = vcnode.id,
		from_id = 999, # non-existent output ID
		to_vc_id = 123,
		to_id = 456
	}
	refs.connections.append(test_connection)
	
	var original_connections_count = refs.connections.size()

	HenCheckerSignal.check_changes_signal(signal_callback_data, refs)

	assert_bool(refs.connections.size() > 0).is_true()
	assert_bool(refs.connections.size() <= original_connections_count).is_true()
	
	var connection_found = false
	for conn in refs.connections:
		if conn.from_id == 999:
			connection_found = true
			break
	
	assert_bool(connection_found).is_false()


func test_should_preserve_valid_connections() -> void:
	# ensures valid connections are preserved
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var signal_callback_data: Dictionary = (SIGNAL_CALLBACK.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_COMPLETE.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections

	var vcnode: Dictionary = (signal_callback_data.virtual_cnode_list as Array)[0] as Dictionary
	
	# first call check_changes_signal to ensure outputs are created
	HenCheckerSignal.check_changes_signal(signal_callback_data, refs)
	
	var vcnode_outputs: Array = vcnode.outputs as Array
	if not vcnode_outputs.is_empty():
		var valid_output_id = vcnode_outputs[0].id
		var valid_connection = {
			from_vc_id = vcnode.id,
			from_id = valid_output_id, # existing output ID
			to_vc_id = 123,
			to_id = 456
		}
		refs.connections.append(valid_connection)
		
		# call check_changes_signal again to process the new connection
		HenCheckerSignal.check_changes_signal(signal_callback_data, refs)

		assert_bool(refs.connections.size() > 0).is_true()
		
		var all_connections_valid = true
		for conn in refs.connections:
			if conn.from_vc_id == vcnode.id:
				var output_exists = false
				if vcnode.has('outputs'):
					for output in vcnode.outputs:
						if output.id == conn.from_id:
							output_exists = true
							break
				if not output_exists:
					all_connections_valid = false
					break
		
		assert_bool(all_connections_valid).is_true()


func test_should_handle_vcnode_without_outputs() -> void:
	# ensures the function handles virtual cnodes without outputs
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var signal_callback_data: Dictionary = (SIGNAL_CALLBACK.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_COMPLETE.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections

	var vcnode: Dictionary = (signal_callback_data.virtual_cnode_list as Array)[0] as Dictionary
	vcnode.erase('outputs')
	
	var test_connection = {
		from_vc_id = vcnode.id,
		from_id = 999,
		to_vc_id = 123,
		to_id = 456
	}
	refs.connections.append(test_connection)
	
	HenCheckerSignal.check_changes_signal(signal_callback_data, refs)

	assert_bool(refs.connections.size() > 0).is_true()
	
	var invalid_connections_exist = false
	for conn in refs.connections:
		if conn.from_vc_id == vcnode.id:
			invalid_connections_exist = true
			break
	
	assert_bool(invalid_connections_exist).is_false()
