extends HenActionTestSuite

# covers shipped action families whose emitted code is worth pinning: tween,
# control, random and get nearest.

# an animated action: its Finished branch runs from the tween signal
const FIX_TWEEN: String = 'res://addons/hengo/actions/tween/tween_move.gd'


# --- random family ----------------------------------------------------------


# the macro keeps the limits the bind source cannot express
func test_random_actions_emit_their_range() -> void:
	HenScriptMacroLoader.load_native_actions()

	var my_var: HenSaveVar = save_data.add_var(false)
	my_var.name = 'roll'
	my_var.type = 'int'

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'random_int'), &'update')
	action.output_bindings['result'] = HenUtils.bind_code_for_var(my_var)

	for param: HenSaveParam in action.inputs:
		match str(param.id):
			'min': param.default_value = 1
			'max': param.default_value = 6

	assert_str(HenTest.get_all_code()).contains('_ref.roll = randi_range(1, 6)')


# an unset in-place target must read as missing in the row, not as an empty literal
func test_preview_calls_out_an_unset_target() -> void:
	HenScriptMacroLoader.load_native_actions()

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'set_value'), &'update')

	assert_str(HenActionsPanel.value_preview(action)).contains('Target: not set')

	var my_var: HenSaveVar = save_data.add_var(false)
	my_var.name = 'hp'
	my_var.type = 'int'
	action.input_bindings['target'] = HenUtils.bind_code_for_var(my_var)

	assert_str(HenActionsPanel.value_preview(action)).contains('Target: hp')


# --- tween ------------------------------------------------------------------


# fire-and-forget: one create_tween() call animating the owner's own property
func test_tween_move_emits_a_property_tween() -> void:
	HenScriptMacroLoader.load_native_actions()

	_add_action(HenActionsPanel.find_macro(&'tween_move'), &'enter')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref.create_tween().tween_property(_ref, "position",')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# fade drives the sub-property of modulate, not a whole Color
func test_tween_fade_targets_modulate_alpha() -> void:
	HenScriptMacroLoader.load_native_actions()

	_add_action(HenActionsPanel.find_macro(&'tween_fade'), &'enter')

	assert_str(HenTest.get_all_code()).contains('tween_property(_ref, "modulate:a",')


# degrees are authored, radians are stored, so the value is wrapped on the way out
func test_tween_rotate_converts_degrees() -> void:
	HenScriptMacroLoader.load_native_actions()

	_add_action(HenActionsPanel.find_macro(&'tween_rotate'), &'enter')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('tween_property(_ref, "rotation", deg_to_rad(')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# per frame it starts itself again, so the phases are offered beside enter
func test_tween_offers_the_per_frame_phases() -> void:
	HenScriptMacroLoader.load_native_actions()

	var macro: HenSaveMacro = HenActionsPanel.find_macro(&'tween_move')

	# per frame it repeats itself, so the phases are offered; enter stays the default
	assert_array(HenSaveAction.supported_phases(macro)).is_equal([&'enter', &'update', &'physics'])
	assert_str(str(HenSaveAction.default_phase(macro))).is_equal('enter')


# --- control ----------------------------------------------------------------


# the target is a bound Control node; a node path reaches it without a variable
func test_set_text_writes_to_a_bound_node() -> void:
	HenScriptMacroLoader.load_native_actions()

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'set_text'), &'enter')
	action.input_bindings['target'] = HenUtils.BIND_PATH_PREFIX + 'HUD/Label'
	action.inputs[1].default_value = 'Score'

	var code: String = HenTest.get_all_code()

	assert_str(code).contains("_ref.get_node(\"HUD/Label\").text = 'Score'")

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# an unbound target has no node to write to, so it is refused instead of emitting `_ref..text`
func test_set_text_without_a_target_is_refused() -> void:
	HenScriptMacroLoader.load_native_actions()

	_add_action(HenActionsPanel.find_macro(&'set_text'), &'enter')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('must be bound to a variable or property')
	assert_str(code).not_contains('.text = ')


# the value setter drives a Range node the same duck-typed way
func test_set_control_value_writes_to_a_bound_node() -> void:
	HenScriptMacroLoader.load_native_actions()

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'set_control_value'), &'enter')
	action.input_bindings['target'] = HenUtils.BIND_PATH_PREFIX + 'HUD/Bar'
	action.inputs[1].default_value = 50.0

	assert_str(HenTest.get_all_code()).contains('_ref.get_node("HUD/Bar").value = 50')


# --- get nearest ------------------------------------------------------------


