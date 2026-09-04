extends HenTestSuite

# moving a state between machines: the lists, the is_sub_state flag and the start
# flags of both sides have to land together


func test_a_top_level_state_becomes_a_sub_state() -> void:
	var host: HenSaveState = save_data.add_state(false)
	var moved: HenSaveState = save_data.add_state(false)

	HenStateOps.apply_move(save_data, moved, host, false)

	assert_array(save_data.states).not_contains([moved])
	assert_array(host.get_sub_states(save_data)).contains([moved])
	assert_bool(moved.is_sub_state).is_true()


func test_a_sub_state_goes_back_to_the_top_level() -> void:
	var host: HenSaveState = save_data.add_state(false)

	host.add_sub_state(save_data)

	var moved: HenSaveState = host.get_sub_states(save_data)[0]

	HenStateOps.apply_move(save_data, moved, null, false)

	assert_array(save_data.states).contains([moved])
	assert_bool(moved.is_sub_state).is_false()
	assert_bool(save_data.sub_states.has(host.id)).is_false()


# the moved state was the start of its old machine, so the machine it leaves has
# to pick a new one and the machine it joins keeps its own
func test_the_old_machine_gets_a_new_start() -> void:
	var host: HenSaveState = save_data.add_state(false)
	var first: HenSaveState = save_data.add_state(false)
	var second: HenSaveState = save_data.add_state(false)

	first.start = true

	HenStateOps.apply_move(save_data, first, host, false)

	assert_bool(first.start).is_true()
	assert_bool(host.start).is_true()
	assert_bool(second.start).is_false()


func test_joining_a_machine_that_already_runs_does_not_steal_its_start() -> void:
	var host: HenSaveState = save_data.add_state(false)
	var moved: HenSaveState = save_data.add_state(false)

	host.add_sub_state(save_data)

	var resident: HenSaveState = host.get_sub_states(save_data)[0]

	moved.start = true
	HenStateOps.apply_move(save_data, moved, host, false)

	assert_bool(resident.start).is_true()
	assert_bool(moved.start).is_false()


func test_a_state_cannot_be_moved_into_its_own_sub_tree() -> void:
	save_data.add_state(false)

	var parent: HenSaveState = save_data.add_state(false)

	parent.add_sub_state(save_data)

	var child: HenSaveState = parent.get_sub_states(save_data)[0]

	assert_bool(HenStateOps.can_move(save_data, parent, child)).is_false()
	assert_bool(HenStateOps.can_move(save_data, parent, parent)).is_false()


func test_the_only_top_level_state_cannot_be_nested() -> void:
	var only: HenSaveState = save_data.add_state(false)

	only.add_sub_state(save_data)

	var child: HenSaveState = only.get_sub_states(save_data)[0]

	assert_bool(HenStateOps.can_move(save_data, only, child)).is_false()


func test_the_move_options_skip_self_the_sub_tree_and_the_current_parent() -> void:
	var host: HenSaveState = save_data.add_state(false)
	var other: HenSaveState = save_data.add_state(false)

	host.add_sub_state(save_data)

	var moved: HenSaveState = host.get_sub_states(save_data)[0]

	moved.add_sub_state(save_data)

	var names: Array = HenStateOps.move_options(save_data, moved).map(func(o: Dictionary) -> String: return str(o.name))

	assert_array(names).contains(['Script (top level)', other.name])
	assert_array(names).not_contains([host.name + ' / ' + moved.name])


func test_a_nested_option_reads_as_its_path() -> void:
	var host: HenSaveState = save_data.add_state(false)

	host.add_sub_state(save_data)

	var child: HenSaveState = host.get_sub_states(save_data)[0]

	assert_str(HenStateOps.path_label(save_data, child)).is_equal(host.name + ' / ' + child.name)


# the snapshot the history stores round trips the whole machine, flags included
func test_a_tree_snapshot_puts_the_state_back() -> void:
	var host: HenSaveState = save_data.add_state(false)
	var moved: HenSaveState = save_data.add_state(false)

	moved.start = true

	var before: Dictionary = HenStateOps.tree_snapshot(save_data)

	HenStateOps.apply_move(save_data, moved, host, false)

	assert_array(host.get_sub_states(save_data)).contains([moved])
	assert_bool(host.start).is_true()

	HenStateOps.apply_tree(save_data, before, false)

	assert_array(save_data.states).contains([moved])
	assert_bool(save_data.sub_states.has(host.id)).is_false()
	assert_bool(moved.is_sub_state).is_false()
	assert_bool(moved.start).is_true()
	assert_bool(host.start).is_false()


# a digest and not ==: two snapshots never compare equal, and an edit that
# changed nothing must not cost a ctrl+z that does nothing
func test_the_digest_only_moves_when_the_machine_does() -> void:
	var host: HenSaveState = save_data.add_state(false)
	var before: Dictionary = HenStateOps.tree_snapshot(save_data)

	assert_str(HenStateOps.tree_digest(HenStateOps.tree_snapshot(save_data))).is_equal(HenStateOps.tree_digest(before))

	HenStateOps.request_add_state(save_data, host, false)

	assert_str(HenStateOps.tree_digest(HenStateOps.tree_snapshot(save_data))).is_not_equal(HenStateOps.tree_digest(before))


func test_a_sub_state_takes_the_start_from_its_own_machine_only() -> void:
	var top: HenSaveState = save_data.add_state(false)

	top.add_sub_state(save_data)
	top.add_sub_state(save_data)

	var subs: Array = top.get_sub_states(save_data)

	HenStateOps.request_set_start(save_data, subs[1] as HenSaveState, false)

	assert_bool((subs[1] as HenSaveState).start).is_true()
	assert_bool((subs[0] as HenSaveState).start).is_false()
	assert_bool(top.start).is_true()


# the very first state of a script has to carry the start flag
func test_the_first_state_added_is_the_start() -> void:
	var created: HenSaveState = HenStateOps.request_add_state(save_data, null, false)

	assert_bool(created.start).is_true()
	assert_bool(created.is_base).is_true()


func test_a_sub_state_is_never_the_base() -> void:
	var host: HenSaveState = save_data.add_state(false)
	var created: HenSaveState = HenStateOps.request_add_state(save_data, host, false)

	assert_bool(created.start).is_true()
	assert_bool(created.is_base).is_false()


func test_the_base_state_cannot_be_nested() -> void:
	var base: HenSaveState = save_data.add_state(false)
	var host: HenSaveState = save_data.add_state(false)

	assert_bool(base.is_base).is_true()
	assert_bool(HenStateOps.can_move(save_data, base, host)).is_false()


# a script created from the panel already answers change_state on ready
func test_a_fresh_script_gets_a_base_state() -> void:
	var fresh: HenSaveData = HenSaveData.new()

	fresh.identity = HenSaveDataIdentity.create(&'fresh', &'Node', 'Fresh')
	fresh.counter = 1

	var base: HenSaveState = fresh.ensure_base_state()

	assert_str(base.name).is_equal(HenSaveState.BASE_NAME)
	assert_bool(base.start).is_true()
	assert_array(fresh.states).contains([base])


# a script written before the base existed keeps the state it starts on
func test_the_backfill_marks_the_state_that_starts() -> void:
	save_data.add_state(false)

	var second: HenSaveState = save_data.add_state(false)

	for state: HenSaveState in save_data.states:
		state.is_base = false

	second.start = true

	assert_object(save_data.ensure_base_state()).is_same(second)
