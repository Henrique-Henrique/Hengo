extends HenActionTestSuite

# sweeps the whole shipped pool: every action, on every owner and on every
# option value, has to generate code that compiles.

# --- new action batch -------------------------------------------------------


# every shipped action must produce a script that actually compiles
func test_shipped_actions_generate_compiling_code() -> void:
	_assert_whole_pool_compiles('CharacterBody2D')


# node3d/ is invisible to a 2d owner, so the pool has to be swept twice
func test_shipped_actions_generate_compiling_code_in_3d() -> void:
	_assert_whole_pool_compiles('Node3D')


# physics3d/ is hidden from every other owner, so it needs its own sweep
func test_shipped_actions_generate_compiling_code_for_a_3d_body() -> void:
	_assert_whole_pool_compiles('CharacterBody3D')


# physics3d/ also holds RigidBody3D-only actions (forces, velocity), hidden from
# the character bodies, so they get their own sweep too
func test_shipped_actions_generate_compiling_code_for_a_rigid_body() -> void:
	_assert_whole_pool_compiles('RigidBody3D')


# a macro whose actions only make sense inside a loop (break, continue)
func _needs_loop(_macro: HenSaveMacro) -> bool:
	return str(_macro.id) in ['break_loop', 'continue_loop']


func _assert_whole_pool_compiles(_owner: String) -> void:
	save_data.identity.type = _owner
	HenScriptMacroLoader.load_native_actions()

	var store: HenSaveVar = save_data.add_var(false)
	store.name = 'store'
	store.type = 'float'

	var list: HenSaveVar = save_data.add_var(false)
	list.name = 'items'
	list.type = 'Array'

	# a Variant var accepts any output type, so its generated declaration is untyped
	var any_out: HenSaveVar = save_data.add_var(false)
	any_out.name = 'any_out'
	any_out.type = 'Variant'

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'other state'

	for macro: HenSaveMacro in (Engine.get_singleton(&'Global') as HenGlobal).action_macros:
		if not macro.serves_class(StringName(_owner)):
			continue

		# break/continue only compile inside a loop body, so they can't ride the flat sweep
		if _needs_loop(macro):
			continue

		var action: HenSaveAction = _add_action(macro, HenSaveAction.default_phase(macro))

		# emit_signal alone requires a non-empty literal name; aim it at the signal above
		if str(macro.id) == 'emit_signal':
			for signal_param: HenSaveParam in action.inputs:
				if str(signal_param.id) == 'signal_name':
					signal_param.default_value = 'swept_signal'

		# every required slot gets a source, so the action is never skipped
		for param: HenSaveParam in action.inputs:
			if not param.lvalue and not param.bind_only:
				continue

			var bind: HenSaveVar = list if param.type == &'Array' else store
			action.input_bindings[str(param.id)] = HenUtils.bind_code_for_var(bind)

		# store every declared output, or a pure producer skips with 'no output stored'
		for output: HenSaveParam in macro.outputs:
			action.output_bindings[str(output.id)] = HenUtils.bind_code_for_var(any_out)

		for flow: HenSaveFlowParam in macro.flow_outputs:
			action.branches[str(flow.id)] = {state_id = target.id, label = ''}

	var code: String = HenTest.get_all_code()

	assert_str(code).override_failure_message('unresolved action for ' + _owner + ':\n' + code).not_contains('# hengo:')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).override_failure_message('generated code for ' + _owner + ' does not compile:\n' + code).is_equal(OK)


# the pool sweep only compiles each options input on its DEFAULT pick, so every
# other option string (method/function name) ships unverified. this re-emits
# each action once per option value, catching a typo at build time not runtime.
func test_every_option_compiles() -> void:
	_assert_every_option_compiles('CharacterBody2D')
	_assert_every_option_compiles('Node3D')
	_assert_every_option_compiles('CharacterBody3D')


func _assert_every_option_compiles(_owner: String) -> void:
	save_data.identity.type = _owner
	HenScriptMacroLoader.load_native_actions()

	# called once per owner in the same test, so drop what the previous owner added
	save_data.variables.clear()
	save_data.states = save_data.states.filter(func(s: HenSaveState) -> bool: return s == state)

	var list: HenSaveVar = save_data.add_var(false)
	list.name = 'items'
	list.type = 'Array'

	var any_out: HenSaveVar = save_data.add_var(false)
	any_out.name = 'any_out'
	any_out.type = 'Variant'

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'other state'

	for macro: HenSaveMacro in (Engine.get_singleton(&'Global') as HenGlobal).action_macros:
		if not macro.serves_class(StringName(_owner)):
			continue

		for opt_param: HenSaveParam in macro.inputs:
			if opt_param.options.is_empty():
				continue

			# emit the action once per option value; every other input is bound to a
			# variable so nothing folds (Math `/` with a literal 0 would parse-error)
			for value: String in opt_param.options:
				var action: HenSaveAction = _add_action(macro, HenSaveAction.default_phase(macro))

				for param: HenSaveParam in action.inputs:
					if str(param.id) == str(opt_param.id):
						param.default_value = value
					else:
						var bind: HenSaveVar = list if param.type == &'Array' else any_out
						action.input_bindings[str(param.id)] = HenUtils.bind_code_for_var(bind)

				for output: HenSaveParam in macro.outputs:
					action.output_bindings[str(output.id)] = HenUtils.bind_code_for_var(any_out)

				for flow: HenSaveFlowParam in macro.flow_outputs:
					action.branches[str(flow.id)] = {state_id = target.id, label = ''}

				var code: String = HenTest.get_all_code()
				var where: String = str(macro.id) + ' / ' + value

				assert_str(code).override_failure_message('option ' + where + ' left an unresolved marker:\n' + code).not_contains('# hengo:')

				var script := GDScript.new()
				script.source_code = code
				assert_int(script.reload()).override_failure_message('option ' + where + ' does not compile:\n' + code).is_equal(OK)

				save_data.remove_state_action(state.id, action)


# an expression on an assignment target would emit `(a + b) = value`, so it is
# refused the same way an unbound target is
func test_lvalue_input_refuses_an_expression() -> void:
	HenScriptMacroLoader.load_native_actions()

	var my_var: HenSaveVar = save_data.add_var(false)
	my_var.name = 'score'
	my_var.type = 'float'

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'set_value'), &'update')
	action.input_bindings['target'] = HenUtils.bind_code_for_var(my_var)
	action.input_expressions['target'] = _expression('a + b', ['a', 'b'], {}, {a = '1', b = '2'})

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('must be bound to a variable or property')
	assert_str(code).not_contains(') = ')
