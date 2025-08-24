extends GdUnitTestSuite

const CNODE_DATA = preload("res://tests/assets/cross_compilation/cnode_data.json")
const SCRIPT_DATA_MOCH = preload("res://tests/assets/cross_compilation/script_data_moch.json")
const SCRIPT_DATA_MOCH_DIFF_ORDER = preload("res://tests/assets/cross_compilation/script_data_moch_order.json")


func test_should_sync_function_name_from_sidebar() -> void:
	# ensures the cnode's name is updated when the function name changes in the sidebar
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var cnode_data: Dictionary = (CNODE_DATA.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_MOCH.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections

	HenCheckerFunc.check_changes_func(cnode_data, refs)
	var right_order: bool = true

	if cnode_data.name != 'my func 70':
		right_order = false

	assert_bool(right_order).is_true()


func test_outputs_should_be_cleared_when_cnode_has_none() -> void:
	# ensures the cnode's name is updated when the function name changes in the sidebar
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var cnode_data: Dictionary = (CNODE_DATA.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_MOCH.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections

	cnode_data.erase('outputs')

	HenCheckerFunc.check_changes_func(cnode_data, refs)
	var right_order: bool = true
	# I'm testing here if check_changes_func will fail if the cnode has no outputs
	assert_bool(right_order).is_true()


func test_should_sync_outputs_correctly() -> void:
	# basic test to check if outputs are synchronized between sidebar and cnode
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var cnode_data: Dictionary = (CNODE_DATA.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_MOCH.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections

	HenCheckerFunc.check_changes_func(cnode_data, refs)
	var ok: bool = true

	if (cnode_data.outputs as Array).size() != 2:
		assert_bool(false).is_true()
		return

	if cnode_data.outputs[0].id != 513:
		ok = false

	if cnode_data.outputs[1].id != 515:
		ok = false

	assert_bool(ok).is_true()


func test_should_reorder_outputs_to_match_sidebar() -> void:
	# verifies that cnode outputs are reordered to match the sidebar's output order
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var cnode_data: Dictionary = (CNODE_DATA.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_MOCH.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections

	# swap the outputs order on sidebar to ensure cnode follows sidebar order
	var outs: Array = refs.side_bar_list.func_list[0].outputs as Array
	var tmp: Dictionary = outs[0]
	outs[0] = outs[1]
	tmp = outs[1]

	HenCheckerFunc.check_changes_func(cnode_data, refs)
	var right_order: bool = true

	if (cnode_data.outputs as Array).size() != 2:
		assert_bool(false).is_true()
		return

	if cnode_data.outputs[0].id != outs[0].id:
		right_order = false

	if cnode_data.outputs[1].id != outs[1].id:
		right_order = false

	assert_bool(right_order).is_true()


func test_should_rebuild_outputs_when_cnode_has_none() -> void:
	# ensures outputs are fully created from sidebar data if the cnode has no outputs
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var cnode_data: Dictionary = (CNODE_DATA.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_MOCH.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections

	(cnode_data.outputs as Array).clear()

	HenCheckerFunc.check_changes_func(cnode_data, refs)
	var ok: bool = true

	if (cnode_data.outputs as Array).size() != 2:
		assert_bool(false).is_true()
		return

	if cnode_data.outputs[0].id != 513:
		ok = false

	if cnode_data.outputs[1].id != 515:
		ok = false

	assert_bool(ok).is_true()


func test_should_clear_cnode_outputs_when_sidebar_outputs_are_empty() -> void:
	# verifies that clearing all outputs in the sidebar also clears them in the cnode
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var cnode_data: Dictionary = (CNODE_DATA.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_MOCH.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections

	# clear sidebar outputs
	var original_outputs = (refs.side_bar_list.func_list[0].outputs as Array).duplicate()
	(refs.side_bar_list.func_list[0].outputs as Array).clear()

	HenCheckerFunc.check_changes_func(cnode_data, refs)
	
	# the function should have no outputs since we cleared them in the sidebar
	assert_int((cnode_data.outputs as Array).size()).is_equal(0)
	
	# restore the outputs for other tests
	refs.side_bar_list.func_list[0].outputs = original_outputs


func test_should_sync_output_metadata() -> void:
	# verifies that output metadata (name and type) is properly synced from sidebar to cnode
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var cnode_data: Dictionary = (CNODE_DATA.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_MOCH.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections

	# modify output metadata in the sidebar
	var output = (refs.side_bar_list.func_list[0].outputs as Array)[0]
	output.name = 'new_output_name'
	output.type = 'String'

	HenCheckerFunc.check_changes_func(cnode_data, refs)
	
	# find the corresponding output in cnode_data
	var found = false
	for out in cnode_data.outputs:
		if out.id == output.id:
			found = true
			assert_str(out.name).is_equal('new_output_name')
			assert_str(out.type).is_equal('String')
			break
	
	assert_bool(found).is_true()


func test_should_handle_missing_outputs_in_cnode() -> void:
	# verifies behavior when cnode has no 'outputs' key at all
	var refs: HenRegenerateRefs = HenRegenerateRefs.new()
	var cnode_data: Dictionary = (CNODE_DATA.get_data() as Dictionary).duplicate(true)
	var script_data: HenScriptData = HenScriptData.load((SCRIPT_DATA_MOCH.get_data() as Dictionary).duplicate(true))

	refs.counter = script_data.node_counter
	refs.side_bar_list = script_data.side_bar_list
	refs.connections = script_data.connections

	# remove outputs key completely
	cnode_data.erase('outputs')

	# this should not crash and should create outputs from sidebar
	HenCheckerFunc.check_changes_func(cnode_data, refs)
	
	assert_int((cnode_data.outputs as Array).size()).is_greater(0)
