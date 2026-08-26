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

		# read every declared output, or a pure producer skips with 'no output stored'
		for output: HenSaveParam in macro.outputs:
			_read_output(action, macro, output.id, any_out)

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

				var readers: Array[HenSaveAction] = []

				for output: HenSaveParam in macro.outputs:
					readers.append(_read_output(action, macro, output.id, any_out))

				for flow: HenSaveFlowParam in macro.flow_outputs:
					action.branches[str(flow.id)] = {state_id = target.id, label = ''}

				var code: String = HenTest.get_all_code()
				var where: String = str(macro.id) + ' / ' + value

				assert_str(code).override_failure_message('option ' + where + ' left an unresolved marker:\n' + code).not_contains('# hengo:')

				var script := GDScript.new()
				script.source_code = code
				assert_int(script.reload()).override_failure_message('option ' + where + ' does not compile:\n' + code).is_equal(OK)

				save_data.remove_state_action(state.id, action)

				for reader: HenSaveAction in readers:
					save_data.remove_state_action(state.id, reader)


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


# --- output scope -----------------------------------------------------------


# the declared branch of an output and the place its template emits it are two
# sources for one fact, so the sweep reads the body and refuses a disagreement
func test_every_output_declares_the_branch_it_is_emitted_in() -> void:
	HenScriptMacroLoader.load_native_actions()

	var checked: int = 0

	for macro: HenSaveMacro in HenHengoActions.pool():
		if macro.outputs.is_empty() or macro.flow_outputs.is_empty():
			continue

		var instance: HenScriptMacroBase = (load(macro.script_path) as GDScript).new()

		for phase: StringName in [&'enter', &'update', &'physics', &'exit']:
			var getter: String = 'get_flow_' + str(phase)

			if not instance.has_method(getter):
				continue

			var body: String = str(instance.call(getter))

			if body.is_empty():
				continue

			checked += _assert_body_matches_declaration(macro, instance, body)

	assert_int(checked).is_greater(0)


# emitted at the top level of the body it is reachable on every path, indented it
# belongs to whichever branch placeholder shares that indent
func _assert_body_matches_declaration(_macro: HenSaveMacro, _instance: HenScriptMacroBase, _body: String) -> int:
	var branch_at: Dictionary = {}
	var lines: PackedStringArray = _body.split('\n')
	var seen: int = 0

	for line: String in lines:
		var token: Dictionary = _placeholder_of(line)

		if token.is_empty() or token.is_output or branch_at.has(token.indent):
			continue

		branch_at[token.indent] = token.id

	for line: String in lines:
		var token: Dictionary = _placeholder_of(line)

		if token.is_empty() or not token.is_output:
			continue

		var expected: String = str(branch_at.get(token.indent, ''))
		var where: String = str(_macro.id) + ' / ' + token.id

		assert_str(str(_instance.output_branch(StringName(token.id)))) \
			.override_failure_message(where).is_equal(expected)
		seen += 1

	return seen


# a line holding nothing but one placeholder, as {indent, id, is_output}
func _placeholder_of(_line: String) -> Dictionary:
	var body: String = _line.rstrip(' \t')
	var indent: String = body.substr(0, body.length() - body.lstrip('\t').length())
	var token: String = body.lstrip('\t')

	if not token.begins_with('{{') or not token.ends_with('}}'):
		return {}

	var id: String = token.substr(2, token.length() - 4)

	if id.begins_with('out:'):
		return {indent = indent, id = id.substr(4), is_output = true}

	if id.begins_with('VCNODE') or id.contains(':'):
		return {}

	return {indent = indent, id = id, is_output = false}


# a Set Value wired to the output: the reader is what keeps a pure producer alive.
# an output written inside a branch only exists there, so the reader goes in with it
func _read_output(_producer: HenSaveAction, _macro: HenSaveMacro, _output: StringName, _target: HenSaveVar) -> HenSaveAction:
	var reader: HenSaveAction = HenSaveAction.create(HenActionsPanel.find_macro(&'set_value'))

	reader.phase = _producer.phase
	reader.input_bindings['target'] = HenUtils.bind_code_for_var(_target)
	reader.input_wires['value'] = {action_id = StringName(str(_producer.id)), output = _output}

	var instance: HenScriptMacroBase = (load(_macro.script_path) as GDScript).new()
	var branch: String = str(instance.output_branch(_output))

	if branch.is_empty():
		save_data.add_state_action(state.id, reader)

	return reader

	var steps: Array[HenSaveAction] = []

	steps.assign(HenGeneratorAction.branch_steps(_producer, branch))
	steps.append(reader)
	_producer.branch_actions[branch] = steps
