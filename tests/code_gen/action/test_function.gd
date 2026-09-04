extends HenActionTestSuite

# covers the method a function of the script is emitted as, the call the action
# that uses it emits, and what the body of one is allowed to hold.


func _add_function(_name: String) -> HenSaveFunc:
	var func_res: HenSaveFunc = save_data.add_function()

	func_res.name = _name

	return func_res


func _function_step(_func: HenSaveFunc, _macro: HenSaveMacro) -> HenSaveAction:
	var action: HenSaveAction = HenSaveAction.create(_macro)

	save_data.add_state_action(_func.scope_state().id, action)

	return action


func _call_action(_func: HenSaveFunc) -> HenSaveAction:
	var action: HenSaveAction = HenSaveAction.create(HenFunctionMacro.macro_of(_func))

	save_data.add_state_action(state.id, action)

	return action


func _finish_action(_func: HenSaveFunc) -> HenSaveAction:
	var action: HenSaveAction = HenSaveAction.create(HenFunctionMacro.macro_of(_func, true))

	save_data.add_state_action(_func.scope_state().id, action)

	return action


func _add_input(_func: HenSaveFunc, _name: String, _type: StringName) -> HenSaveParam:
	var param: HenSaveParam = _func.get_new_input()

	param.name = _name
	param.type = _type

	return param


func _add_output(_func: HenSaveFunc, _name: String, _type: StringName) -> HenSaveParam:
	var param: HenSaveParam = _func.get_new_output()

	param.name = _name
	param.type = _type

	return param


# --- the method -------------------------------------------------------------


func test_a_function_is_a_method_of_the_script() -> void:
	var func_res: HenSaveFunc = _add_function('do stuff')

	_function_step(func_res, _register(FIX_PHASES))

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('func fn_do_stuff() -> void:\n\ttest_update("hi")')


func test_an_empty_function_still_parses() -> void:
	_add_function('nothing')

	assert_str(HenTest.get_all_code()).contains('func fn_nothing() -> void:\n\tpass')


func test_inputs_become_typed_parameters() -> void:
	var func_res: HenSaveFunc = _add_function('hurt')

	_add_input(func_res, 'amount', &'float')
	_add_input(func_res, 'source', &'Node2D')

	assert_str(HenTest.get_all_code()).contains('func fn_hurt(amount: float = 0., source: Node2D = null) -> void:')


# a step of the body reads a parameter the same way it reads a variable
func test_a_step_binds_an_input_of_the_function() -> void:
	var func_res: HenSaveFunc = _add_function('shout')
	var param: HenSaveParam = _add_input(func_res, 'word', &'String')
	var action: HenSaveAction = _function_step(func_res, _register(FIX_PHASES))

	action.input_bindings['value'] = HenUtils.bind_code_for_arg(param)

	assert_str(HenTest.get_all_code()).contains('func fn_shout(word: String = \'\') -> void:\n\ttest_update(word)')


# --- the call ---------------------------------------------------------------


func test_a_state_calls_the_function() -> void:
	var func_res: HenSaveFunc = _add_function('do stuff')

	_function_step(func_res, _register(FIX_PHASES))
	_call_action(func_res)

	assert_str(HenTest.get_all_code()).contains('func update(delta) -> void:\n\t\tsuper(delta)\n\t\t_ref.fn_do_stuff()')


func test_the_call_carries_the_values_of_its_slots() -> void:
	var func_res: HenSaveFunc = _add_function('hurt')

	_add_input(func_res, 'amount', &'float')
	_function_step(func_res, _register(FIX_PHASES))

	var action: HenSaveAction = _call_action(func_res)

	action.inputs[0].default_value = 12.5

	assert_str(HenTest.get_all_code()).contains('_ref.fn_hurt(12.5)')


# a single output and no way out reads as the return value, so the call can feed
# a slot instead of standing on its own
func test_a_single_output_function_is_read_as_its_return() -> void:
	var func_res: HenSaveFunc = _add_function('distance')

	var result: HenSaveParam = _add_output(func_res, 'result', &'float')

	_finish_action(func_res).inputs[0].default_value = 3.0

	var reader: HenSaveAction = _add_action(_register(FIX_PHASES), &'update')
	var producer: HenSaveAction = HenSaveAction.create(HenFunctionMacro.macro_of(func_res))

	reader.input_actions['value'] = {action = producer, output = str(result.id)}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('func fn_distance() -> float:\n\treturn 3.0')
	assert_str(code).contains('test_update((_ref.fn_distance()))')


