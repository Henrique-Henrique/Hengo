extends HenTestSuite

# the start flag is exclusive per script: deserializing a state from another
# script fires the same setter and must not clear the open script's flags


func test_start_is_exclusive_between_siblings() -> void:
	var first: HenSaveState = save_data.add_state(false)
	var second: HenSaveState = save_data.add_state(false)

	first.start = true
	second.start = true

	assert_bool(first.start).is_false()
	assert_bool(second.start).is_true()


func test_foreign_state_does_not_clear_start() -> void:
	var state: HenSaveState = save_data.add_state(false)
	state.name = 'idle'
	state.start = true

	# same shape a disk load produces: a state that belongs to no open script
	var foreign: HenSaveState = HenSaveState.new()
	foreign.name = 'foreign start'
	foreign.start = true

	assert_bool(state.start).is_true()


func test_batch_validation_flags_missing_start_state() -> void:
	save_data.add_state(false)

	var errors: Array[String] = HenSaveAll.new()._validate_routes(save_data, [])

	assert_array(errors).contains(['No start state defined. Mark one state as the start state.'])


func test_batch_validation_passes_with_start_state() -> void:
	var state: HenSaveState = save_data.add_state(false)
	state.start = true

	assert_array(HenSaveAll.new()._validate_routes(save_data, [])).is_empty()
	# a script without states never needs one
	assert_array(HenSaveAll.new()._validate_routes(HenSaveData.new(), [])).is_empty()


func test_generated_code_keeps_start_state() -> void:
	var state: HenSaveState = save_data.add_state(false)
	state.name = 'idle'
	state.start = true

	var foreign: HenSaveState = HenSaveState.new()
	foreign.start = true

	assert_str(HenTest.get_all_code()).contains('change_state("idle")')
