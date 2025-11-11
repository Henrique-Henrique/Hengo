extends GdUnitTestSuite

const CNODE_DATA_VAR = preload("res://tests/assets/cross_compilation/cnode_data_var.json")
const SCRIPT_DATA_MOCH = preload("res://tests/assets/cross_compilation/script_data_moch.json")


func test_should_remove_deleted_variables_and_keep_expected_ones() -> void:
	# verifies sidebar variable removal is reflected in cnode
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var cnode_data: Dictionary = (CNODE_DATA_VAR.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_MOCH.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections

	HenCheckerVar.check_changes_var(cnode_data, refs)

	assert_str(cnode_data.outputs[0].name).is_equal('my var 2')


func test_should_update_name_to_code() -> void:
	# verifies name_to_code is updated to expected
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var cnode_data: Dictionary = (CNODE_DATA_VAR.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_MOCH.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections

	HenCheckerVar.check_changes_var(cnode_data, refs)

	assert_str(cnode_data.name_to_code).is_equal('my var 2')


func test_should_update_variable_type() -> void:
	# verifies variable type is updated to expected
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var cnode_data: Dictionary = (CNODE_DATA_VAR.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_MOCH.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections

	HenCheckerVar.check_changes_var(cnode_data, refs)

	assert_str(cnode_data.outputs[0].type).is_equal('int')


func test_should_remove_connections_to_variable_output_on_change() -> void:
	# ensures that connections targeting the variable output are removed
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var cnode_data: Dictionary = (CNODE_DATA_VAR.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_MOCH.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections

	# add a connection that points to the variable output (id 913)
	(refs.connections as Array).append({
		from_id = 913,
		from_vc_id = 906,
		to_id = 9999,
		to_vc_id = 9999,
	})

	HenCheckerVar.check_changes_var(cnode_data, refs)

	var ok: bool = true
	for connection: Dictionary in refs.connections:
		if connection.from_id == 913:
			ok = false

	assert_bool(ok).is_true()