# --- ways out ---------------------------------------------------------------


func test_a_branching_function_reports_which_way_it_went() -> void:
	var func_res: HenSaveFunc = _add_function('look')

	func_res.get_new_flow_output().name = 'found'
	func_res.flow_outputs[0].id = &'found'
	func_res.get_new_flow_output().name = 'missed'
	func_res.flow_outputs[1].id = &'missed'

	var finish: HenSaveAction = _finish_action(func_res)

	for param: HenSaveParam in finish.inputs:
		if str(param.id) == str(HenFunctionMacro.BRANCH_INPUT):
			param.default_value = 'missed'

	var call_action: HenSaveAction = _call_action(func_res)

	call_action.branch_actions['found'] = [HenSaveAction.create(_register(FIX_PHASES))]

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('func fn_look() -> StringName:\n\treturn &\'missed\'\n\treturn &\'\'')
	assert_str(code).contains('match _ref.fn_look():')
	assert_str(code).contains('\t\t\t&\'found\':\n\t\t\t\ttest_update("hi")')
	assert_str(code).contains('\t\t\t&\'missed\':\n\t\t\t\tpass')


# with a way out declared the value cannot ride the return, so it is parked in a
# variable of the script the readers pick up
func test_a_branching_function_parks_its_output() -> void:
	var func_res: HenSaveFunc = _add_function('look')

	func_res.get_new_flow_output().id = &'found'
	_add_output(func_res, 'damage', &'float')

	var finish: HenSaveAction = _finish_action(func_res)

	finish.inputs[0].default_value = 7.0

	var code: String = HenTest.get_all_code()
	var parked: String = '_fn_' + str(func_res.id) + '_' + str(func_res.outputs[0].id)

	assert_str(code).contains('var ' + parked + ': float = 0.')
	# a function body is written at script scope, where the node is self
	assert_str(code).contains("\tself." + parked + " = 7.0\n\treturn &'found'")


# --- what a function body may hold ------------------------------------------


func test_a_finish_outside_a_function_is_refused() -> void:
	var func_res: HenSaveFunc = _add_function('look')
	var stray: HenSaveAction = HenSaveAction.create(HenFunctionMacro.macro_of(func_res, true))

	save_data.add_state_action(state.id, stray)

	var errors: Array[Dictionary] = HenGeneratorAction.collect_errors(save_data)

	assert_int(errors.size()).is_equal(1)
	assert_str(str(errors[0].reason)).contains('can only be used inside a function')


func test_a_transition_inside_a_function_is_refused() -> void:
	var func_res: HenSaveFunc = _add_function('go')
	var target: HenSaveState = save_data.add_state(false)
	var action: HenSaveAction = _function_step(func_res, _register(FIX_TRANSITION))

	action.branches['to'] = {state_id = target.id, label = ''}

	var errors: Array[Dictionary] = HenGeneratorAction.collect_errors(save_data)

	assert_int(errors.size()).is_equal(1)
	assert_str(str(errors[0].reason)).is_equal('a function cannot change the state of its own script')


# driving the machine of another node is a call, not a state change of this script
func test_a_cross_script_transition_inside_a_function_is_allowed() -> void:
	var func_res: HenSaveFunc = _add_function('wake')
	var other: Dictionary = _other_script('Pop')
	var action: HenSaveAction = _function_step(func_res, _register(FIX_TRANSITION))

	action.branches['to'] = _cross_branch('to', other, {instance_path = '../Ball'})

	assert_int(HenGeneratorAction.collect_errors(save_data).size()).is_equal(0)
	assert_str(HenTest.get_all_code()).contains('self.get_node("../Ball")._STATE_CONTROLLER.change_state("pop")')


# --- creating one ------------------------------------------------------------


