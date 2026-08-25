extends HenActionTestSuite

# covers what the ui paints a broken step from: the same check the codegen runs
# to decide it drops an action


func test_an_unbound_lvalue_is_collected() -> void:
	HenScriptMacroLoader.load_native_actions()

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'set_value'), &'update')
	var errors: Array = HenGeneratorAction.collect_errors(save_data)

	assert_int(errors.size()).is_equal(1)
	assert_str(str(errors[0].reason)).contains('Target')
	assert_str(str(errors[0].action_id)).is_equal(str(action.id))
	assert_str(str(errors[0].state_id)).is_equal(str(state.id))
	assert_str(str(errors[0].description)).contains(state.name)


# the graph and the generated file must never disagree about why a step is gone
func test_the_collected_reason_is_the_one_left_in_the_code() -> void:
	HenScriptMacroLoader.load_native_actions()

	_add_action(HenActionsPanel.find_macro(&'set_value'), &'update')

	var errors: Array = HenGeneratorAction.collect_errors(save_data)
	var code: String = HenTest.get_all_code()

	assert_int(errors.size()).is_equal(1)
	assert_str(code).contains('unresolved: ' + str(errors[0].reason))


func test_a_break_outside_a_loop_is_collected() -> void:
	HenScriptMacroLoader.load_native_actions()

	_add_action(HenActionsPanel.find_macro(&'break_loop'), &'update')

	var errors: Array = HenGeneratorAction.collect_errors(save_data)

	assert_int(errors.size()).is_equal(1)
	assert_str(str(errors[0].reason)).contains('inside a loop')


# the sweep has to descend at the depth the emit path uses, or a valid break in a
# body reads as a loose one
func test_a_break_inside_a_loop_body_is_fine() -> void:
	HenScriptMacroLoader.load_native_actions()

	var loop: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'repeat'), &'update')

	loop.body_actions.append(HenSaveAction.create(HenActionsPanel.find_macro(&'break_loop')))

	assert_array(HenGeneratorAction.collect_errors(save_data)).is_empty()


func test_a_skipped_parent_hides_its_body() -> void:
	HenScriptMacroLoader.load_native_actions()

	var loop: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'for_each'), &'update')

	loop.body_actions.append(HenSaveAction.create(HenActionsPanel.find_macro(&'set_value')))

	var errors: Array = HenGeneratorAction.collect_errors(save_data)

	assert_int(errors.size()).is_equal(1)
	assert_str(str(errors[0].action_id)).is_equal(str(loop.id))


func test_a_muted_action_reports_nothing() -> void:
	HenScriptMacroLoader.load_native_actions()

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'set_value'), &'update')

	action.disabled = true

	assert_array(HenGeneratorAction.collect_errors(save_data)).is_empty()
