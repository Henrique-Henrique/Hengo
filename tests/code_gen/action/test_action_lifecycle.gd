extends HenActionTestSuite

# covers where an action lands in the generated script: the lifecycle phase it
# runs in, its order inside that phase and the macro body it resolves to.

const FIX_RAW: String = 'res://tests/fixtures/action_raw.gd'


# --- lifecycle phases -------------------------------------------------------


func test_action_runs_in_update() -> void:
	_add_action(_register(FIX_PHASES), &'update')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('class StateTest extends HengoState:\n\tfunc update(delta) -> void:\n\t\tsuper(delta)\n\t\ttest_update("hi")')


# enter has no base method, so it must NOT call super()
func test_action_runs_in_enter_without_super() -> void:
	_add_action(_register(FIX_PHASES), &'enter')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('func enter() -> void:\n\t\ttest_enter("hi")')


# exit MUST call super() — HengoState.exit tears down current_sub_state
func test_action_runs_in_exit_with_super() -> void:
	_add_action(_register(FIX_PHASES), &'exit')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('func exit() -> void:\n\t\tsuper()\n\t\ttest_exit("hi")')


func test_actions_split_across_phases() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)
	_add_action(macro, &'enter')
	_add_action(macro, &'update')
	_add_action(macro, &'exit')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('func enter() -> void:\n\t\ttest_enter("hi")')
	assert_str(code).contains('func update(delta) -> void:\n\t\tsuper(delta)\n\t\ttest_update("hi")')
	assert_str(code).contains('func exit() -> void:\n\t\tsuper()\n\t\ttest_exit("hi")')


# --- ordering ---------------------------------------------------------------


# emission follows the list order inside a phase, so reordering rewrites the body
func test_actions_emit_in_list_order() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)

	for value: String in ['a', 'b', 'c']:
		_add_action(macro, &'update').inputs[0].default_value = value

	assert_str(HenTest.get_all_code()).contains('test_update("a")\n\t\ttest_update("b")\n\t\ttest_update("c")')


func test_reorder_moves_action_inside_phase() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)
	var actions: Array[HenSaveAction] = []

	for value: String in ['a', 'b', 'c']:
		var action: HenSaveAction = _add_action(macro, &'update')
		action.inputs[0].default_value = value
		actions.append(action)

	var moved: Array = HenActionsPanel.reorder(save_data.get_state_actions(state.id), actions[2], &'update', 0)
	save_data.set_state_actions(state.id, moved)

	assert_str(HenTest.get_all_code()).contains('test_update("c")\n\t\ttest_update("a")\n\t\ttest_update("b")')


# a move across phases changes where the line is emitted, not just its position
func test_reorder_moves_action_to_another_phase() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)
	var action: HenSaveAction = _add_action(macro, &'update')

	action.phase = &'enter'
	save_data.set_state_actions(state.id, HenActionsPanel.reorder(save_data.get_state_actions(state.id), action, &'enter', 0))

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('func enter() -> void:\n\t\ttest_enter("hi")')
	assert_str(code).not_contains('test_update(')


# dropping below a row above the dragged one still lands right under that row
func test_drop_index_ignores_the_dragged_action() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)
	var first: HenSaveAction = _add_action(macro, &'update')
	var second: HenSaveAction = _add_action(macro, &'update')
	var third: HenSaveAction = _add_action(macro, &'update')

	var actions: Array = save_data.get_state_actions(state.id)

	assert_int(HenActionsPanel.drop_index(actions, first, third, true)).is_equal(0)
	assert_int(HenActionsPanel.drop_index(actions, first, third, false)).is_equal(1)
	assert_int(HenActionsPanel.drop_index(actions, second, third, false)).is_equal(2)

	# a drop onto a row of another phase counts inside that phase only
	second.phase = &'enter'
	assert_int(HenActionsPanel.drop_index(actions, second, third, true)).is_equal(0)


# the flat list is normalized to the order codegen emits the phases in
func test_reorder_keeps_phases_in_run_order() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)
	var exit_action: HenSaveAction = _add_action(macro, &'exit')
	var enter_action: HenSaveAction = _add_action(macro, &'enter')

	var ordered: Array = HenActionsPanel.reorder(save_data.get_state_actions(state.id), enter_action, &'enter', 0)

	assert_array(ordered).is_equal([enter_action, exit_action])


# a state with no actions must stay empty (no stray lifecycle methods)
func test_state_without_actions_stays_empty() -> void:
	var code: String = HenTest.get_all_code()

	assert_str(code).contains('class StateTest extends HengoState:\n\tpass')


# --- macro body resolution --------------------------------------------------


# a macro with no flow inputs still works on update via its _process override
func test_action_falls_back_to_process_body_on_update() -> void:
	_add_action(_register(FIX_PROCESS), &'update')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('test_process(90')


# never drop silently: a phase the macro has no body for leaves a visible marker
func test_action_without_phase_body_emits_marker() -> void:
	_add_action(_register(FIX_PROCESS), &'enter')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('has no enter body')


# a raw input is a code fragment: emitted verbatim while its quoted twin isn't
func test_raw_input_is_not_quoted() -> void:
	var action: HenSaveAction = _add_action(_register(FIX_RAW), &'update')
	action.inputs[0].default_value = '_ref.queue_free()'
	action.inputs[1].default_value = '_ref.queue_free()'

	var code: String = HenTest.get_all_code()

	assert_str(code).contains("test_raw(_ref.queue_free(), '_ref.queue_free()')")


# --- physics phase ----------------------------------------------------------


# the fixed tick is where a body must be moved; super(delta) propagates to the sub-state
func test_action_runs_in_physics_with_super() -> void:
	HenScriptMacroLoader.load_native_actions()
	save_data.identity.type = 'CharacterBody2D'

	_add_action(HenActionsPanel.find_macro(&'move_and_slide'), &'physics')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('func physics(delta) -> void:\n\t\tsuper(delta)\n\t\t_ref.move_and_slide()')


# the macro names the phase a new action lands on, and it still has to declare a body
func test_default_phase_follows_the_macro_hint() -> void:
	HenScriptMacroLoader.load_native_actions()

	assert_str(str(HenSaveAction.default_phase(HenActionsPanel.find_macro(&'move_and_slide')))).is_equal('physics')
	assert_str(str(HenSaveAction.default_phase(HenActionsPanel.find_macro(&'wait')))).is_equal('update')
	assert_str(str(HenSaveAction.default_phase(HenActionsPanel.find_macro(&'print_value')))).is_equal('update')

	var phases: Array = HenSaveAction.supported_phases(HenActionsPanel.find_macro(&'move_and_slide'))

	assert_array(phases).contains([&'physics', &'update'])


# an action saved before the physics phase existed must keep compiling
func test_physics_macro_still_runs_on_update() -> void:
	HenScriptMacroLoader.load_native_actions()
	save_data.identity.type = 'CharacterBody2D'

	_add_action(HenActionsPanel.find_macro(&'move_and_slide'), &'update')

	assert_str(HenTest.get_all_code()).contains('func update(delta) -> void:\n\t\tsuper(delta)\n\t\t_ref.move_and_slide()')
