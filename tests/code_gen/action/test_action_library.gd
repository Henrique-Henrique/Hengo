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


func test_tween_move_emits_a_property_tween() -> void:
	HenScriptMacroLoader.load_native_actions()

	_add_action(HenActionsPanel.find_macro(&'tween_move'), &'enter')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('= _ref.create_tween()')
	assert_str(code).contains('.tween_property(_ref, "position",')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# a one-way animation stops where it was cancelled, which is a fine place to stop
func test_a_cancelled_one_way_tween_is_not_run_out() -> void:
	HenScriptMacroLoader.load_native_actions()

	_add_action(HenActionsPanel.find_macro(&'tween_move'), &'enter')

	assert_str(HenTest.get_all_code()).not_contains('custom_step')


# a swap left mid fade keeps the old track at a level nobody asked for, a fade and
# a typewriter leave the same kind of half state, so all of them are run out
func test_the_animated_actions_that_run_out_on_cancel() -> void:
	HenScriptMacroLoader.load_native_actions()

	for id: String in ['flash', 'camera_shake', 'play_music', 'type_text', 'fade_audio']:
		assert_bool(_tween_macro(id).finishes_on_cancel()).override_failure_message(id).is_true()

	for id: String in ['tween_move', 'tween_scale', 'tween_color', 'tween_property']:
		assert_bool(_tween_macro(id).finishes_on_cancel()).override_failure_message(id).is_false()


func _tween_macro(_id: String) -> HenActionTweenBase:
	var macro: HenSaveMacro = HenActionsPanel.find_macro(StringName(_id))

	return (load(macro.script_path) as GDScript).new() as HenActionTweenBase


# a round trip effect ends on the resting value, so cancelling it runs it out
# instead of parking the node on the flash color
func test_a_cancelled_flash_is_run_out_with_its_branch_muted() -> void:
	HenScriptMacroLoader.load_native_actions()

	_add_action(HenActionsPanel.find_macro(&'flash'), &'enter')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('finished.get_connections()')
	assert_str(code).contains('.custom_step(')
	assert_str(code).contains('.kill()')


# casting to a class the node is not yields null, not an error
func test_flash_guards_the_material_path_before_the_cast() -> void:
	HenScriptMacroLoader.load_native_actions()

	save_data.identity.type = 'Node3D'

	var once: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'flash'), &'enter')
	var every: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'flash'), &'update')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('if node_' + str(once.id) + ' is GeometryInstance3D:')
	assert_str(code).contains('if node_' + str(every.id) + ' is GeometryInstance3D:')
	# the kept slot stays outside the check, so the finish hook reads a declared name
	assert_str(code).contains('\n\t\tif flash_' + str(once.id) + ':')

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


# no branch wired: there is no end to report, so no signal is hooked
func test_an_animated_action_hooks_nothing_without_its_branch() -> void:
	_add_action(_register(FIX_TWEEN), &'enter')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('.tween_property(_ref, "position"')
	assert_str(code).not_contains('finished.connect')


# a loop starts one animation per iteration, so a single slot would only ever hold
# the last of them and the teardown would leave the others running
func test_an_animated_action_in_a_loop_keeps_every_tween() -> void:
	HenScriptMacroLoader.load_native_actions()

	var loop: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'repeat'), &'enter')

	loop.body_actions.append(_nested(&'tween_move'))

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('Array[Tween] = []')
	assert_str(code).contains('.append(')
	assert_str(code).contains('.clear()')
	assert_str(code).not_contains('# hengo:')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# finished fires from inside the tween's own step, and Tween refuses custom_step()
# from there, so the slot is released before the branch can leave the state
func test_a_finished_animation_releases_its_slot_before_the_branch() -> void:
	var target: HenSaveState = save_data.add_state(false)
	target.name = 'done'

	var action: HenSaveAction = _add_action(_register(FIX_TWEEN), &'enter')

	action.branches['finished'] = {state_id = target.id, label = ''}

	var code: String = HenTest.get_all_code()
	var connect_at: int = code.find('finished.connect(func() -> void:')
	var release_at: int = code.find(' = null', connect_at)
	var branch_at: int = code.find('change_state("done")', connect_at)

	assert_int(connect_at).is_greater(-1)
	assert_int(release_at).is_greater(connect_at)
	assert_int(branch_at).is_greater(release_at)


func test_a_finished_animation_in_a_loop_drops_itself_from_the_list() -> void:
	HenScriptMacroLoader.load_native_actions()

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'done'

	var loop: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'repeat'), &'enter')
	var mover: HenSaveAction = _nested(&'tween_move')

	mover.branches['finished'] = {state_id = target.id, label = ''}
	loop.body_actions.append(mover)

	assert_str(HenTest.get_all_code()).contains('.erase(')


# a branch runs at the depth its action does; counting it as a loop would declare
# the list while the body still assigns the single slot
func test_an_animated_action_in_a_branch_keeps_one_tween() -> void:
	HenScriptMacroLoader.load_native_actions()

	var gate: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'compare'), &'enter')

	gate.branch_actions['true'] = [_nested(&'tween_move')] as Array[HenSaveAction]

	var code: String = HenTest.get_all_code()

	assert_str(code).contains(': Tween = null')
	assert_str(code).not_contains('Array[Tween]')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# the per-frame guard asks whether the last animation ended, and one animation per
# item on every frame has no answer to that
func test_an_animated_action_per_frame_in_a_loop_is_refused() -> void:
	HenScriptMacroLoader.load_native_actions()

	var loop: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'repeat'), &'update')

	loop.body_actions.append(_nested(&'tween_move'))

	assert_str(HenTest.get_all_code()).contains('has to run on enter, not every frame')


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


# on enter the slot is kept and torn down like anywhere else, but the restart
# guard belongs to a per-frame phase and must not show up here
func test_an_animated_action_on_enter_keeps_its_tween_without_the_guard() -> void:
	HenScriptMacroLoader.load_native_actions()

	_add_action(HenActionsPanel.find_macro(&'tween_move'), &'enter')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('= _ref.create_tween()')
	assert_str(code).contains('.kill()')
	assert_str(code).not_contains('is_running()')


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
