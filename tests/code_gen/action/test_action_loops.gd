extends HenActionTestSuite

# covers actions holding a body: nesting, indentation and what is refused
# inside a loop.

# a gating action: it holds a body and branches, both optional
const FIX_DO_N_TIMES: String = 'res://addons/hengo/actions/flow/do_n_times.gd'


# --- loops ------------------------------------------------------------------


# a For Each stores the item into a variable and runs its body indented under it
func test_for_each_body_emits_indented() -> void:
	HenScriptMacroLoader.load_native_actions()

	var coll: HenSaveVar = save_data.add_var(false)
	coll.name = 'enemies'
	coll.type = 'Array'
	var item: HenSaveVar = save_data.add_var(false)
	item.name = 'e'
	item.type = 'Variant'

	var loop: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'for_each'), &'update')
	loop.input_bindings['collection'] = HenUtils.bind_code_for_var(coll)
	var reader: HenSaveAction = HenSaveAction.create(HenActionsPanel.find_macro(&'set_value'))

	reader.input_bindings['target'] = HenUtils.bind_code_for_var(item)
	reader.input_wires['value'] = {action_id = StringName(str(loop.id)), output = &'item'}
	loop.body_actions.append(reader)

	var print_a: HenSaveAction = _nested(&'print_value')
	print_a.inputs = [HenSaveParam.create({name = 'Value', type = 'Variant', id = &'value'})]
	print_a.input_bindings['value'] = HenUtils.bind_code_for_var(item)
	loop.body_actions.append(print_a)

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('for __item_' + str(loop.id) + ' in _ref.enemies:')
	assert_str(code).contains('\t\t\t_ref.e = (__item_' + str(loop.id) + ')')
	assert_str(code).contains('\t\t\tprint(_ref.e)')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# a loop nested in a loop gets distinct locals and two indent levels
func test_nested_loops_have_distinct_locals() -> void:
	HenScriptMacroLoader.load_native_actions()

	var coll: HenSaveVar = save_data.add_var(false)
	coll.name = 'rows'
	coll.type = 'Array'

	var outer: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'for_each'), &'update')
	outer.input_bindings['collection'] = HenUtils.bind_code_for_var(coll)

	var inner: HenSaveAction = _nested(&'repeat')
	inner.inputs = [HenSaveParam.create({name = 'Times', type = 'int', id = &'times', default_value = 3})]
	outer.body_actions.append(inner)

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('\t\tfor __item_' + str(outer.id) + ' in _ref.rows:')
	assert_str(code).contains('\t\t\tfor __i_' + str(inner.id) + ' in 3:')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# an empty loop body still compiles: the for gets a pass after the index counter
func test_empty_loop_body_gets_pass() -> void:
	HenScriptMacroLoader.load_native_actions()

	var coll: HenSaveVar = save_data.add_var(false)
	coll.name = 'stuff'
	coll.type = 'Array'

	var loop: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'for_each'), &'update')
	loop.input_bindings['collection'] = HenUtils.bind_code_for_var(coll)

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('for __item_' + str(loop.id) + ' in _ref.stuff:\n\t\t\t__i_' + str(loop.id) + ' += 1\n\t\t\tpass')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# break and continue only make sense inside a loop
func test_break_outside_a_loop_is_refused() -> void:
	HenScriptMacroLoader.load_native_actions()

	_add_action(HenActionsPanel.find_macro(&'break_loop'), &'update')

	assert_str(HenTest.get_all_code()).contains('can only be used inside a loop')


func test_break_inside_a_loop_compiles() -> void:
	HenScriptMacroLoader.load_native_actions()

	var coll: HenSaveVar = save_data.add_var(false)
	coll.name = 'stuff'
	coll.type = 'Array'

	var loop: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'for_each'), &'update')
	loop.input_bindings['collection'] = HenUtils.bind_code_for_var(coll)
	loop.body_actions.append(_nested(&'break_loop'))

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('\t\t\tbreak')
	assert_str(code).not_contains('# hengo:')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# a delta-using action inside an enter-phase loop must not smuggle delta into enter()
