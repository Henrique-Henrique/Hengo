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


# the first state is flagged on creation, so a script reaches this state only by
# having had the flag cleared
func test_batch_validation_flags_missing_start_state() -> void:
	save_data.add_state(false).start = false

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


# a script whose first state is not the start compiles as change_state(""), so the
# flag is set on creation instead of waiting for someone to remember it
func test_the_first_state_is_the_start() -> void:
	var first: HenSaveState = save_data.add_state(false)

	assert_bool(first.start).is_true()
	assert_array(HenSaveAll.new()._validate_routes(save_data, [])).is_empty()


func test_a_later_state_does_not_steal_the_start() -> void:
	var first: HenSaveState = save_data.add_state(false)
	var second: HenSaveState = save_data.add_state(false)

	assert_bool(first.start).is_true()
	assert_bool(second.start).is_false()


func test_the_first_sub_state_is_the_start_of_its_machine() -> void:
	var parent: HenSaveState = save_data.add_state(false)

	parent.add_sub_state(save_data)
	parent.add_sub_state(save_data)

	var subs: Array = parent.get_sub_states(save_data)

	assert_int(subs.size()).is_equal(2)
	assert_bool((subs[0] as HenSaveState).start).is_true()
	assert_bool((subs[1] as HenSaveState).start).is_false()


# the setter sweeps the siblings by looking for the list holding this state, so a
# flag set before the append finds no list and silently leaves the others alone
func test_the_start_of_a_new_state_is_exclusive() -> void:
	var first: HenSaveState = save_data.add_state(false)

	first.start = true

	var second: HenSaveState = save_data.add_state(false)

	second.start = true

	assert_bool(first.start).is_false()
	assert_bool(second.start).is_true()
