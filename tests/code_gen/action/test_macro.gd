extends HenActionTestSuite

# covers a macro: the machine it holds written inside every state that uses it,
# the values a use hands it and where its named ways out lead.


func _add_macro(_name: String) -> HenSaveStateMacro:
	var macro: HenSaveStateMacro = save_data.add_macro()

	macro.name = _name
	macro.get_states(save_data)[0].name = _name + ' first'

	return macro


func _use(_macro: HenSaveStateMacro, _parent: HenSaveState) -> HenSaveState:
	return HenStateOps.request_add_macro_use(save_data, _parent, _macro)


func _macro_step(_macro: HenSaveStateMacro, _fixture: String) -> HenSaveAction:
	var action: HenSaveAction = HenSaveAction.create(_register(_fixture))

	save_data.add_state_action(_macro.get_states(save_data)[0].id, action)

	return action


func _add_input(_macro: HenSaveStateMacro, _name: String, _type: StringName) -> HenSaveParam:
	var param: HenSaveParam = _macro.get_new_input()

	param.name = _name
	param.type = _type

	return param


# --- the machine a use runs --------------------------------------------------


func test_a_use_writes_the_macro_inside_the_state() -> void:
	var macro: HenSaveStateMacro = _add_macro('patrol')

	_macro_step(macro, FIX_PHASES)

	var use: HenSaveState = _use(macro, state)

	use.name = 'patrol here'

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('class PatrolHere extends HengoState:')
	assert_str(code).contains('class PatrolFirst extends HengoState:')
	assert_str(code).contains('add_sub_state("patrol_first", PatrolFirst.new(_p))')
	assert_str(code).contains('change_sub_state("patrol_first")')
	assert_str(code).contains('test_update("hi")')


# the states of a macro belong to the uses of it, never to the script itself
func test_a_macro_nobody_uses_writes_nothing() -> void:
	var macro: HenSaveStateMacro = _add_macro('patrol')

	_macro_step(macro, FIX_PHASES)

	assert_str(HenTest.get_all_code()).not_contains('class PatrolFirst extends HengoState:')


func test_two_uses_each_get_their_own_copy() -> void:
	var macro: HenSaveStateMacro = _add_macro('patrol')
	var other: HenSaveState = save_data.add_state(false)

	other.name = 'other'
	_macro_step(macro, FIX_PHASES)
	_use(macro, state).name = 'first use'
	_use(macro, other).name = 'second use'

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('class FirstUse extends HengoState:')
	assert_str(code).contains('class SecondUse extends HengoState:')


# --- the values a use hands it -----------------------------------------------


func test_a_use_parks_its_values_at_script_scope() -> void:
	var macro: HenSaveStateMacro = _add_macro('patrol')

	_add_input(macro, 'speed', &'float').default_value = 240.0

	var use: HenSaveState = _use(macro, state)

	use.macro_inputs[0].default_value = 120.0

	assert_str(HenTest.get_all_code()).contains('var _mc_' + str(use.id) + '_speed = 120.0')


func test_a_step_inside_the_macro_reads_the_value_of_its_use() -> void:
	var macro: HenSaveStateMacro = _add_macro('patrol')
	var param: HenSaveParam = _add_input(macro, 'speed', &'float')
	var action: HenSaveAction = _macro_step(macro, FIX_PHASES)

	action.input_bindings['value'] = HenUtils.bind_code_for_arg(param)

	var use: HenSaveState = _use(macro, state)

	use.macro_inputs[0].default_value = 12.0

	assert_str(HenTest.get_all_code()).contains('test_update(_ref._mc_' + str(use.id) + '_speed)')


# --- the ways out ------------------------------------------------------------


func test_a_way_out_transitions_to_what_the_use_wired() -> void:
	var macro: HenSaveStateMacro = _add_macro('patrol')
	var flow: HenSaveFlowParam = macro.get_new_flow_output()
	var target: HenSaveState = save_data.add_state(false)
	var action: HenSaveAction = _macro_step(macro, FIX_TRANSITION)

	flow.name = 'done'
	target.name = 'idle'
	action.branches['to'] = {exit_id = str(flow.id), label = ''}

	var use: HenSaveState = _use(macro, state)

	use.flow_targets[str(flow.id)] = {state_id = target.id, label = ''}

	assert_str(HenTest.get_all_code()).contains('_ref._STATE_CONTROLLER.change_state("idle")')


# a use that left a way out unwired keeps running instead of jumping nowhere
func test_an_unwired_way_out_emits_nothing() -> void:
	var macro: HenSaveStateMacro = _add_macro('patrol')
	var flow: HenSaveFlowParam = macro.get_new_flow_output()
	var action: HenSaveAction = _macro_step(macro, FIX_TRANSITION)

	var target: HenSaveState = save_data.add_state(false)

	target.name = 'idle'
	flow.name = 'done'
	action.branches['to'] = {exit_id = str(flow.id), label = ''}
	_use(macro, state)

	var code: String = HenTest.get_all_code()

	assert_str(code).not_contains('change_state("idle")')
	assert_str(code).contains("func update(delta) -> void:\n\t\t\t\tsuper(delta)\n\t\t\t\tpass")


# --- surviving a save --------------------------------------------------------


