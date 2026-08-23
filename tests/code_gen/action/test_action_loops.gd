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
	loop.output_bindings['item'] = HenUtils.bind_code_for_var(item)

	var print_a: HenSaveAction = _nested(&'print_value')
	print_a.inputs = [HenSaveParam.create({name = 'Value', type = 'Variant', id = &'value'})]
	print_a.input_bindings['value'] = HenUtils.bind_code_for_var(item)
	loop.body_actions.append(print_a)

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('for __item_' + str(loop.id) + ' in _ref.enemies:')
	assert_str(code).contains('\t\t\t_ref.e = __item_' + str(loop.id))
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


# a stateful action (wait, signal, mouse look) can't live inside a loop: its
# declarations are collected from the flat state list only, so nesting it would
# reference undeclared vars. refused loudly instead of emitting broken code
func test_stateful_action_in_a_loop_is_refused() -> void:
	HenScriptMacroLoader.load_native_actions()

	var coll: HenSaveVar = save_data.add_var(false)
	coll.name = 'stuff'
	coll.type = 'Array'

	var loop: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'for_each'), &'update')
	loop.input_bindings['collection'] = HenUtils.bind_code_for_var(coll)

	var wait: HenSaveAction = _nested(&'wait')
	wait.inputs = [HenSaveParam.create({name = 'Seconds', type = 'float', id = &'seconds', default_value = 1.0})]
	loop.body_actions.append(wait)

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('can only be used at the top level, not inside a loop')
	assert_str(code).not_contains('wait_' + str(wait.id))

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# --- a body and a branch on the same action ---------------------------------


# the nested actions run on the branch that fires, and the branch still follows
func test_a_gating_action_runs_its_body_before_its_branch() -> void:
	var target: HenSaveState = save_data.add_state(false)
	target.name = 'done'

	var action: HenSaveAction = _add_action(_register(FIX_DO_N_TIMES), &'update')

	action.branches['done'] = {state_id = target.id, label = ''}
	action.body_actions.append(HenSaveAction.create(_register(FIX_PHASES)))

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('test_update("hi")')
	assert_str(code).contains('_ref._STATE_CONTROLLER.change_state("done")')


# the body alone is reason enough to emit: both branches are optional
func test_a_gating_action_with_only_a_body_is_not_skipped() -> void:
	var action: HenSaveAction = _add_action(_register(FIX_DO_N_TIMES), &'update')

	action.body_actions.append(HenSaveAction.create(_register(FIX_PHASES)))

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('test_update("hi")')
	assert_str(code).not_contains('unresolved')


# nothing nested and nothing wired: an if/else of two passes, reported instead
func test_a_gating_action_with_nothing_wired_is_reported() -> void:
	_add_action(_register(FIX_DO_N_TIMES), &'update')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('add an action inside it or set a branch target')