func test_delta_action_in_enter_loop_is_refused() -> void:
	HenScriptMacroLoader.load_native_actions()
	save_data.identity.type = 'Node2D'

	var coll: HenSaveVar = save_data.add_var(false)
	coll.name = 'pts'
	coll.type = 'Array'
	var p: HenSaveVar = save_data.add_var(false)
	p.name = 'p'
	p.type = 'Vector2'

	var loop: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'for_each'), &'enter')
	loop.input_bindings['collection'] = HenUtils.bind_code_for_var(coll)

	var mover: HenSaveAction = _nested(&'move_towards')
	mover.inputs = [
		HenSaveParam.create({name = 'Target', type = 'Vector2', id = &'target'}),
		HenSaveParam.create({name = 'Speed', type = 'float', id = &'speed', default_value = 100.0})
	]
	mover.input_bindings['target'] = HenUtils.bind_code_for_var(p)
	loop.body_actions.append(mover)

	var code: String = HenTest.get_all_code()

	# enter() carries no delta; the delta action is refused loudly instead
	assert_str(code).contains('has no enter body')
	assert_str(code).not_contains('* delta')


# body_actions survive a save/reload round-trip, nested and all
func test_body_actions_round_trip() -> void:
	var loop := HenSaveAction.new()
	loop.macro_id = &'for_each'
	var child := HenSaveAction.new()
	child.macro_id = &'print_value'
	loop.body_actions.append(child)

	var path: String = 'user://loop_rt.tres'
	ResourceSaver.save(loop, path)
	var loaded: HenSaveAction = ResourceLoader.load(path, '', ResourceLoader.CACHE_MODE_IGNORE) as HenSaveAction

	assert_int(loaded.body_actions.size()).is_equal(1)
	assert_str(str(loaded.body_actions[0].macro_id)).is_equal('print_value')


# a stateful action (wait, signal, mouse look) nested in a loop: its declarations
# are collected THROUGH the bodies, so the counter lives at state level and the
# reset runs in enter(), the same as it does at the top
func test_stateful_action_in_a_loop_declares_at_state_level() -> void:
	HenScriptMacroLoader.load_native_actions()

	var coll: HenSaveVar = save_data.add_var(false)
	coll.name = 'stuff'
	coll.type = 'Array'

	var loop: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'for_each'), &'update')
	loop.input_bindings['collection'] = HenUtils.bind_code_for_var(coll)

	var done: HenSaveState = save_data.add_state(false)
	done.name = 'done'

	var wait: HenSaveAction = _nested(&'wait')
	wait.inputs = [HenSaveParam.create({name = 'Seconds', type = 'float', id = &'seconds', default_value = 1.0})]
	wait.branches['finished'] = {state_id = done.id, label = ''}
	loop.body_actions.append(wait)

	var code: String = HenTest.get_all_code()

	assert_str(code).not_contains('can only be used at the top level')
	assert_str(code).not_contains('unresolved')
	assert_str(code).contains('var wait_' + str(wait.id))
	assert_str(code).contains('wait_' + str(wait.id) + ' = 0.0')
	assert_str(code).contains('wait_' + str(wait.id) + ' += delta')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# a skipped loop takes its whole body with it: declaring for a step that never
# runs would leave a counter, or a signal connection, with nothing driving it
func test_a_skipped_loop_declares_nothing_for_its_body() -> void:
	HenScriptMacroLoader.load_native_actions()

	var coll: HenSaveVar = save_data.add_var(false)
	coll.name = 'gone'
	coll.type = 'Array'

	var loop: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'for_each'), &'update')
	loop.input_bindings['collection'] = HenUtils.bind_code_for_var(coll)

	var done: HenSaveState = save_data.add_state(false)
	done.name = 'done'

	var wait: HenSaveAction = _nested(&'wait')
	wait.inputs = [HenSaveParam.create({name = 'Seconds', type = 'float', id = &'seconds', default_value = 1.0})]
	wait.branches['finished'] = {state_id = done.id, label = ''}
	loop.body_actions.append(wait)

	save_data.variables.erase(coll)

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('unresolved: input "Collection"')
	assert_str(code).not_contains('wait_' + str(wait.id))

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# a loop inside a loop, both keeping state: two counters, two resets, no collision
func test_a_gate_nested_in_a_loop_keeps_its_own_counter() -> void:
	HenScriptMacroLoader.load_native_actions()

	var outer: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'do_n_times'), &'update')
	outer.inputs = [HenSaveParam.create({name = 'Times', type = 'int', id = &'times', default_value = 3})]

	var inner: HenSaveAction = _nested(&'do_once')
	outer.branch_actions['within'] = [inner] as Array[HenSaveAction]

	var step: HenSaveAction = _nested(&'print_value')
	step.inputs = [HenSaveParam.create({name = 'Value', type = 'Variant', id = &'value', default_value = 'hi'})]
	inner.branch_actions['first'] = [step] as Array[HenSaveAction]

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('var did_' + str(outer.id))
	assert_str(code).contains('var did_' + str(inner.id))
	assert_str(code).contains('did_' + str(outer.id) + ' = 0')
	assert_str(code).contains('did_' + str(inner.id) + ' = false')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# --- steps a branch runs without leaving the state --------------------------


