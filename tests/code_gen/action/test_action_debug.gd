extends HenActionTestSuite

# covers the tracing emitted when debug compilation is on, and the flags that
# turn an action off or rename it.

# --- debug tracing ----------------------------------------------------------


# get_all_code() forces debug off (its codegen-accuracy hack), so a trace test
# regenerates with the flag on, then restores it the same way the harness does
func _code_with_debug() -> String:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var code_generation: HenCodeGeneration = Engine.get_singleton(&'CodeGeneration')
	var sd: HenSaveData = global.SAVE_DATA
	global.SAVE_DATA = null
	ProjectSettings.set_setting(HenSettings.DEBUG_COMPILATION_PATH, true)
	var code: String = code_generation.get_code(sd)
	ProjectSettings.set_setting(HenSettings.DEBUG_COMPILATION_PATH, false)
	global.SAVE_DATA = sd
	return code


func _trace_line(_action: HenSaveAction) -> String:
	var script_id: String = str(save_data.identity.id)

	return 'if _ref.get_instance_id() == HengoDebugger.state_targets.get("' + script_id \
		+'", -1): HengoDebugger.trace_action(&"' + str(_action.id) + '", "' + script_id + '")'


# with debug on, each action gets a guarded trace line right before its body, so
# its row lights up only for the focused instance while the action runs
func test_debug_emits_guarded_trace_before_body() -> void:
	var action: HenSaveAction = _add_action(_register(FIX_PHASES), &'update')

	# the trace precedes the body inside update(), guarded to the focused instance
	assert_str(_code_with_debug()).contains(
		'\t\t' + _trace_line(action) + '\n\t\ttest_update("hi")')


# the nested case is the fragile one: a loop-body action's trace line must be
# reindented one level deeper alongside the block, and still parse
func test_debug_trace_indents_inside_loop_body() -> void:
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

	var code: String = _code_with_debug()

	# the loop's own trace sits at method indent, right before the block it opens
	assert_str(code).contains(
		'\t\t' + _trace_line(loop) + '\n\t\tvar __i_' + str(loop.id))
	# the nested action's trace is one level deeper, right before its body
	assert_str(code).contains(
		'\t\t\t' + _trace_line(print_a) + '\n\t\t\tprint(_ref.e)')

	var script := GDScript.new()
	script.source_code = code
	assert_int(script.reload()).is_equal(OK)


# a function body is written at script scope, where `_ref` is not declared
func test_debug_trace_inside_a_function_names_self() -> void:
	var func_res: HenSaveFunc = save_data.add_function()

	func_res.name = 'do stuff'

	var action: HenSaveAction = HenSaveAction.create(_register(FIX_PRINT))

	save_data.add_state_action(func_res.scope_state().id, action)

	var code: String = _code_with_debug()

	assert_str(code).contains(
		'func fn_do_stuff() -> void:\n\t' + _trace_line(action).replace('_ref.', 'self.'))
	assert_str(code).not_contains('func fn_do_stuff() -> void:\n\tif _ref.')

	var script := GDScript.new()
	script.source_code = code
	assert_int(script.reload()).is_equal(OK)


# the release-shaped path (get_all_code) carries no instrumentation
func test_debug_off_emits_no_trace() -> void:
	_add_action(_register(FIX_PHASES), &'update')

	assert_str(HenTest.get_all_code()).not_contains('trace_action')


# a branch action flashes its state-viewer edge (source state + branch label)
# right before it transitions, so the arrow lights like the old cnode transition
func test_debug_flashes_branch_transition_edge() -> void:
	var dead: HenSaveState = save_data.add_state(false)
	dead.name = 'dead'

	var action: HenSaveAction = _add_action(_register(FIX_TRANSITION), &'update')
	action.branches['to'] = {state_id = dead.id, label = 'morreu'}

	var sid: String = str(save_data.identity.id)
	var code: String = _code_with_debug()

	assert_str(code).contains('trace_state_transition("state test", "morreu", "' + sid
		+'")\n\t\t_ref._STATE_CONTROLLER.change_state("dead")')
	assert_str(code).contains('if _ref.get_instance_id() == HengoDebugger.state_targets.get("' + sid + '", -1):')

	var script := GDScript.new()
	script.source_code = code
	assert_int(script.reload()).is_equal(OK)


# a muted step keeps its values and emits nothing, the way a breakpoint does
func test_a_disabled_action_emits_no_code() -> void:
	var action: HenSaveAction = _add_action(_register(FIX_TYPED), &'update')

	action.inputs[1].default_value = 45.0
	action.disabled = true

	assert_str(HenTest.get_all_code()).not_contains('= 45')


func test_a_disabled_action_keeps_its_values() -> void:
	var action: HenSaveAction = _add_action(_register(FIX_TYPED), &'update')

	action.inputs[1].default_value = 45.0
	action.disabled = true
	action.disabled = false

	assert_that(action.inputs[1].default_value).is_equal(45.0)


# the label is what the user named this instance, so it wins over the macro name
func test_a_labelled_action_shows_its_own_name() -> void:
	var action: HenSaveAction = _add_action(_register(FIX_TYPED), &'update')

	assert_str(HenActionsPanel.display_name(action)).is_not_equal('Hit Counter')

	action.label = 'Hit Counter'

	assert_str(HenActionsPanel.display_name(action)).is_equal('Hit Counter')

	action.label = '   '

	assert_str(HenActionsPanel.display_name(action)).is_not_equal('   ')