# the scan produces the closest node into a bound variable
func test_get_nearest_scans_the_group_into_a_variable() -> void:
	HenScriptMacroLoader.load_native_actions()

	var enemy: HenSaveVar = save_data.add_var(false)
	enemy.name = 'closest'
	enemy.type = 'Node2D'

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'get_nearest'), &'update')
	action.output_bindings['nearest'] = HenUtils.bind_code_for_var(enemy)

	var code: String = HenTest.get_all_code()

	assert_str(code).contains("_ref.get_tree().get_nodes_in_group('enemies')")
	assert_str(code).contains('_ref.closest = best_' + str(action.id))

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# a producer with its own for-loop nests inside a For Each without being treated
# as a stateful hook — the proof loops only made viable
func test_get_nearest_runs_inside_a_for_each() -> void:
	HenScriptMacroLoader.load_native_actions()

	var coll: HenSaveVar = save_data.add_var(false)
	coll.name = 'waves'
	coll.type = 'Array'
	var enemy: HenSaveVar = save_data.add_var(false)
	enemy.name = 'closest'
	enemy.type = 'Node2D'

	var loop: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'for_each'), &'update')
	loop.input_bindings['collection'] = HenUtils.bind_code_for_var(coll)

	var near: HenSaveAction = _nested(&'get_nearest')
	near.inputs = [HenSaveParam.create({name = 'Group', type = 'StringName', id = &'group', default_value = 'enemies'})]
	near.output_bindings['nearest'] = HenUtils.bind_code_for_var(enemy)
	loop.body_actions.append(near)

	var code: String = HenTest.get_all_code()

	assert_str(code).contains("get_nodes_in_group('enemies')")
	assert_str(code).not_contains('# hengo:')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# --- an animated action reporting its end -----------------------------------


# no branch wired: the plain one-liner it always was, with nothing declared, so
# the action still fits inside a loop body
func test_an_animated_action_stays_a_one_liner_without_its_branch() -> void:
	_add_action(_register(FIX_TWEEN), &'enter')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref.create_tween().tween_property(_ref, "position"')
	assert_str(code).not_contains('finished.connect')


# wired: the tween drives the transition from its own signal, and exit kills it
# so an animation left behind never transitions on its way out
func test_an_animated_action_branches_from_the_tween_signal() -> void:
	var target: HenSaveState = save_data.add_state(false)
	target.name = 'done'

	var action: HenSaveAction = _add_action(_register(FIX_TWEEN), &'enter')

	action.branches['finished'] = {state_id = target.id, label = ''}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('finished.connect(func() -> void:')
	assert_str(code).contains('_ref._STATE_CONTROLLER.change_state("done")')
	assert_str(code).contains('.kill()')


# an animated action on enter is the one line it always was: nothing declared,
# nothing torn down, so it stays the cheapest thing it can be
func test_an_animated_action_on_enter_declares_nothing() -> void:
	HenScriptMacroLoader.load_native_actions()

	_add_action(HenActionsPanel.find_macro(&'tween_move'), &'enter')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref.create_tween().tween_property(_ref, "position"')
	assert_str(code).not_contains('is_running()')
	assert_str(code).not_contains('.kill()')


# per frame it keeps the tween in a slot and only starts again once the last one
# ended: without the guard every frame would stack another animation
func test_an_animated_action_per_frame_keeps_its_tween() -> void:
	HenScriptMacroLoader.load_native_actions()

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'tween_move'), &'update')

	var code: String = HenTest.get_all_code()
	var slot: String = 'tween_' + str(action.id)

	assert_str(code).contains('var ' + slot + ': Tween = null')
	assert_str(code).contains('if ' + slot + ' == null or not ' + slot + '.is_running():')
	assert_str(code).contains(slot + ' = _ref.create_tween()')
	# the state gives it back instead of leaving it running for good
	assert_str(code).contains(slot + '.kill()')

	var script := GDScript.new()

	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# the Finished branch does not have to leave the state: steps on it run from the
# tween signal, which is what makes a one-off follow-up need no state of its own
func test_an_animated_action_runs_steps_on_finished() -> void:
	HenScriptMacroLoader.load_native_actions()

	var tween: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'tween_move'), &'enter')
	var step: HenSaveAction = _nested(&'print_value')

	step.inputs = [HenSaveParam.create({name = 'Value', type = 'Variant', id = &'value', default_value = 'done'})]
	tween.branch_actions['finished'] = [step] as Array[HenSaveAction]

	var code: String = HenTest.get_all_code()

	# steps alone arm the signal: without them the action stays the plain one-liner
	assert_str(code).contains('finished.connect(func() -> void:')
	assert_str(code).contains('print("done")')
	# _ready always starts the machine, so only the state body is checked
	assert_str(code.substr(code.find('class StateTest'))).not_contains('change_state')

	var script := GDScript.new()

	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# --- library wide -----------------------------------------------------------


# update and physics are the two per-frame ticks: an action offered on one runs
# the same on the other, and picking the wrong one used to hide it from the picker
func test_every_per_frame_action_runs_on_both_ticks() -> void:
	HenScriptMacroLoader.load_native_actions()

	var missing: Array[String] = []

	for macro: HenSaveMacro in (Engine.get_singleton(&'Global') as HenGlobal).action_macros:
		var phases: Array = HenSaveAction.supported_phases(macro)

		if phases.has(&'update') and not phases.has(&'physics'):
			missing.append(str(macro.id))

	assert_array(missing).override_failure_message(
		'these declare Update with no Physics body: ' + ', '.join(missing)
	).is_empty()
