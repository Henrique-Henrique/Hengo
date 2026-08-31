extends HenActionTestSuite

# the awkward states a definition can be left in: deleted while in use, named like
# its neighbour, pointing at itself. none of them may write a script that refuses
# to parse or hang the generator.


func _add_function(_name: String) -> HenSaveFunc:
	var func_res: HenSaveFunc = save_data.add_function()

	func_res.name = _name

	return func_res


func _add_macro(_name: String) -> HenSaveStateMacro:
	var macro: HenSaveStateMacro = save_data.add_macro()

	macro.name = _name
	(macro.get_states(save_data)[0] as HenSaveState).name = _name + ' first'

	return macro


func _call(_func: HenSaveFunc, _state: HenSaveState) -> HenSaveAction:
	var action: HenSaveAction = HenSaveAction.create(HenFunctionMacro.macro_of(_func))

	save_data.add_state_action(_state.id, action)

	return action


func _function_step(_func: HenSaveFunc, _macro: HenSaveMacro) -> HenSaveAction:
	var action: HenSaveAction = HenSaveAction.create(_macro)

	save_data.add_state_action(_func.scope_state().id, action)

	return action


# the fixtures call methods the generated script does not have, so parsing it
# proves nothing here: what matters is that no name is declared twice in one
# scope, which is what would refuse to compile in a real script. the scope is the
# chain of classes above the line, since two sibling classes may repeat a member
func _repeated_declarations(_code: String) -> Array[String]:
	var seen: Dictionary = {}
	var repeated: Array[String] = []
	var path: PackedStringArray = []

	for line: String in _code.split("
"):
		var stripped: String = line.strip_edges(true, false)

		if stripped.is_empty() or stripped.begins_with('#'):
			continue

		var indent: int = line.length() - stripped.length()

		while path.size() > indent:
			path.remove_at(path.size() - 1)

		var head: String = ''

		if stripped.begins_with('class '):
			head = stripped.substr(6, stripped.find(' extends') - 6)
		elif stripped.begins_with('func '):
			head = stripped.substr(5, stripped.find('(') - 5)
		elif stripped.begins_with('var '):
			head = stripped.substr(4).split(' ')[0].split(':')[0].split('=')[0]
		else:
			continue

		var key: String = '/'.join(path) + '::' + head

		if seen.has(key):
			repeated.append(key)

		seen[key] = true

		if stripped.begins_with('class '):
			path.append(head)

	return repeated


# --- deleted while in use ----------------------------------------------------


func test_a_call_of_a_deleted_function_is_reported_not_emitted() -> void:
	var func_res: HenSaveFunc = _add_function('gone')

	_function_step(func_res, _register(FIX_PHASES))
	_call(func_res, state)
	save_data.functions.clear()

	var code: String = HenTest.get_all_code()

	assert_str(code).not_contains('fn_gone')
	assert_array(_repeated_declarations(code)).is_empty()
	assert_int(HenGeneratorAction.collect_errors(save_data).size()).is_equal(1)


func test_a_use_of_a_deleted_macro_writes_an_empty_state() -> void:
	var macro: HenSaveStateMacro = _add_macro('gone')

	HenStateOps.request_add_macro_use(save_data, state, macro).name = 'ghost'
	save_data.macros.clear()

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('class Ghost extends HengoState:')
	assert_array(_repeated_declarations(code)).is_empty()


# --- names that would collide ------------------------------------------------


# two functions whose names land on the same method would write it twice
func test_two_functions_cannot_write_the_same_method() -> void:
	var first: HenSaveFunc = _add_function('take damage')
	var second: HenSaveFunc = _add_function('Take Damage')

	_function_step(first, _register(FIX_PHASES))
	_function_step(second, _register(FIX_PHASES))

	assert_array(_repeated_declarations(HenTest.get_all_code())).is_empty()


# two uses of one macro are born with its name, and a machine cannot hold two
# states called the same
func test_two_uses_are_born_with_names_of_their_own() -> void:
	var macro: HenSaveStateMacro = _add_macro('alarm')
	var first: HenSaveState = HenStateOps.request_add_macro_use(save_data, state, macro)
	var second: HenSaveState = HenStateOps.request_add_macro_use(save_data, state, macro)

	assert_str(first.name).is_not_equal(second.name)
	assert_array(_repeated_declarations(HenTest.get_all_code())).is_empty()


# --- pointing at itself ------------------------------------------------------


# a macro used inside itself would write its own body forever
func test_a_macro_used_inside_itself_does_not_hang() -> void:
	var macro: HenSaveStateMacro = _add_macro('loop')
	var inner: HenSaveState = macro.get_states(save_data)[0]
	var use: HenSaveState = HenSaveState.create_macro_use(macro, save_data)

	use.name = 'inner use'
	save_data.sub_states[inner.id] = [use]

	HenStateOps.request_add_macro_use(save_data, state, macro).name = 'outer use'

	assert_array(_repeated_declarations(HenTest.get_all_code())).is_empty()


# a function calling itself is a recursive method, which is fine, but the
# collectors must not walk it forever
func test_a_function_calling_itself_does_not_hang() -> void:
	var func_res: HenSaveFunc = _add_function('again')

	_function_step(func_res, _register(FIX_ONCE)).branch_actions['first'] = [HenSaveAction.create(_register(FIX_PHASES))]
	_function_step(func_res, HenFunctionMacro.macro_of(func_res))
	_call(func_res, state)

	assert_array(_repeated_declarations(HenTest.get_all_code())).is_empty()


# two functions calling each other, which is the same trap one level deeper
func test_two_functions_calling_each_other_do_not_hang() -> void:
	var first: HenSaveFunc = _add_function('ping')
	var second: HenSaveFunc = _add_function('pong')

	_function_step(first, HenFunctionMacro.macro_of(second))
	_function_step(second, HenFunctionMacro.macro_of(first))
	_call(first, state)

	assert_array(_repeated_declarations(HenTest.get_all_code())).is_empty()


# --- inputs that went away ---------------------------------------------------


# a step reading an input the definition no longer has cannot emit a bare name
func test_a_step_reading_a_dropped_input_is_reported() -> void:
	var func_res: HenSaveFunc = _add_function('shout')
	var param: HenSaveParam = func_res.get_new_input()
	var action: HenSaveAction = _function_step(func_res, _register(FIX_PHASES))

	param.name = 'word'
	action.input_bindings['value'] = HenUtils.bind_code_for_arg(param)
	func_res.inputs = [] as Array[HenSaveParam]

	var code: String = HenTest.get_all_code()

	assert_array(_repeated_declarations(code)).is_empty()
	assert_int(HenGeneratorAction.collect_errors(save_data).size()).is_greater(0)


# --- what points at what -----------------------------------------------------


# a way out wired to a state that was deleted afterwards
func test_a_way_out_pointing_at_a_deleted_state_emits_nothing() -> void:
	var macro: HenSaveStateMacro = _add_macro('alarm')
	var way: HenSaveFlowParam = macro.get_new_flow_output()
	var target: HenSaveState = save_data.add_state(false)
	var action: HenSaveAction = HenSaveAction.create(_register(FIX_TRANSITION))

	target.name = 'gone'
	action.branches['to'] = {exit_id = str(way.id), label = ''}
	save_data.add_state_action(macro.get_states(save_data)[0].id, action)

	var use: HenSaveState = HenStateOps.request_add_macro_use(save_data, state, macro)

	use.flow_targets[str(way.id)] = {state_id = target.id, label = ''}
	save_data.states.erase(target)

	var code: String = HenTest.get_all_code()

	assert_str(code).not_contains('change_state("gone")')
	assert_array(_repeated_declarations(code)).is_empty()


# a use at the top level of the script, not nested in another state
func test_a_use_can_be_a_state_of_the_script() -> void:
	var macro: HenSaveStateMacro = _add_macro('alarm')
	var use: HenSaveState = HenSaveState.create_macro_use(macro, save_data)

	use.name = 'top alarm'
	use.is_sub_state = false
	save_data.states.append(use)

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('top_alarm=TopAlarm.new(self)')
	assert_str(code).contains('class TopAlarm extends HengoState:')
	assert_str(code).contains('change_sub_state("alarm_first")')
	assert_array(_repeated_declarations(code)).is_empty()


# the step that runs a place of a macro only makes sense inside that macro
func test_running_a_place_outside_its_macro_is_reported() -> void:
	var macro: HenSaveStateMacro = _add_macro('alarm')
	var hook: HenSaveFlowParam = macro.get_new_flow_input()
	var stray: HenSaveAction = HenSaveAction.create(HenMacroHookMacro.macro_of(macro, hook))

	hook.name = 'on aim'
	save_data.add_state_action(state.id, stray)

	var code: String = HenTest.get_all_code()

	assert_array(_repeated_declarations(code)).is_empty()
	# nothing was put there by any use, so it may not write a hole in the method
	assert_str(code).not_contains('{{macro_hook}}')


# the same function called from two phases of one state
func test_a_function_called_from_two_phases() -> void:
	var func_res: HenSaveFunc = _add_function('tick')

	_function_step(func_res, _register(FIX_PHASES))

	var first: HenSaveAction = _call(func_res, state)
	var second: HenSaveAction = _call(func_res, state)

	first.phase = &'enter'
	second.phase = &'physics'

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('func enter() -> void:\n\t\t_ref.fn_tick()')
	assert_str(code).contains('func physics(delta) -> void:\n\t\tsuper(delta)\n\t\t_ref.fn_tick()')
	assert_array(_repeated_declarations(code)).is_empty()


# a copy of a call keeps pointing at the same definition
func test_a_copied_call_still_reaches_its_function() -> void:
	var func_res: HenSaveFunc = _add_function('tick')
	var other: HenSaveState = save_data.add_state(false)

	other.name = 'Other'
	_function_step(func_res, _register(FIX_PHASES))

	var original: HenSaveAction = _call(func_res, state)
	var copy: HenSaveAction = original.duplicate(true)

	copy.id = save_data.new_counter_id()
	save_data.add_state_action(other.id, copy)

	var code: String = HenTest.get_all_code()

	assert_int(code.count('_ref.fn_tick()')).is_equal(2)
	assert_int(HenGeneratorAction.collect_errors(save_data).size()).is_equal(0)


# --- surviving the editor ----------------------------------------------------


# a macro with a place filled by a use, saved and read back: the steps ride the
# action list of the use keyed by the place, which has to come back as it went
func test_hooks_and_use_steps_survive_a_round_trip() -> void:
	var macro: HenSaveStateMacro = _add_macro('weapon')
	var hook: HenSaveFlowParam = macro.get_new_flow_input()
	var run: HenSaveAction = HenSaveAction.create(HenMacroHookMacro.macro_of(macro, hook))

	hook.name = 'on aim'
	save_data.add_state_action(macro.get_states(save_data)[0].id, run)

	var use: HenSaveState = HenStateOps.request_add_macro_use(save_data, state, macro)
	var step: HenSaveAction = HenSaveAction.create(_register(FIX_PHASES))

	step.phase = StringName(str(hook.id))
	step.inputs[0].default_value = 'pew'
	save_data.add_state_action(use.id, step)

	var before: String = HenTest.get_all_code()
	var path: String = 'user://hengo_hook_round_trip.res'

	assert_int(ResourceSaver.save(save_data, path)).is_equal(OK)

	var reloaded: HenSaveData = ResourceLoader.load(path, '', ResourceLoader.CACHE_MODE_IGNORE_DEEP) as HenSaveData
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var code_generation: HenCodeGeneration = Engine.get_singleton(&'CodeGeneration')

	assert_int(reloaded.macros[0].flow_inputs.size()).is_equal(1)

	global.SAVE_DATA = null
	ProjectSettings.set_setting(HenSettings.DEBUG_COMPILATION_PATH, false)

	var after: String = code_generation.get_code(reloaded)

	global.SAVE_DATA = save_data
	DirAccess.remove_absolute(path)

	assert_str(after).is_equal(before)
	assert_str(after).contains('test_update("pew")')


# deleting a function through the sidebar takes its body with it, and undoing
# brings both back
func test_deleting_a_function_takes_its_body_and_gives_it_back() -> void:
	var side_bar: HenSideBar = (load('res://addons/hengo/scenes/side_bar.tscn') as PackedScene).instantiate()
	var func_res: HenSaveFunc = _add_function('gone')

	add_child(side_bar)
	_function_step(func_res, _register(FIX_PHASES))
	_call(func_res, state)

	assert_int(save_data.get_state_actions(func_res.scope_state().id).size()).is_equal(1)

	side_bar._request_delete_resource(func_res)

	assert_int(save_data.functions.size()).is_equal(0)
	assert_int(save_data.get_state_actions(func_res.scope_state().id).size()).is_equal(0)

	assert_bool((Engine.get_singleton(&'Global') as HenGlobal).flow_history.undo(save_data)).is_true()

	assert_int(save_data.functions.size()).is_equal(1)
	assert_int(save_data.get_state_actions(func_res.scope_state().id).size()).is_equal(1)

	side_bar.free()


# the same for a macro, whose states live in the drawer
func test_deleting_a_macro_takes_its_states_and_gives_them_back() -> void:
	var side_bar: HenSideBar = (load('res://addons/hengo/scenes/side_bar.tscn') as PackedScene).instantiate()
	var macro: HenSaveStateMacro = _add_macro('alarm')

	add_child(side_bar)
	HenStateOps.request_add_macro_use(save_data, state, macro)

	assert_int(macro.get_states(save_data).size()).is_equal(1)

	side_bar._request_delete_resource(macro)

	assert_int(save_data.macros.size()).is_equal(0)
	assert_bool(save_data.sub_states.has(macro.id)).is_false()

	assert_bool((Engine.get_singleton(&'Global') as HenGlobal).flow_history.undo(save_data)).is_true()

	assert_int(save_data.macros.size()).is_equal(1)
	assert_int(macro.get_states(save_data).size()).is_equal(1)

	side_bar.free()


# undoing the use of a macro takes the box out of the state again
func test_undo_takes_a_use_back_out() -> void:
	var macro: HenSaveStateMacro = _add_macro('alarm')
	var use: HenSaveState = HenStateOps.request_add_macro_use(save_data, state, macro)

	assert_bool(state.get_sub_states(save_data).has(use)).is_true()

	assert_bool((Engine.get_singleton(&'Global') as HenGlobal).flow_history.undo(save_data)).is_true()

	assert_bool(state.get_sub_states(save_data).has(use)).is_false()
	# the macro itself is untouched: only the box is gone
	assert_int(save_data.macros.size()).is_equal(1)