# the definitions ride the same undo stack every other edit does
func test_undo_takes_a_new_function_back_out() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var func_res: HenSaveFunc = HenStateOps.request_add_function(save_data)

	assert_object(func_res).is_not_null()
	assert_int(save_data.functions.size()).is_equal(1)

	assert_bool(global.flow_history.undo(save_data)).is_true()
	assert_int(save_data.functions.size()).is_equal(0)

	assert_bool(global.flow_history.redo(save_data)).is_true()
	assert_int(save_data.functions.size()).is_equal(1)


# --- what a function keeps ---------------------------------------------------


# a step of a function keeps its state at script scope, out of reach of the state
# that called it, so zeroing it is a method the caller asks for
func test_a_stateful_step_inside_a_function_resets_through_a_method() -> void:
	var func_res: HenSaveFunc = _add_function('try once')
	var once: HenSaveAction = _function_step(func_res, _register(FIX_ONCE))

	once.branch_actions['first'] = [HenSaveAction.create(_register(FIX_PHASES))]
	_call_action(func_res)

	var code: String = HenTest.get_all_code()
	var guard: String = 'did_' + str(once.id)

	assert_str(code).contains('var ' + guard + ': bool = false')
	assert_str(code).contains('func fn_try_once_reset() -> void:\n\t' + guard + ' = false')
	assert_str(code).contains('func enter() -> void:\n\t\t_ref.fn_try_once_reset()')


# the same call from inside a macro used twice: the reset still names the method,
# never a variable that only one copy of the macro would have
func test_a_macro_calling_a_stateful_function_asks_it_to_reset() -> void:
	var func_res: HenSaveFunc = _add_function('try once')
	var once: HenSaveAction = _function_step(func_res, _register(FIX_ONCE))
	var macro: HenSaveStateMacro = save_data.add_macro()

	once.branch_actions['first'] = [HenSaveAction.create(_register(FIX_PHASES))]
	macro.name = 'runner'

	var inner: HenSaveState = macro.get_states(save_data)[0]

	inner.name = 'call it'
	save_data.add_state_action(inner.id, HenSaveAction.create(HenFunctionMacro.macro_of(func_res)))

	HenStateOps.request_add_macro_use(save_data, state, macro).name = 'first use'
	HenStateOps.request_add_macro_use(save_data, save_data.add_state(false), macro).name = 'second use'

	var code: String = HenTest.get_all_code()

	assert_int(code.count('_ref.fn_try_once_reset()')).is_equal(2)
	assert_int(code.count('var did_' + str(once.id))).is_equal(1)


# the same ask from one function to another is written at script scope, where the
# node is self and `_ref` is not declared
func test_a_function_asking_another_to_reset_names_self() -> void:
	var inner: HenSaveFunc = _add_function('try once')

	_function_step(inner, _register(FIX_ONCE)).branch_actions['first'] = [HenSaveAction.create(_register(FIX_PHASES))]

	var outer: HenSaveFunc = _add_function('caller')

	save_data.add_state_action(outer.scope_state().id, HenSaveAction.create(HenFunctionMacro.macro_of(inner)))
	_call_action(outer)

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('func fn_caller_reset() -> void:\n\tself.fn_try_once_reset()')
	assert_str(code).not_contains('\t_ref.fn_try_once_reset()\n')


# --- a call is a step, not a value -------------------------------------------


# adding an output to a function must not silence the call: it runs a body of its
# own, unlike a native producer whose whole content is the value
func test_a_call_still_runs_when_nobody_stores_the_output() -> void:
	var func_res: HenSaveFunc = _add_function('roll')

	_add_output(func_res, 'result', &'float')
	_function_step(func_res, _register(FIX_PHASES))
	_call_action(func_res)

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('\t\t_ref.fn_roll()')
	assert_int(HenGeneratorAction.collect_errors(save_data).size()).is_equal(0)


# one reader is enough to park the value: reading it twice would run the body twice
func test_a_read_output_is_parked_instead_of_called_again() -> void:
	var func_res: HenSaveFunc = _add_function('roll')
	var result: HenSaveParam = _add_output(func_res, 'result', &'float')

	_function_step(func_res, _register(FIX_PHASES))

	var producer: HenSaveAction = _call_action(func_res)
	var reader: HenSaveAction = _add_action(_register(FIX_PHASES), &'update')

	reader.input_wires['value'] = {action_id = producer.id, output = str(result.id)}

	var code: String = HenTest.get_all_code()

	assert_int(code.count('_ref.fn_roll()')).is_equal(1)
	assert_str(code).contains('var wire_' + str(producer.id) + '_' + str(result.id) + ' = _ref.fn_roll()')


