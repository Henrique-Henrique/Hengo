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


func test_should_sync_signal_params() -> void:
	# ensures signal parameters are synchronized with the sidebar
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var signal_callback_data: Dictionary = (SIGNAL_CALLBACK.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_COMPLETE.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections
	
	HenCheckerSignal.check_changes_signal(signal_callback_data, refs)

	# Verify params were synchronized
	var signal_data: Dictionary = refs.side_bar_list.signal_list[0] as Dictionary
	var params: Array = signal_callback_data.params as Array
	var inputs: Array = signal_data.inputs as Array
	
	# Check parameter count matches
	if params.size() != inputs.size():
		assert_bool(false).is_true()
		return
	
	# Check each parameter individually
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

	# Get the virtual cnode (should be the first one)
	var vcnode: Dictionary = (signal_callback_data.virtual_cnode_list as Array)[0] as Dictionary
	var signal_data: Dictionary = (refs.side_bar_list.signal_list as Array)[0] as Dictionary
	var vcnode_outputs: Array = vcnode.outputs as Array
	var inputs: Array = signal_data.inputs as Array

	# Verify outputs match signal parameters
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

	# Clear params in the signal data
	script_data.side_bar_list.signal_list[0].inputs = []
	
	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections

	HenCheckerSignal.check_changes_signal(signal_callback_data, refs)

	# Verify params were cleared
	var params: Array = signal_callback_data.params as Array
	assert_bool(params.is_empty()).is_true()
	
	# Verify virtual cnode outputs were cleared
	var vcnode: Dictionary = (signal_callback_data.virtual_cnode_list as Array)[0] as Dictionary
	var vcnode_outputs: Array = vcnode.outputs as Array
	assert_bool(vcnode_outputs.is_empty()).is_true()