# a branch runs its own steps and still transitions: the steps go first, since a
# transition ends the state and nothing after it would run
func test_a_branch_runs_its_steps_before_transitioning() -> void:
	var target: HenSaveState = save_data.add_state(false)
	target.name = 'done'

	var action: HenSaveAction = _add_action(_register(FIX_DO_N_TIMES), &'update')
	var step: HenSaveAction = HenSaveAction.create(_register(FIX_PHASES))

	action.branches['within'] = {state_id = target.id, label = ''}
	action.branch_actions['within'] = [step] as Array[HenSaveAction]

	var code: String = HenTest.get_all_code()
	var at_step: int = code.find('test_update("hi")')
	var at_change: int = code.find('_ref._STATE_CONTROLLER.change_state("done")')

	assert_int(at_step).is_greater(0)
	assert_int(at_step).is_less(at_change)


# steps alone are reason enough to emit: the branch never has to leave the state
func test_a_branch_with_only_steps_is_not_skipped() -> void:
	var action: HenSaveAction = _add_action(_register(FIX_DO_N_TIMES), &'update')

	action.branch_actions['done'] = [HenSaveAction.create(_register(FIX_PHASES))] as Array[HenSaveAction]

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('test_update("hi")')
	assert_str(code).not_contains('unresolved')


# the two sides run their own steps and neither changes state
func test_both_branches_can_run_steps() -> void:
	var action: HenSaveAction = _add_action(_register(FIX_DO_N_TIMES), &'update')

	action.branch_actions['within'] = [HenSaveAction.create(_register(FIX_PHASES))] as Array[HenSaveAction]
	action.branch_actions['done'] = [HenSaveAction.create(_register(FIX_PHASES))] as Array[HenSaveAction]

	var code: String = HenTest.get_all_code()

	assert_int(code.count('test_update("hi")')).is_equal(2)
	assert_str(code).not_contains('unresolved')
	# _ready always starts the machine, so only the state body is checked
	assert_str(code.substr(code.find('class StateTest'))).not_contains('change_state')


# nothing nested and nothing wired: an if/else of two passes, reported instead
func test_a_gating_action_with_nothing_wired_is_reported() -> void:
	_add_action(_register(FIX_DO_N_TIMES), &'update')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('add an action inside it or set a branch target')


# steps used to live in body_actions before every branch could hold its own. the
# macro names the branch they move to, so the migration never guesses from order
func test_an_older_body_moves_to_the_branch_the_macro_names() -> void:
	HenScriptMacroLoader.load_native_actions()

	var gate: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'for_seconds'), &'update')
	var step: HenSaveAction = _nested(&'print_value')

	gate.body_actions.append(step)

	HenSaveAction.migrate_branch_bodies(save_data)

	assert_bool(gate.body_actions.is_empty()).is_true()
	assert_int((gate.branch_actions.get('during', []) as Array).size()).is_equal(1)
	assert_str(str((gate.branch_actions['during'][0] as HenSaveAction).macro_id)).is_equal('print_value')

	# running it again moves nothing: the body is already empty
	HenSaveAction.migrate_branch_bodies(save_data)

	assert_int((gate.branch_actions.get('during', []) as Array).size()).is_equal(1)