# the inspector swaps the array when a param is added, so the macro behind every
# call has to read the definition again instead of keeping the array it saw
func test_an_output_added_later_reaches_the_call() -> void:
	var func_res: HenSaveFunc = _add_function('roll')

	_function_step(func_res, _register(FIX_PHASES))

	var call_action: HenSaveAction = _call_action(func_res)

	assert_int(HenFunctionMacro.macro_of(func_res).outputs.size()).is_equal(0)

	var grown: Array[HenSaveParam] = func_res.outputs.duplicate()

	grown.append(HenSaveParam.create({name = 'result', type = &'float'}))
	func_res.outputs = grown

	assert_int(HenFunctionMacro.macro_of(func_res).outputs.size()).is_equal(1)
	assert_int(HenActionsPanel.find_macro(call_action.macro_id).outputs.size()).is_equal(1)


# the finish clones the slots of the outputs, so renaming or retyping one has to
# reach the steps that already exist
func test_a_retyped_output_updates_the_finish_slot() -> void:
	var func_res: HenSaveFunc = _add_function('roll')
	var result: HenSaveParam = _add_output(func_res, 'result', &'Variant')
	var finish: HenSaveAction = _finish_action(func_res)

	finish.inputs[0].default_value = 'text'

	result.name = 'ronald'
	result.type = &'float'

	HenSaveAction.sync_action_inputs(finish, HenFunctionMacro.macro_of(func_res, true))

	assert_str(finish.inputs[0].name).is_equal('ronald')
	assert_str(str(finish.inputs[0].type)).is_equal('float')
	# a value of the old type would emit a string into a float slot
	assert_object(finish.inputs[0].default_value).is_null()


# a slot the definition dropped takes what was feeding it along
func test_a_removed_output_drops_its_slot() -> void:
	var func_res: HenSaveFunc = _add_function('roll')
	var result: HenSaveParam = _add_output(func_res, 'result', &'float')
	var finish: HenSaveAction = _finish_action(func_res)

	finish.input_bindings[str(result.id)] = 'x'
	func_res.outputs = [] as Array[HenSaveParam]

	HenSaveAction.sync_action_inputs(finish, HenFunctionMacro.macro_of(func_res, true))

	assert_int(finish.inputs.size()).is_equal(0)
	assert_bool(finish.input_bindings.has(str(result.id))).is_false()


# a node slot left empty stands for the node the script sits on, which a function
# reaches as self and a state reaches as _ref
func test_a_node_slot_inside_a_function_falls_back_to_the_script_node() -> void:
	var func_res: HenSaveFunc = _add_function('tint')

	_function_step(func_res, _register(FIX_NODE_SLOT))

	assert_str(HenTest.get_all_code()).contains('func fn_tint() -> void:\n\tself.modulate =')


# the bind picker of a step inside a function has to offer the same sources a
# step in a state gets, the node running the script above all
func test_the_bind_picker_inside_a_function_offers_self() -> void:
	HenScriptMacroLoader.load_native_actions()

	var inspector := HenInspector.new()
	var func_res: HenSaveFunc = _add_function('tint')
	var param: HenSaveParam = _add_input(func_res, 'who', &'Node2D')
	var action: HenSaveAction = _function_step(func_res, _register(FIX_NODE_SLOT))
	var names: Array = _option_names(inspector, action, 'ref')

	assert_array(names).contains(['Self (this node)'])
	# and the inputs of the function it lives in, which is what makes one reusable
	assert_array(names).contains([param.name])

	inspector.free()


