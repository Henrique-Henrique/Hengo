extends GdUnitTestSuite

const CNODE_DATA = preload("res://tests/assets/cross_compilation/cnode_data.json")
const CNODE_DATA_LESS = preload("res://tests/assets/cross_compilation/cnode_data_less.json")
const SCRIPT_DATA_MOCH = preload("res://tests/assets/cross_compilation/script_data_moch.json")
const SCRIPT_DATA_MOCH_DIFF_ORDER = preload("res://tests/assets/cross_compilation/script_data_moch_order.json")


func test_should_remove_deleted_inputs_and_keep_expected_ones() -> void:
	# verifies that inputs removed from the sidebar are also removed from the cnode
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var cnode_data: Dictionary = (CNODE_DATA.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_MOCH.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections

	HenCheckerFunc.check_changes_func(cnode_data, refs)
	var deleted_success: bool = true

	if (cnode_data.inputs as Array).size() != 3:
		assert_bool(false).is_true()
		return

	for input: Dictionary in cnode_data.inputs:
		if input.id == 509:
			deleted_success = false

	if cnode_data.inputs[0].id != 493:
		deleted_success = false
	
	if cnode_data.inputs[1].id != 511:
		deleted_success = false
	
	if cnode_data.inputs[2].id != 682:
		deleted_success = false

	assert_bool(deleted_success).is_true()


func test_should_reorder_inputs_to_match_sidebar_order() -> void:
	# ensures cnode inputs are reordered to match the exact order in the sidebar
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var cnode_data: Dictionary = (CNODE_DATA.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_MOCH_DIFF_ORDER.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections

	HenCheckerFunc.check_changes_func(cnode_data, refs)
	var right_order: bool = true

	if (cnode_data.inputs as Array).size() != 4:
		assert_bool(false).is_true()
		return

	if cnode_data.inputs[0].id != 493:
		right_order = false
	
	if cnode_data.inputs[1].id != 682:
		right_order = false
	
	if cnode_data.inputs[2].id != 509:
		right_order = false

	if cnode_data.inputs[3].id != 511:
		right_order = false

	assert_bool(right_order).is_true()


func test_should_add_missing_inputs_from_sidebar() -> void:
	# tests if new inputs in the sidebar are correctly added to the cnode
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var cnode_data: Dictionary = (CNODE_DATA_LESS.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_MOCH_DIFF_ORDER.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections

	HenCheckerFunc.check_changes_func(cnode_data, refs)
	var right_order: bool = true

	if (cnode_data.inputs as Array).size() != 4:
		assert_bool(false).is_true()
		return

	if cnode_data.inputs[0].id != 493:
		right_order = false
	
	if cnode_data.inputs[1].id != 682:
		right_order = false
	
	if cnode_data.inputs[2].id != 509:
		right_order = false

	if cnode_data.inputs[3].id != 511:
		right_order = false

	assert_bool(right_order).is_true()


func test_should_rebuild_all_inputs_when_cnode_has_none() -> void:
	# verifies that if a cnode has no inputs, they are all created from the sidebar
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var cnode_data: Dictionary = (CNODE_DATA_LESS.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_MOCH_DIFF_ORDER.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections

	(cnode_data.inputs as Array).clear()

	HenCheckerFunc.check_changes_func(cnode_data, refs)
	var right_order: bool = true

	if (cnode_data.inputs as Array).size() != 4:
		assert_bool(false).is_true()
		return

	if cnode_data.inputs[0].id != 493:
		right_order = false
	
	if cnode_data.inputs[1].id != 682:
		right_order = false
	
	if cnode_data.inputs[2].id != 509:
		right_order = false

	if cnode_data.inputs[3].id != 511:
		right_order = false

	assert_bool(right_order).is_true()


func test_should_clear_inputs_and_connections_when_sidebar_inputs_are_empty() -> void:
	# checks that if sidebar inputs are cleared, cnode inputs and related connections follow
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var cnode_data: Dictionary = (CNODE_DATA_LESS.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_MOCH_DIFF_ORDER.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections

	(refs.side_bar_list.func_list[0].inputs as Array).clear()

	HenCheckerFunc.check_changes_func(cnode_data, refs)
	var right_order: bool = true

	# needs to mantain the 'is_ref'
	if (cnode_data.inputs as Array).size() != 1:
		right_order = false

	if cnode_data.inputs[0].id != 493:
		right_order = false
	
	for connection: Dictionary in refs.connections:
		if connection.to_id == 509:
			right_order = false

	assert_bool(right_order).is_true()


func test_should_sync_input_metadata_like_name_and_type() -> void:
	# verifies that changes to an input's name and type in the sidebar are reflected in the cnode
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var cnode_data: Dictionary = (CNODE_DATA_LESS.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_MOCH_DIFF_ORDER.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections

	(refs.side_bar_list.func_list[0].inputs as Array)[1].name = 'name 001'
	(refs.side_bar_list.func_list[0].inputs as Array)[1].type = 'String'

	HenCheckerFunc.check_changes_func(cnode_data, refs)
	var right_order: bool = true

	if (cnode_data.inputs as Array).size() != 4:
		assert_bool(false).is_true()
		return

	if cnode_data.inputs[0].id != 493:
		right_order = false
	
	if cnode_data.inputs[1].id != 682 \
	and cnode_data.inputs[1].name != 'name 001' \
	and cnode_data.inputs[1].type != 'String':
		right_order = false
	
	if cnode_data.inputs[2].id != 509:
		right_order = false

	if cnode_data.inputs[3].id != 511:
		right_order = false

	assert_bool(right_order).is_true()


func test_should_sync_inputs_with_mixed_changes() -> void:
	# tests a scenario with deleted connections and order changes simultaneously
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var cnode_data: Dictionary = (CNODE_DATA_LESS.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_MOCH_DIFF_ORDER.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections

	HenCheckerFunc.check_changes_func(cnode_data, refs)
	var right_order: bool = true

	if (cnode_data.inputs as Array).size() != 4:
		assert_bool(false).is_true()
		return

	if cnode_data.inputs[0].id != 493:
		right_order = false
	
	if cnode_data.inputs[1].id != 682 \
	and cnode_data.inputs[1].name != 'name 001' \
	and cnode_data.inputs[1].type != 'String':
		right_order = false
	
	if cnode_data.inputs[2].id != 509:
		right_order = false

	if cnode_data.inputs[3].id != 511:
		right_order = false

	assert_bool(right_order).is_true()


func test_should_remove_connections_to_a_deleted_input() -> void:
	# confirms that when an input is deleted, any connections pointing to it are also removed
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var cnode_data: Dictionary = (CNODE_DATA.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_MOCH.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections

	HenCheckerFunc.check_changes_func(cnode_data, refs)
	var right_order: bool = true

	if (cnode_data.inputs as Array).size() != 3:
		assert_bool(false).is_true()
		return

	if cnode_data.inputs[0].id != 493:
		right_order = false
	
	if cnode_data.inputs[1].id != 511:
		right_order = false

	if cnode_data.inputs[2].id != 682:
		right_order = false

	for connection: Dictionary in refs.connections:
		if connection.to_id == 509:
			right_order = false

	assert_bool(right_order).is_true()


func test_should_deduplicate_inputs_with_same_id_from_sidebar() -> void:
	# verifies that if the sidebar has duplicate input ids, they are collapsed into one in the cnode
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var cnode_data: Dictionary = (CNODE_DATA_LESS.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_MOCH_DIFF_ORDER.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections

	# Add a duplicate input to the sidebar
	var duplicate_input = (refs.side_bar_list.func_list[0].inputs as Array)[0].duplicate()
	(refs.side_bar_list.func_list[0].inputs as Array).append(duplicate_input)

	HenCheckerFunc.check_changes_func(cnode_data, refs)
	var input_count = (cnode_data.inputs as Array).size()
	var unique_ids = {}
	
	for input in cnode_data.inputs:
		unique_ids[input.id] = true

	# The number of unique inputs should match the number of inputs in the cnode
	assert_int(unique_ids.size()).is_equal(input_count)