# the definitions are inline sub-resources of save.res, and a key that comes back
# as another type would leave a macro looking empty
func test_a_macro_and_a_function_survive_a_round_trip() -> void:
	var macro: HenSaveStateMacro = _add_macro('patrol')
	var func_res: HenSaveFunc = save_data.add_function()

	func_res.name = 'reach'
	_macro_step(macro, FIX_PHASES)

	var use: HenSaveState = _use(macro, state)
	var body: HenSaveAction = HenSaveAction.create(_register(FIX_PHASES))

	use.name = 'patrol here'
	save_data.add_state_action(func_res.scope_state().id, body)

	var before: String = HenTest.get_all_code()
	var path: String = 'user://hengo_round_trip.res'

	assert_int(ResourceSaver.save(save_data, path)).is_equal(OK)

	var reloaded: HenSaveData = ResourceLoader.load(path, '', ResourceLoader.CACHE_MODE_IGNORE_DEEP) as HenSaveData

	assert_object(reloaded).is_not_null()
	assert_int(reloaded.macros.size()).is_equal(1)
	assert_int(reloaded.functions.size()).is_equal(1)
	assert_int(reloaded.macros[0].get_states(reloaded).size()).is_equal(1)

	var global: HenGlobal = Engine.get_singleton(&'Global')
	var code_generation: HenCodeGeneration = Engine.get_singleton(&'CodeGeneration')

	global.SAVE_DATA = null
	ProjectSettings.set_setting(HenSettings.DEBUG_COMPILATION_PATH, false)

	var after: String = code_generation.get_code(reloaded)

	global.SAVE_DATA = save_data
	DirAccess.remove_absolute(path)

	assert_str(after).is_equal(before)


func test_undo_takes_a_new_macro_back_out() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var macro: HenSaveStateMacro = HenStateOps.request_add_macro(save_data)

	assert_int(save_data.macros.size()).is_equal(1)
	assert_int(macro.get_states(save_data).size()).is_equal(1)

	assert_bool(global.flow_history.undo(save_data)).is_true()
	assert_int(save_data.macros.size()).is_equal(0)


# the same empty node slot inside a macro: there it runs in a state class, where
# the node is _ref
func test_a_node_slot_inside_a_macro_falls_back_to_the_script_node() -> void:
	var macro: HenSaveStateMacro = _add_macro('tint')

	_macro_step(macro, FIX_NODE_SLOT)
	_use(macro, state)

	assert_str(HenTest.get_all_code()).contains('_ref.modulate =')


# --- what each use puts inside the macro --------------------------------------


func _hook(_macro: HenSaveStateMacro, _name: String) -> HenSaveFlowParam:
	var flow: HenSaveFlowParam = _macro.get_new_flow_input()

	flow.name = _name

	return flow


func _use_step(_use: HenSaveState, _macro_id: StringName, _phase: StringName) -> HenSaveAction:
	var action: HenSaveAction = HenSaveAction.create(HenActionsPanel.find_macro(_macro_id))

	action.phase = _phase
	save_data.add_state_action(_use.id, action)

	return action


# the macro leaves a named place; each use fills it with steps of its own
func test_a_use_fills_the_place_the_macro_left() -> void:
	_register(FIX_PHASES)

	var macro: HenSaveStateMacro = _add_macro('weapon')
	var trigger: HenSaveFlowParam = _hook(macro, 'on trigger')
	var run: HenSaveAction = HenSaveAction.create(HenMacroHookMacro.macro_of(macro, trigger))

	save_data.add_state_action(macro.get_states(save_data)[0].id, run)

	var first: HenSaveState = _use(macro, state)
	var second: HenSaveState = _use(macro, save_data.add_state(false))

	first.name = 'pistol'
	second.name = 'cannon'

	_use_step(first, &'test_action_phases', StringName(str(trigger.id))).inputs[0].default_value = 'pew'
	_use_step(second, &'test_action_phases', StringName(str(trigger.id))).inputs[0].default_value = 'boom'

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('test_update("pew")')
	assert_str(code).contains('test_update("boom")')


# a place nobody filled is a pass, never a hole in the generated method
func test_an_empty_place_emits_pass() -> void:
	var macro: HenSaveStateMacro = _add_macro('weapon')
	var trigger: HenSaveFlowParam = _hook(macro, 'on trigger')
	var run: HenSaveAction = HenSaveAction.create(HenMacroHookMacro.macro_of(macro, trigger))

	save_data.add_state_action(macro.get_states(save_data)[0].id, run)
	_use(macro, state)

	assert_int(HenGeneratorAction.collect_errors(save_data).size()).is_equal(0)
	assert_str(HenTest.get_all_code()).contains('pass')


# beyond the places the macro names, a use keeps the four phases of a state
func test_a_use_runs_its_own_phases_around_the_macro() -> void:
	var macro: HenSaveStateMacro = _add_macro('weapon')

	_macro_step(macro, FIX_PHASES)
	_register(FIX_PHASES)

	var use: HenSaveState = _use(macro, state)

	use.name = 'pistol'
	_use_step(use, &'test_action_phases', &'enter').inputs[0].default_value = 'ready'

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('class Pistol extends HengoState:')
	assert_str(code).contains('test_enter("ready")')
	# the machine of the macro still starts when the use is entered
	assert_str(code).contains('change_sub_state("weapon_first")')