# the branch picker of a step inside a function only offers what a function may
# actually drive: the machine of another node, never its own script
func test_the_branch_picker_inside_a_function_offers_no_local_state() -> void:
	var inspector := HenInspector.new()
	var func_res: HenSaveFunc = _add_function('wake')
	var other: Dictionary = _other_script('Pop')
	var action: HenSaveAction = _function_step(func_res, _register(FIX_TRANSITION))

	# the picker reads the mapped scripts, which is where an open one is announced
	var ast: HenMapDependencies.ProjectAST = HenMapDependencies.ProjectAST.new()

	ast.identity = (other.save_data as HenSaveData).identity
	ast.states.assign((other.save_data as HenSaveData).states)
	(Engine.get_singleton(&'MapDependencies') as HenMapDependencies).ast_list.set(ast.identity.id, ast)

	save_data.add_state(false).name = 'Idle'
	inspector.edit(action)

	var names: Array = inspector._build_branch_options().map(func(o: Dictionary) -> String: return str(o.name))

	assert_array(names).not_contains(['Idle'])
	assert_array(names).contains(['Player / Pop'])

	inspector.free()


# a way out is stored by id, which survives a rename, and read by name, which is
# what the user wrote
func test_the_finish_shows_the_name_of_the_way_out() -> void:
	var func_res: HenSaveFunc = _add_function('look')
	var way: HenSaveFlowParam = func_res.get_new_flow_output()

	way.name = 'found it'

	var finish: HenSaveAction = _finish_action(func_res)
	var slot: HenSaveParam = finish.inputs[finish.inputs.size() - 1]

	assert_str(str(slot.default_value)).is_equal(str(way.id))
	assert_str(slot.option_label(slot.default_value)).is_equal('found it')

	var parts: Array[Dictionary] = HenActionsPanel.value_parts(finish, save_data)

	assert_str(str(parts[parts.size() - 1].value)).is_equal('found it')

	# renaming reaches the card without touching what the code emits
	way.name = 'spotted'

	HenSaveAction.sync_action_inputs(finish, HenFunctionMacro.macro_of(func_res, true))

	assert_str(str(finish.inputs[finish.inputs.size() - 1].default_value)).is_equal(str(way.id))
	assert_str(str(HenActionsPanel.value_parts(finish, save_data)[0].value)).is_equal('spotted')
	assert_str(HenTest.get_all_code()).contains("return &'" + str(way.id) + "'")


# renaming a way out has to reach the list the picker shows, not only the chip
func test_renaming_a_way_out_updates_the_option_list() -> void:
	var func_res: HenSaveFunc = _add_function('look')
	var first: HenSaveFlowParam = func_res.get_new_flow_output()
	var second: HenSaveFlowParam = func_res.get_new_flow_output()

	first.name = 'close'
	second.name = 'far'

	var finish: HenSaveAction = _finish_action(func_res)

	HenSaveAction.sync_action_inputs(finish, HenFunctionMacro.macro_of(func_res, true))

	second.name = 'way far'

	HenSaveAction.sync_action_inputs(finish, HenFunctionMacro.macro_of(func_res, true))

	var parts: Array[Dictionary] = HenActionsPanel.value_parts(finish, save_data)
	var branch_part: Dictionary = parts[parts.size() - 1]
	var slot_param: HenSaveParam = (branch_part.slot as Dictionary).param
	var listed: Array[String] = []

	for option: String in branch_part.options:
		listed.append(slot_param.option_label(option))

	assert_array(listed).is_equal(['close', 'way far'])


# renaming an entry of a list is an edit like any other: it has to be announced,
# or the cards keep drawing what the definition was called before
func test_renaming_a_way_out_is_announced() -> void:
	var func_res: HenSaveFunc = _add_function('look')
	var way: HenSaveFlowParam = func_res.get_new_flow_output()
	var inspector := HenInspector.new()
	var list: Node = (load('res://addons/hengo/scenes/props/array.tscn') as PackedScene).instantiate()

	way.name = 'close'
	add_child(inspector)
	inspector.add_child(list)
	list.setup(func_res, 'flow_outputs', func_res.flow_outputs, '24/17:HenSaveFlowParam')

	assert_bool(inspector._dirty).is_false()

	list._on_item_prop_changed(way, 'name', 'far', TYPE_STRING)

	assert_str(way.name).is_equal('far')
	assert_bool(inspector._dirty).is_true()

	inspector.free()
