extends HenTestSuite


class CountingState extends HengoState:
	var enters: int = 0


	func enter() -> void:
		enters += 1


func test_the_flag_is_off_by_default() -> void:
	var state: HenSaveState = save_data.add_state(false)
	state.name = 'idle'

	assert_bool(state.can_reenter).is_false()
	assert_str(HenTest.get_all_code()).not_contains('set_reenterable')


func test_a_reenterable_state_is_listed_in_the_base() -> void:
	var state: HenSaveState = save_data.add_state(false)
	state.name = 'shoot'
	state.can_reenter = true

	assert_str(HenTest.get_all_code()).contains('_STATE_CONTROLLER.set_reenterable(["shoot"])')


func test_a_reenterable_sub_state_is_flagged_on_registration() -> void:
	var parent: HenSaveState = save_data.add_state(false)
	parent.name = 'combat'
	parent.add_sub_state(save_data)

	var sub: HenSaveState = parent.get_sub_states(save_data)[0]
	sub.name = 'swing'
	sub.can_reenter = true

	assert_str(HenTest.get_all_code()).contains('add_sub_state("swing", Swing.new(_p), true)')


func test_a_plain_sub_state_registers_without_the_flag() -> void:
	var parent: HenSaveState = save_data.add_state(false)
	parent.name = 'combat'
	parent.add_sub_state(save_data)

	var sub: HenSaveState = parent.get_sub_states(save_data)[0]
	sub.name = 'swing'

	assert_str(HenTest.get_all_code()).contains('add_sub_state("swing", Swing.new(_p))')


func test_a_state_does_not_run_again_when_it_is_already_running() -> void:
	var node: Node = auto_free(Node.new())
	var controller: HengoStateController = HengoStateController.new(node)
	var idle: CountingState = CountingState.new(node)

	controller.set_states({idle = idle})
	controller.change_state('idle')
	controller.change_state('idle')

	assert_int(idle.enters).is_equal(1)


func test_a_reenterable_state_runs_again() -> void:
	var node: Node = auto_free(Node.new())
	var controller: HengoStateController = HengoStateController.new(node)
	var idle: CountingState = CountingState.new(node)

	controller.set_states({idle = idle})
	controller.set_reenterable(['idle'])
	controller.change_state('idle')
	controller.change_state('idle')

	assert_int(idle.enters).is_equal(2)


func test_the_guard_only_blocks_the_state_that_is_running() -> void:
	var node: Node = auto_free(Node.new())
	var controller: HengoStateController = HengoStateController.new(node)
	var idle: CountingState = CountingState.new(node)
	var run: CountingState = CountingState.new(node)

	controller.set_states({idle = idle, run = run})
	controller.change_state('idle')
	controller.change_state('run')
	controller.change_state('idle')

	assert_int(idle.enters).is_equal(2)
	assert_int(run.enters).is_equal(1)


# a blocked call must leave previous_state_name alone, or go_back lands on the
# state that is already running
func test_a_blocked_call_does_not_become_the_state_to_go_back_to() -> void:
	var node: Node = auto_free(Node.new())
	var controller: HengoStateController = HengoStateController.new(node)
	var idle: CountingState = CountingState.new(node)
	var run: CountingState = CountingState.new(node)

	controller.set_states({idle = idle, run = run})
	controller.change_state('idle')
	controller.change_state('run')
	controller.change_state('run')
	controller.go_back()

	assert_object(controller.current_state).is_same(idle)


func test_a_sub_state_does_not_run_again_when_it_is_already_running() -> void:
	var node: Node = auto_free(Node.new())
	var parent: HengoState = HengoState.new(node)
	var swing: CountingState = CountingState.new(node)

	parent.add_sub_state('swing', swing)
	parent.change_sub_state('swing')
	parent.change_sub_state('swing')

	assert_int(swing.enters).is_equal(1)


func test_a_reenterable_sub_state_runs_again() -> void:
	var node: Node = auto_free(Node.new())
	var parent: HengoState = HengoState.new(node)
	var swing: CountingState = CountingState.new(node)

	parent.add_sub_state('swing', swing, true)
	parent.change_sub_state('swing')
	parent.change_sub_state('swing')

	assert_int(swing.enters).is_equal(2)
