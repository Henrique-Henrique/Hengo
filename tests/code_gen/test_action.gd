extends HenTestSuite

# covers the action system end to end at the codegen level: lifecycle phases,
# literal values, bindings (variable/property), expressions and type_from.

const FIX_PHASES: String = 'res://tests/fixtures/action_phases.gd'
const FIX_TYPED: String = 'res://tests/fixtures/action_typed.gd'
const FIX_PROCESS: String = 'res://tests/fixtures/action_process.gd'
const FIX_RAW: String = 'res://tests/fixtures/action_raw.gd'
const FIX_BRANCH: String = 'res://addons/hengo/actions/flow/if_condition.gd'
const FIX_TRANSITION: String = 'res://addons/hengo/actions/flow/transition.gd'
# single-output, multi-output and branching, one per inline case
const FIX_MATH: String = 'res://addons/hengo/actions/math/math_operator.gd'
const FIX_VEC_XY: String = 'res://addons/hengo/actions/vector/get_vector2_xy.gd'
const FIX_MOVE: String = 'res://addons/hengo/actions/physics2d/move_and_collide.gd'

var state: HenSaveState


func before_test() -> void:
	super()
	# a type that actually has float/vector props, so property binding has a target
	save_data.identity.type = 'Sprite2D'
	state = save_data.add_state(false)
	state.name = 'state test'


# mirrors HenScriptMacroLoader._load_macro_script so the tests exercise the real
# pool shape without depending on the native actions shipped with the addon
func _register(_path: String) -> HenSaveMacro:
	var instance: HenScriptMacroBase = (load(_path) as GDScript).new()
	var macro: HenSaveMacro = HenSaveMacro.new()

	macro.id = instance.get_id()
	macro.name = _path.get_file().get_basename()
	macro.is_script_macro = true
	macro.script_path = _path

	for input: Dictionary in instance.get_inputs():
		macro.inputs.append(HenSaveParam.create(input))

	for flow: Dictionary in instance.get_flow_inputs():
		macro.flow_inputs.append(HenSaveFlowParam.create(flow))

	for flow: Dictionary in instance.get_flow_outputs():
		macro.flow_outputs.append(HenSaveFlowParam.create(flow))

	macro.target_classes.assign(instance.get_target_classes())

	(Engine.get_singleton(&'Global') as HenGlobal).action_macros.append(macro)
	return macro


func _add_action(_macro: HenSaveMacro, _phase: StringName) -> HenSaveAction:
	var action: HenSaveAction = HenSaveAction.create(_macro)
	action.phase = _phase
	save_data.add_state_action(state.id, action)
	return action


func _expression(_code: String, _words: Array, _bindings: Dictionary, _literals: Dictionary) -> HenSaveActionExpression:
	var expr: HenSaveActionExpression = HenSaveActionExpression.new()
	expr.code = _code

	var words: Array[HenSaveParam] = []
	for word_name: String in _words:
		var param: HenSaveParam = HenSaveParam.create({name = word_name, type = 'Variant'})
		if _literals.has(word_name):
			param.default_value = _literals[word_name]
		words.append(param)

	expr.words = words
	expr.word_bindings = _bindings
	return expr


# --- lifecycle phases -------------------------------------------------------


func test_action_runs_in_update() -> void:
	_add_action(_register(FIX_PHASES), &'update')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('class StateTest extends HengoState:\n\tfunc update(delta) -> void:\n\t\tsuper(delta)\n\t\ttest_update("hi")')


# enter has no base method, so it must NOT call super()
func test_action_runs_in_enter_without_super() -> void:
	_add_action(_register(FIX_PHASES), &'enter')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('func enter() -> void:\n\t\ttest_enter("hi")')


# exit MUST call super() — HengoState.exit tears down current_sub_state
func test_action_runs_in_exit_with_super() -> void:
	_add_action(_register(FIX_PHASES), &'exit')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('func exit() -> void:\n\t\tsuper()\n\t\ttest_exit("hi")')


func test_actions_split_across_phases() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)
	_add_action(macro, &'enter')
	_add_action(macro, &'update')
	_add_action(macro, &'exit')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('func enter() -> void:\n\t\ttest_enter("hi")')
	assert_str(code).contains('func update(delta) -> void:\n\t\tsuper(delta)\n\t\ttest_update("hi")')
	assert_str(code).contains('func exit() -> void:\n\t\tsuper()\n\t\ttest_exit("hi")')


# --- ordering ---------------------------------------------------------------


# emission follows the list order inside a phase, so reordering rewrites the body
func test_actions_emit_in_list_order() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)

	for value: String in ['a', 'b', 'c']:
		_add_action(macro, &'update').inputs[0].default_value = value

	assert_str(HenTest.get_all_code()).contains('test_update("a")\n\t\ttest_update("b")\n\t\ttest_update("c")')


func test_reorder_moves_action_inside_phase() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)
	var actions: Array[HenSaveAction] = []

	for value: String in ['a', 'b', 'c']:
		var action: HenSaveAction = _add_action(macro, &'update')
		action.inputs[0].default_value = value
		actions.append(action)

	var moved: Array = HenActionsPanel.reorder(save_data.get_state_actions(state.id), actions[2], &'update', 0)
	save_data.set_state_actions(state.id, moved)

	assert_str(HenTest.get_all_code()).contains('test_update("c")\n\t\ttest_update("a")\n\t\ttest_update("b")')


# a move across phases changes where the line is emitted, not just its position
func test_reorder_moves_action_to_another_phase() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)
	var action: HenSaveAction = _add_action(macro, &'update')

	action.phase = &'enter'
	save_data.set_state_actions(state.id, HenActionsPanel.reorder(save_data.get_state_actions(state.id), action, &'enter', 0))

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('func enter() -> void:\n\t\ttest_enter("hi")')
	assert_str(code).not_contains('test_update(')


# dropping below a row above the dragged one still lands right under that row
func test_drop_index_ignores_the_dragged_action() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)
	var first: HenSaveAction = _add_action(macro, &'update')
	var second: HenSaveAction = _add_action(macro, &'update')
	var third: HenSaveAction = _add_action(macro, &'update')

	var actions: Array = save_data.get_state_actions(state.id)

	assert_int(HenActionsPanel.drop_index(actions, first, third, true)).is_equal(0)
	assert_int(HenActionsPanel.drop_index(actions, first, third, false)).is_equal(1)
	assert_int(HenActionsPanel.drop_index(actions, second, third, false)).is_equal(2)

	# a drop onto a row of another phase counts inside that phase only
	second.phase = &'enter'
	assert_int(HenActionsPanel.drop_index(actions, second, third, true)).is_equal(0)


# the flat list is normalized to the order codegen emits the phases in
func test_reorder_keeps_phases_in_run_order() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)
	var exit_action: HenSaveAction = _add_action(macro, &'exit')
	var enter_action: HenSaveAction = _add_action(macro, &'enter')

	var ordered: Array = HenActionsPanel.reorder(save_data.get_state_actions(state.id), enter_action, &'enter', 0)

	assert_array(ordered).is_equal([enter_action, exit_action])


# a state with no actions must stay empty (no stray lifecycle methods)
func test_state_without_actions_stays_empty() -> void:
	var code: String = HenTest.get_all_code()

	assert_str(code).contains('class StateTest extends HengoState:\n\tpass')


# --- value sources ----------------------------------------------------------


func test_action_emits_literal_value() -> void:
	var action: HenSaveAction = _add_action(_register(FIX_PHASES), &'update')
	action.inputs[0].default_value = 'custom'

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('test_update("custom")')


# _ref is untyped, so only declaration + usage together prove the variable exists
func test_action_bound_to_variable() -> void:
	var my_var: HenSaveVar = save_data.add_var(false)
	my_var.name = 'my_speed'
	my_var.type = 'float'

	var action: HenSaveAction = _add_action(_register(FIX_PHASES), &'update')
	action.input_bindings['value'] = 'my_speed'

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('var my_speed')
	assert_str(code).contains('test_update(_ref.my_speed)')


func test_action_bound_to_property() -> void:
	var action: HenSaveAction = _add_action(_register(FIX_PHASES), &'update')
	action.input_bindings['value'] = 'rotation'

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('test_update(_ref.rotation)')


# the binding stores the variable id, so the emitted code follows a rename
func test_binding_follows_variable_rename() -> void:
	var my_var: HenSaveVar = save_data.add_var(false)
	my_var.name = 'my_speed'
	my_var.type = 'float'

	var action: HenSaveAction = _add_action(_register(FIX_PHASES), &'update')
	action.input_bindings['value'] = HenUtils.bind_code_for_var(my_var)

	my_var.name = 'run speed'

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('var run_speed')
	assert_str(code).contains('test_update(_ref.run_speed)')


# a binding substitutes mid-expression, so a deleted variable takes the whole
# action out instead of leaving `test_update(_ref.)` behind
func test_binding_to_deleted_variable_skips_the_action() -> void:
	var my_var: HenSaveVar = save_data.add_var(false)
	my_var.name = 'my_speed'
	my_var.type = 'float'

	var action: HenSaveAction = _add_action(_register(FIX_PHASES), &'update')
	action.input_bindings['value'] = HenUtils.bind_code_for_var(my_var)

	save_data.variables.erase(my_var)

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('binds a variable that no longer exists')
	assert_str(code).not_contains('test_update(')


func test_expression_word_binding_follows_rename() -> void:
	var my_var: HenSaveVar = save_data.add_var(false)
	my_var.name = 'spin'
	my_var.type = 'float'

	var action: HenSaveAction = _add_action(_register(FIX_PHASES), &'update')
	action.input_expressions['value'] = _expression('a + b', ['a', 'b'], {a = HenUtils.bind_code_for_var(my_var)}, {b = '2'})

	my_var.name = 'spin speed'

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('test_update((_ref.spin_speed + 2))')


# opening an action upgrades bindings saved by name; property binds keep their name
func test_opening_an_action_migrates_name_bindings() -> void:
	var my_var: HenSaveVar = save_data.add_var(false)
	my_var.name = 'my_speed'
	my_var.type = 'float'

	var expected: String = HenUtils.bind_code_for_var(my_var)
	var other: Dictionary = _other_script('hurt')

	var action: HenSaveAction = _add_action(_register(FIX_PHASES), &'update')
	action.input_bindings['value'] = 'my_speed'
	action.input_bindings['angle'] = 'rotation'
	action.input_expressions['other'] = _expression('a', ['a'], {a = 'my_speed'}, {})
	action.branches['to'] = _cross_branch('to', other, {instance_bind = 'my_speed'})

	HenInspector._migrate_name_bindings(action)

	assert_str(str(action.input_bindings['value'])).is_equal(expected)
	assert_str(str(action.input_bindings['angle'])).is_equal('rotation')
	assert_str(str((action.input_expressions['other'] as HenSaveActionExpression).word_bindings['a'])).is_equal(expected)
	assert_str(str((action.branches['to'] as Dictionary).instance_bind)).is_equal(expected)

	# migrating an already migrated action changes nothing
	HenInspector._migrate_name_bindings(action)

	assert_str(str(action.input_bindings['value'])).is_equal(expected)


func test_expression_word_bound_to_deleted_variable_skips_the_action() -> void:
	var my_var: HenSaveVar = save_data.add_var(false)
	my_var.name = 'spin'
	my_var.type = 'float'

	var action: HenSaveAction = _add_action(_register(FIX_PHASES), &'update')
	action.input_expressions['value'] = _expression('a + b', ['a', 'b'], {a = HenUtils.bind_code_for_var(my_var)}, {b = '2'})

	save_data.variables.erase(my_var)

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('binds a variable that no longer exists')
	assert_str(code).not_contains('test_update(')


func test_action_expression_substitutes_words() -> void:
	var my_var: HenSaveVar = save_data.add_var(false)
	my_var.name = 'spin'
	my_var.type = 'float'

	var action: HenSaveAction = _add_action(_register(FIX_PHASES), &'update')
	action.input_expressions['value'] = _expression('a + b', ['a', 'b'], {a = 'spin'}, {b = '2'})

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('test_update((_ref.spin + 2))')


# word 'a' resolves to a value containing word 'b' — a sequential pass would
# rewrite the b inside _ref.b, so substitution has to be single-pass
func test_action_expression_substitution_is_single_pass() -> void:
	var action: HenSaveAction = _add_action(_register(FIX_PHASES), &'update')
	action.input_expressions['value'] = _expression('a + b', ['a', 'b'], {a = 'b'}, {b = '9'})

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('test_update((_ref.b + 9))')


# Value declares type_from = target, so binding Target to a float var makes the
# literal emit unquoted (a Variant input would emit "45" and break arithmetic)
func test_action_value_type_follows_target_binding() -> void:
	var my_var: HenSaveVar = save_data.add_var(false)
	my_var.name = 'my_speed'
	my_var.type = 'float'

	var action: HenSaveAction = _add_action(_register(FIX_TYPED), &'update')
	action.input_bindings['target'] = 'my_speed'
	action.inputs[1].default_value = 45.0

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref.my_speed = 45')


# --- inline actions ---------------------------------------------------------


func _math_child(_a: Variant, _op: String, _b: Variant) -> HenSaveAction:
	var child: HenSaveAction = HenSaveAction.create(_register(FIX_MATH))

	for param: HenSaveParam in child.inputs:
		match str(param.id):
			'a': param.default_value = _a
			'op': param.default_value = _op
			'b': param.default_value = _b

	return child


func test_inline_action_feeds_input() -> void:
	var parent: HenSaveAction = _add_action(_register(FIX_PHASES), &'update')
	parent.input_actions['value'] = {action = _math_child(3.0, '*', 2.0), output = &'result'}

	assert_str(HenTest.get_all_code()).contains('test_update((3.0 * 2.0))')


func test_inline_action_wins_over_binding() -> void:
	var v: HenSaveVar = save_data.add_var(false)
	v.name = 'my_speed'
	v.type = 'float'

	var parent: HenSaveAction = _add_action(_register(FIX_PHASES), &'update')
	parent.input_bindings['value'] = HenUtils.bind_code_for_var(v)
	parent.input_actions['value'] = {action = _math_child(1.0, '+', 1.0), output = &'result'}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('test_update((1.0 + 1.0))')
	assert_str(code).not_contains('test_update(_ref.my_speed)')


func test_inline_multi_output_picks_the_chosen_one() -> void:
	var vec: HenSaveVar = save_data.add_var(false)
	vec.name = 'aim'
	vec.type = 'Vector2'

	var child: HenSaveAction = HenSaveAction.create(_register(FIX_VEC_XY))
	child.input_bindings['vector'] = HenUtils.bind_code_for_var(vec)

	var parent: HenSaveAction = _add_action(_register(FIX_PHASES), &'update')
	parent.input_actions['value'] = {action = child, output = &'y'}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('test_update((_ref.aim.y))')
	assert_str(code).not_contains('.x')


func test_inline_defaults_to_sole_output() -> void:
	var parent: HenSaveAction = _add_action(_register(FIX_PHASES), &'update')
	parent.input_actions['value'] = {action = _math_child(5.0, '-', 1.0), output = &''}

	assert_str(HenTest.get_all_code()).contains('test_update((5.0 - 1.0))')


func test_inline_action_nests() -> void:
	var outer: HenSaveAction = HenSaveAction.create(_register(FIX_MATH))

	for param: HenSaveParam in outer.inputs:
		match str(param.id):
			'op': param.default_value = '+'
			'b': param.default_value = 1.0

	outer.input_actions['a'] = {action = _math_child(2.0, '*', 3.0), output = &'result'}

	var parent: HenSaveAction = _add_action(_register(FIX_PHASES), &'update')
	parent.input_actions['value'] = {action = outer, output = &'result'}

	assert_str(HenTest.get_all_code()).contains('test_update(((2.0 * 3.0) + 1.0))')


func test_inline_broken_binding_skips_parent() -> void:
	var v: HenSaveVar = save_data.add_var(false)
	v.name = 'gone'
	v.type = 'float'

	var child: HenSaveAction = _math_child(0.0, '+', 1.0)
	child.input_bindings['a'] = HenUtils.bind_code_for_var(v)

	var parent: HenSaveAction = _add_action(_register(FIX_PHASES), &'update')
	parent.input_actions['value'] = {action = child, output = &'result'}

	save_data.variables.erase(v)

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('binds a variable that no longer exists')
	assert_str(code).not_contains('test_update(')


# inlining it would re-run the work per use and drop its flow
func test_inline_refuses_a_branching_action() -> void:
	var child: HenSaveAction = HenSaveAction.create(_register(FIX_MOVE))

	var parent: HenSaveAction = _add_action(_register(FIX_PHASES), &'update')
	parent.input_actions['value'] = {action = child, output = &'collider'}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('not a pure value producer')
	assert_str(code).not_contains('test_update(')


func test_inline_action_round_trips() -> void:
	var child: HenSaveAction = _math_child(4.0, '/', 2.0)
	var parent: HenSaveAction = _add_action(_register(FIX_PHASES), &'update')
	parent.input_actions['value'] = {action = child, output = &'result'}

	var path: String = 'user://test_inline_action.res'
	assert_int(ResourceSaver.save(parent, path)).is_equal(OK)

	var loaded: HenSaveAction = ResourceLoader.load(path, '', ResourceLoader.CACHE_MODE_IGNORE_DEEP) as HenSaveAction

	assert_bool(loaded.input_actions.has('value')).is_true()

	var ref: Dictionary = loaded.input_actions['value']
	assert_str(str(ref.get('output', ''))).is_equal('result')

	var reloaded_child: HenSaveAction = ref.get('action')
	assert_object(reloaded_child).is_not_null()
	assert_str(str(reloaded_child.macro_id)).is_equal('math_operator')

	DirAccess.remove_absolute(path)


func test_inline_action_code_compiles() -> void:
	HenScriptMacroLoader.load_native_actions()

	var score: HenSaveVar = save_data.add_var(false)
	score.name = 'score'
	score.type = 'float'

	var parent: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'set_value'), &'update')
	parent.input_bindings['target'] = HenUtils.bind_code_for_var(score)
	parent.input_actions['value'] = {action = _math_child(3.0, '+', 4.0), output = &'result'}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref.score = (3.0 + 4.0)')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).override_failure_message('inline action code does not compile:\n' + code).is_equal(OK)


func test_action_cascade_script_parses() -> void:
	var script: GDScript = load('res://addons/hengo/scripts/side_bar/action_cascade.gd')

	assert_object(script).is_not_null()
	assert_bool(script.can_instantiate()).is_true()


func test_nested_producer_inspector_renders_inputs_only() -> void:
	_register(FIX_MATH)

	var child: HenSaveAction = _math_child(1.0, '+', 2.0)
	var inspector: HenInspector = load('res://addons/hengo/scenes/custom_inspector.tscn').instantiate()
	inspector.nested_producer = true
	inspector.hide_phase = true
	inspector.edit(child, '', [])

	var labels: Array = _collect_labels(inspector.vbox)

	assert_bool(labels.has('A')).is_true()
	assert_bool(labels.has('B')).is_true()
	assert_bool(labels.has('Outputs')).is_false()
	assert_bool(labels.has('Phase')).is_false()

	inspector.free()


func _collect_labels(node: Node) -> Array:
	var out: Array = []

	for child: Node in node.get_children():
		if child is Label:
			out.append((child as Label).text)

		out.append_array(_collect_labels(child))

	return out


func test_cascade_open_level_builds_panel() -> void:
	_register(FIX_MATH)

	var parent: HenSaveAction = _add_action(_register(FIX_PHASES), &'update')
	parent.input_actions['value'] = {action = _math_child(1.0, '+', 2.0), output = &'result'}

	var slot: Dictionary = {
		param = parent.inputs[0],
		bind_store = parent.input_bindings,
		bind_key = 'value',
		expr_store = parent.input_expressions,
		expr_key = 'value',
		action_store = parent.input_actions,
		action_key = 'value',
		macro_params = {},
		indent = 0
	}

	var cascade: HenActionCascade = HenActionCascade.new()
	add_child(cascade)
	auto_free(cascade)

	# no source inspector: the highlight is skipped, the panel still builds
	cascade._open_level(0, slot, null)

	assert_int(cascade._levels.size()).is_equal(1)

	var labels: Array = _collect_labels((cascade._levels[0].inspector as HenInspector).vbox)
	assert_bool(labels.has('A')).is_true()
	assert_bool(labels.has('B')).is_true()

	# a second open at the same index replaces, never stacks
	cascade._open_level(0, slot, null)
	assert_int(cascade._levels.size()).is_equal(1)


# also proves is_inlinable runs on a cold instance (target_class never primed)
func test_producer_palette_filters_to_inlinable() -> void:
	save_data.identity.type = 'CharacterBody2D'
	HenScriptMacroLoader.load_native_actions()

	var search: HenActionsSearch = auto_free(load('res://addons/hengo/scenes/actions_search.tscn').instantiate())
	search.setup(state.id)
	search.setup_producer_picker('Variant', func(_m: HenSaveMacro) -> void: pass )

	var ids: Array = []
	for macro: HenSaveMacro in search._get_pool():
		ids.append(str(macro.id))

	assert_bool(ids.has('math_operator')).is_true()
	assert_bool(ids.has('get_vector2_xy')).is_true()

	assert_bool(ids.has('move_and_collide')).is_false()
	assert_bool(ids.has('if_condition')).is_false()


func test_producer_palette_filters_by_output_type() -> void:
	save_data.identity.type = 'CharacterBody2D'
	HenScriptMacroLoader.load_native_actions()

	var search: HenActionsSearch = auto_free(load('res://addons/hengo/scenes/actions_search.tscn').instantiate())
	search.setup(state.id)
	search.setup_producer_picker('Vector2', func(_m: HenSaveMacro) -> void: pass )

	var ids: Array = []
	for macro: HenSaveMacro in search._get_pool():
		ids.append(str(macro.id))

	# get_vector2_xy only outputs floats, so it cannot feed a Vector2 slot
	assert_bool(ids.has('get_vector2_xy')).is_false()
	# math is Variant-typed, which fits any slot
	assert_bool(ids.has('math_operator')).is_true()


# --- macro body resolution --------------------------------------------------


# a macro with no flow inputs still works on update via its _process override
func test_action_falls_back_to_process_body_on_update() -> void:
	_add_action(_register(FIX_PROCESS), &'update')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('test_process(90')


# never drop silently: a phase the macro has no body for leaves a visible marker
func test_action_without_phase_body_emits_marker() -> void:
	_add_action(_register(FIX_PROCESS), &'enter')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('has no enter body')


# a raw input is a code fragment: emitted verbatim while its quoted twin isn't
func test_raw_input_is_not_quoted() -> void:
	var action: HenSaveAction = _add_action(_register(FIX_RAW), &'update')
	action.inputs[0].default_value = '_ref.queue_free()'
	action.inputs[1].default_value = '_ref.queue_free()'

	var code: String = HenTest.get_all_code()

	assert_str(code).contains("test_raw(_ref.queue_free(), '_ref.queue_free()')")


# --- branches ---------------------------------------------------------------


func _if_action(_phase: StringName) -> HenSaveAction:
	var action: HenSaveAction = _add_action(_register(FIX_BRANCH), _phase)
	action.input_bindings['condition'] = 'is_dead'
	return action


func test_branch_to_sibling_state() -> void:
	var dead: HenSaveState = save_data.add_state(false)
	dead.name = 'dead'

	var action: HenSaveAction = _if_action(&'update')
	action.branches['true'] = {state_id = dead.id, label = 'morreu'}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('if _ref.is_dead:\n\t\t\t_ref._STATE_CONTROLLER.change_state("dead")\n\t\telse:\n\t\t\tpass')


# a child of the owning state goes through the parent, not the controller
func test_branch_to_sub_state() -> void:
	state.add_sub_state(save_data)
	var child: HenSaveState = state.get_sub_states(save_data).get(0)
	child.name = 'child state'

	var action: HenSaveAction = _if_action(&'update')
	action.branches['false'] = {state_id = child.id, label = ''}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref._STATE_CONTROLLER.current_state.change_sub_state("child_state")')


func test_branch_both_sides() -> void:
	var dead: HenSaveState = save_data.add_state(false)
	dead.name = 'dead'
	var idle: HenSaveState = save_data.add_state(false)
	idle.name = 'idle'

	var action: HenSaveAction = _if_action(&'update')
	action.branches['true'] = {state_id = dead.id, label = 'morreu'}
	action.branches['false'] = {state_id = idle.id, label = ''}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref._STATE_CONTROLLER.change_state("dead")')
	assert_str(code).contains('_ref._STATE_CONTROLLER.change_state("idle")')


# a target deleted after being bound must not emit a dangling call
func test_branch_with_stale_target_falls_back_to_pass() -> void:
	var action: HenSaveAction = _if_action(&'update')
	action.branches['true'] = {state_id = &'9999', label = ''}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('no branch target set')


# an if that goes nowhere is a misconfiguration, not an empty block
func test_branch_without_any_target_emits_marker() -> void:
	_if_action(&'update')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('no branch target set')


# the row preview shows where each configured branch goes
func test_branch_shows_in_row_preview() -> void:
	var dead: HenSaveState = save_data.add_state(false)
	dead.name = 'dead'

	var macro: HenSaveMacro = _register(FIX_BRANCH)
	var action: HenSaveAction = HenSaveAction.create(macro)
	save_data.add_state_action(state.id, action)
	action.branches['true'] = {state_id = dead.id, label = 'morreu'}

	var parts: Array[Dictionary] = HenActionsPanel.branch_parts(action, macro)

	assert_int(parts.size()).is_equal(1)
	assert_str(str(parts[0].kind)).is_equal('branch')
	assert_str(str(parts[0].value)).is_equal('-> dead')


# change_state runs exit() before swapping current_state, so transitioning from
# exit would re-enter it forever: the phase must be refused, not generated
func test_branch_is_refused_on_exit() -> void:
	var dead: HenSaveState = save_data.add_state(false)
	dead.name = 'dead'

	var macro: HenSaveMacro = _register(FIX_BRANCH)
	var action: HenSaveAction = _add_action(macro, &'exit')
	action.branches['true'] = {state_id = dead.id, label = ''}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('cannot run on exit')
	assert_str(code).not_contains('func exit() -> void:\n\t\tsuper()\n\t\tif')

	# and the inspector must not offer the phase in the first place
	assert_bool(HenSaveAction.supported_phases(macro).has(&'exit')).is_false()
	assert_bool(HenSaveAction.supported_phases(macro).has(&'enter')).is_true()


# string asserts pin the indentation, but only a real compile proves the block is valid
func test_branch_code_compiles() -> void:
	var dead: HenSaveState = save_data.add_state(false)
	dead.name = 'dead'

	var action: HenSaveAction = _if_action(&'update')
	action.branches['true'] = {state_id = dead.id, label = ''}

	var script := GDScript.new()
	script.source_code = HenTest.get_all_code()

	assert_int(script.reload()).is_equal(OK)


# the custom branch name is what labels the arrow in the state viewer
func test_branch_feeds_state_viewer_edges() -> void:
	var dead: HenSaveState = save_data.add_state(false)
	dead.name = 'dead'
	var idle: HenSaveState = save_data.add_state(false)
	idle.name = 'idle'

	var action: HenSaveAction = _if_action(&'update')
	action.branches['true'] = {state_id = dead.id, label = 'colidiu com player'}
	action.branches['false'] = {state_id = idle.id, label = ''}

	# the edges come from save_data alone, with no view involved
	var on_dict: Dictionary = {}
	HenStateGraphSource.add_branch_edges(state, save_data, on_dict, {})

	assert_str(str(on_dict.get('colidiu com player', ''))).is_equal('dead')
	# no custom name falls back to the same shape the transition nodes use
	assert_str(str(on_dict.get('go_to_idle', ''))).is_equal('idle')


# --- transition action ------------------------------------------------------


# a second script the transition can target, registered as if it were open
func _other_script(_state_name: String) -> Dictionary:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var other: HenSaveData = HenSaveData.new()

	other.identity = HenSaveDataIdentity.create(str(ResourceUID.create_id()), 'Node', 'Player')
	other.counter = 1

	var target: HenSaveState = HenSaveState.new()
	target.id = StringName('other_' + _state_name)
	target.name = _state_name
	other.states.append(target)

	global.OPEN_SCRIPTS.append(other)

	return {save_data = other, state = target}


func test_transition_goes_to_a_state() -> void:
	var dead: HenSaveState = save_data.add_state(false)
	dead.name = 'dead'

	var action: HenSaveAction = _add_action(_register(FIX_TRANSITION), &'update')
	action.branches['to'] = {state_id = dead.id, label = ''}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('func update(delta) -> void:\n\t\tsuper(delta)\n\t\t_ref._STATE_CONTROLLER.change_state("dead")')


func test_transition_goes_to_a_sub_state() -> void:
	state.add_sub_state(save_data)
	var child: HenSaveState = state.get_sub_states(save_data).get(0)
	child.name = 'child state'

	var action: HenSaveAction = _add_action(_register(FIX_TRANSITION), &'update')
	action.branches['to'] = {state_id = child.id, label = ''}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref._STATE_CONTROLLER.current_state.change_sub_state("child_state")')


# the bound instance is the prefix, so the other node's machine is the one driven
func test_transition_goes_to_another_script_state() -> void:
	var other: Dictionary = _other_script('hurt')

	var action: HenSaveAction = _add_action(_register(FIX_TRANSITION), &'update')
	action.branches['to'] = {
		state_id = other.state.id,
		script_id = other.save_data.identity.id,
		instance_bind = 'target_player',
		label = ''
	}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref.target_player._STATE_CONTROLLER.change_state("hurt")')


# without the instance there is nothing to call change_state on
func test_cross_script_branch_without_instance_emits_marker() -> void:
	var other: Dictionary = _other_script('hurt')

	var action: HenSaveAction = _add_action(_register(FIX_TRANSITION), &'update')
	action.branches['to'] = {
		state_id = other.state.id,
		script_id = other.save_data.identity.id,
		label = ''
	}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('missing target instance connection')
	assert_str(code).not_contains('change_state("hurt")')


# any branching action takes cross-script targets, not just the transition
func test_if_branch_goes_to_another_script_state() -> void:
	var other: Dictionary = _other_script('dead')

	var action: HenSaveAction = _if_action(&'update')
	action.branches['true'] = {
		state_id = other.state.id,
		script_id = other.save_data.identity.id,
		instance_bind = 'target_player',
		label = ''
	}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('if _ref.is_dead:\n\t\t\t_ref.target_player._STATE_CONTROLLER.change_state("dead")')


# it transitions on its own, so it may never run on exit
func test_transition_phases() -> void:
	var macro: HenSaveMacro = _register(FIX_TRANSITION)

	assert_array(HenSaveAction.supported_phases(macro)).is_equal([&'enter', &'update'])
	assert_str(str(HenSaveAction.default_phase(macro))).is_equal('update')


# --- instance source ---------------------------------------------------------


func _cross_branch(_key: String, _other: Dictionary, _extra: Dictionary) -> Dictionary:
	var branch: Dictionary = {
		state_id = _other.state.id,
		script_id = _other.save_data.identity.id,
		label = ''
	}
	branch.merge(_extra)
	return branch


# a node path keeps no reference around: it resolves at the call site
func test_instance_from_node_path() -> void:
	var other: Dictionary = _other_script('hurt')

	var action: HenSaveAction = _add_action(_register(FIX_TRANSITION), &'update')
	action.branches['to'] = _cross_branch('to', other, {instance_path = '%Player'})

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref.get_node("%Player")._STATE_CONTROLLER.change_state("hurt")')


func test_instance_check_guards_a_bound_variable() -> void:
	var other: Dictionary = _other_script('hurt')

	var action: HenSaveAction = _add_action(_register(FIX_TRANSITION), &'update')
	action.branches['to'] = _cross_branch('to', other, {instance_bind = 'target_player', check_instance = true})

	var code: String = HenTest.get_all_code()
	var temp: String = '__hg_' + str(action.id) + '_to'

	assert_str(code).contains('var ' + temp + ' = _ref.target_player')
	assert_str(code).contains('if is_instance_valid(' + temp + ') and "_STATE_CONTROLLER" in ' + temp + ':')
	assert_str(code).contains('\t' + temp + '._STATE_CONTROLLER.change_state("hurt")')


# the instance is bound by id as well, so a rename can't break the transition
func test_instance_binding_follows_variable_rename() -> void:
	var other: Dictionary = _other_script('hurt')
	var target: HenSaveVar = save_data.add_var(false)
	target.name = 'target_player'
	target.type = 'Node2D'

	var action: HenSaveAction = _add_action(_register(FIX_TRANSITION), &'update')
	action.branches['to'] = _cross_branch('to', other, {instance_bind = HenUtils.bind_code_for_var(target)})

	target.name = 'enemy ref'

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref.enemy_ref._STATE_CONTROLLER.change_state("hurt")')


# a deleted instance variable leaves the branch with no receiver
func test_instance_binding_to_deleted_variable_emits_marker() -> void:
	var other: Dictionary = _other_script('hurt')
	var target: HenSaveVar = save_data.add_var(false)
	target.name = 'target_player'
	target.type = 'Node2D'

	var action: HenSaveAction = _add_action(_register(FIX_TRANSITION), &'update')
	action.branches['to'] = _cross_branch('to', other, {instance_bind = HenUtils.bind_code_for_var(target)})

	save_data.variables.erase(target)

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('missing target instance connection')
	assert_str(code).not_contains('change_state("hurt")')


# the guarded path resolves once into the temp, and a missing node must not push an error
func test_instance_check_uses_get_node_or_null() -> void:
	var other: Dictionary = _other_script('hurt')

	var action: HenSaveAction = _add_action(_register(FIX_TRANSITION), &'update')
	action.branches['to'] = _cross_branch('to', other, {instance_path = '%Player', check_instance = true})

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('var __hg_' + str(action.id) + '_to = _ref.get_node_or_null("%Player")')
	assert_int(code.count('get_node_or_null')).is_equal(1)


# string asserts pin the tabs, only a compile proves the guard block nests right
func test_guarded_branch_inside_if_compiles() -> void:
	var other: Dictionary = _other_script('dead')

	var action: HenSaveAction = _if_action(&'update')
	action.branches['true'] = _cross_branch('true', other, {instance_path = '%Player', check_instance = true})

	var script := GDScript.new()
	script.source_code = HenTest.get_all_code()

	assert_int(script.reload()).is_equal(OK)


# an empty path is as unset as no source at all
func test_empty_node_path_emits_marker() -> void:
	var other: Dictionary = _other_script('hurt')

	var action: HenSaveAction = _add_action(_register(FIX_TRANSITION), &'update')
	action.branches['to'] = _cross_branch('to', other, {instance_path = ''})

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('missing target instance connection')


# the new branch keys must survive ResourceSaver like state_id/script_id do
func test_instance_source_round_trips() -> void:
	var other: Dictionary = _other_script('hurt')

	var action: HenSaveAction = _add_action(_register(FIX_TRANSITION), &'update')
	action.branches['to'] = _cross_branch('to', other, {instance_path = '%Player', check_instance = true})

	var path: String = 'user://test_action_branch.res'
	assert_int(ResourceSaver.save(action, path)).is_equal(OK)

	var loaded: HenSaveAction = ResourceLoader.load(path, '', ResourceLoader.CACHE_MODE_IGNORE_DEEP) as HenSaveAction
	var branch: Dictionary = loaded.branches['to']

	assert_str(str(branch.get('instance_path', ''))).is_equal('%Player')
	assert_bool(bool(branch.get('check_instance', false))).is_true()

	DirAccess.remove_absolute(path)


# a var holds the target when either type inherits the other; only siblings fail
func test_can_hold_instance_of_matrix() -> void:
	assert_bool(HenUtils.can_hold_instance_of(&'CharacterBody2D', &'CharacterBody2D')).is_true()
	assert_bool(HenUtils.can_hold_instance_of(&'Node2D', &'CharacterBody2D')).is_true()
	assert_bool(HenUtils.can_hold_instance_of(&'Node', &'CharacterBody2D')).is_true()

	# a script extending Node can be attached to a Sprite2D, so that var is valid
	assert_bool(HenUtils.can_hold_instance_of(&'Sprite2D', &'Node')).is_true()

	# sibling branches can never point at the same node
	assert_bool(HenUtils.can_hold_instance_of(&'Sprite2D', &'CharacterBody2D')).is_false()
	assert_bool(HenUtils.can_hold_instance_of(&'RigidBody2D', &'CharacterBody2D')).is_false()
	assert_bool(HenUtils.can_hold_instance_of(&'Control', &'Node2D')).is_false()
	assert_bool(HenUtils.can_hold_instance_of(&'int', &'CharacterBody2D')).is_false()

	# an unknown target class must not empty the picker
	assert_bool(HenUtils.can_hold_instance_of(&'Variant', &'MyCustomBase')).is_true()

	# every new variable is born Variant — dropping those would read as a bug
	assert_bool(HenUtils.can_hold_instance_of(&'Variant', &'CharacterBody2D')).is_true()


# --- naming -----------------------------------------------------------------


# pool names must be human: the macro's own, else the file name capitalized
func test_native_actions_load_with_human_names() -> void:
	HenScriptMacroLoader.load_native_actions()

	var names: Array[String] = []
	for macro: HenSaveMacro in (Engine.get_singleton(&'Global') as HenGlobal).action_macros:
		names.append(macro.name)

	assert_array(names).contains(['Print Value', 'Set Value', 'Lerp Toward', 'Array Pop', 'Dictionary Get'])


# asserts the wiring, not the palette: the exact hexes are a taste call that
# should be retunable without breaking the suite
func test_native_actions_carry_icon_and_color() -> void:
	HenScriptMacroLoader.load_native_actions()

	var by_id: Dictionary = {}
	for macro: HenSaveMacro in (Engine.get_singleton(&'Global') as HenGlobal).action_macros:
		by_id[str(macro.id)] = macro

	for macro: HenSaveMacro in by_id.values():
		assert_bool(macro.icon.is_empty()).override_failure_message(macro.name + ' has no icon').is_false()
		assert_bool(macro.color.begins_with('#')).override_failure_message(macro.name + ' has no color').is_true()
		assert_object(HenActionVisuals.icon_texture(macro.icon)).is_not_null()

	# the var-writing family reads as a group, whatever the color ends up being
	assert_str(by_id['toggle_value'].color).is_equal(by_id['set_value'].color)

	# an unknown or missing name must fall back, never crash the row
	assert_object(HenActionVisuals.icon_texture('does-not-exist')).is_not_null()
	assert_object(HenActionVisuals.icon_texture('')).is_not_null()


# --- list preview -----------------------------------------------------------


# single input -> bare value, no label
func test_preview_shows_literal_without_name() -> void:
	var action: HenSaveAction = _add_action(_register(FIX_PHASES), &'update')
	action.inputs[0].default_value = 'custom'

	assert_str(HenActionsPanel.value_preview(action)).is_equal("'custom'")


# a binding reads as the bare identifier, so it never looks like a string literal
func test_preview_shows_binding_and_expression() -> void:
	var action: HenSaveAction = _add_action(_register(FIX_PHASES), &'update')
	action.input_bindings['value'] = 'my_speed'

	assert_str(HenActionsPanel.value_preview(action)).is_equal('my_speed')

	# expression wins over the binding, same precedence codegen uses
	action.input_expressions['value'] = _expression('a + b', ['a'], {}, {})

	assert_str(HenActionsPanel.value_preview(action)).is_equal('(a + b)')


# multiple inputs get labels, and an unset value must be visibly missing
func test_preview_labels_multiple_inputs() -> void:
	var action: HenSaveAction = _add_action(_register(FIX_TYPED), &'update')
	action.inputs[1].default_value = 45.0

	# a whole number drops its decimals: a chip is a few characters wide
	assert_str(HenActionsPanel.value_preview(action)).is_equal('Target: — · Value: 45')


# the chip kind is what carries icon+color, so it must tell the sources apart
func test_preview_parts_classify_each_source() -> void:
	var my_var: HenSaveVar = save_data.add_var(false)
	my_var.name = 'my_speed'
	my_var.type = 'float'

	var action: HenSaveAction = _add_action(_register(FIX_PHASES), &'update')

	assert_str(str(HenActionsPanel.value_parts(action)[0].kind)).is_equal('literal')

	action.input_bindings['value'] = 'my_speed'
	assert_str(str(HenActionsPanel.value_parts(action)[0].kind)).is_equal('variable')

	# not a declared variable -> a native property of the identity type
	action.input_bindings['value'] = 'rotation'
	assert_str(str(HenActionsPanel.value_parts(action)[0].kind)).is_equal('property')

	action.input_expressions['value'] = _expression('a + b', ['a'], {}, {})
	assert_str(str(HenActionsPanel.value_parts(action)[0].kind)).is_equal('expression')

	action.input_actions['value'] = {action = _math_child(1.0, '+', 2.0), output = &'result'}
	var inline_part: Dictionary = HenActionsPanel.value_parts(action)[0]
	assert_str(str(inline_part.kind)).is_equal('action')
	assert_bool(str(inline_part.value).is_empty()).is_false()


# the row renders a capsule instead of a flat label, so the data has to carry the
# nested action's own parts, at any depth
func test_capsule_data_carries_every_level() -> void:
	var outer: HenSaveAction = HenSaveAction.create(_register(FIX_MATH))
	outer.input_actions['a'] = {action = _math_child(2.0, '*', 3.0), output = &'result'}

	var capsule: Dictionary = HenActionsPanel.capsule_data({action = outer, output = &'result'})
	var parts: Array = capsule.parts

	assert_int(parts.size()).is_equal(3)
	assert_bool((parts[0].capsule as Dictionary).is_empty()).is_false()
	assert_int(((parts[0].capsule as Dictionary).parts as Array).size()).is_equal(3)


# a chip only takes typed text on a plain literal of a one-line type
func test_parts_flag_which_values_a_chip_can_type() -> void:
	var action: HenSaveAction = _add_action(_register(FIX_MATH), &'update')
	var parts: Array = HenActionsPanel.value_parts(action)

	assert_bool(parts[0].editable).is_true()
	# the operator comes from a fixed option set, so it gets its picker instead
	assert_bool(parts[1].editable).is_false()

	action.input_bindings['b'] = 'rotation'

	assert_bool(HenActionsPanel.value_parts(action)[2].editable).is_false()


# the chip writes through the slot, so its type has to follow type_from the same
# way codegen does
func test_slot_type_follows_the_bound_target() -> void:
	var my_var: HenSaveVar = save_data.add_var(false)
	my_var.name = 'my_speed'
	my_var.type = 'float'

	var action: HenSaveAction = _add_action(_register(FIX_TYPED), &'update')
	action.input_bindings['target'] = 'my_speed'

	assert_str(str(HenActionsPanel.value_parts(action)[1].slot.type)).is_equal('float')


func test_parse_literal_follows_the_slot_type() -> void:
	var as_float: Variant = HenActionsPanel.parse_literal('45', 'float')
	var as_int: Variant = HenActionsPanel.parse_literal('7', 'int')

	assert_bool(as_float is float).is_true()
	assert_float(as_float).is_equal(45.0)
	assert_int(as_int).is_equal(7)
	# an untyped slot keeps the text, mirroring the inspector's Variant editor
	assert_str(str(HenActionsPanel.parse_literal('45', 'Variant'))).is_equal('45')


func test_inline_label_counts_nested_actions() -> void:
	var outer: HenSaveAction = HenSaveAction.create(_register(FIX_MATH))
	for param: HenSaveParam in outer.inputs:
		match str(param.id):
			'op': param.default_value = '+'
			'b': param.default_value = 5.0
	outer.input_actions['a'] = {action = _math_child(2.0, '*', 3.0), output = &'result'}

	var label: String = HenActionsPanel.inline_label({action = outer, output = &'result'})

	assert_str(label).contains('+1 action')
	# the nested action's own operator/args are not expanded into the chip
	assert_str(label).not_contains('*')


# a null value falls back to the macro default, mirroring what the inspector seeds
func test_preview_falls_back_to_macro_default() -> void:
	var action: HenSaveAction = _add_action(_register(FIX_PHASES), &'update')
	action.inputs[0].default_value = null

	assert_str(HenActionsPanel.value_preview(action)).is_equal("'hi'")


func test_supported_and_default_phases() -> void:
	var phases_macro: HenSaveMacro = _register(FIX_PHASES)
	var process_macro: HenSaveMacro = _register(FIX_PROCESS)

	assert_bool(HenSaveAction.supported_phases(phases_macro).has(&'enter')).is_true()
	assert_bool(HenSaveAction.supported_phases(phases_macro).has(&'exit')).is_true()

	# no flow inputs -> only update (its body comes from the _process override)
	assert_bool(HenSaveAction.supported_phases(process_macro).has(&'enter')).is_false()
	assert_str(str(HenSaveAction.default_phase(process_macro))).is_equal('update')

	# an enter-only macro must not be born on a phase it has no body for
	var enter_only: HenSaveMacro = HenSaveMacro.new()
	enter_only.flow_inputs = [HenSaveFlowParam.create({name = 'Enter', id = &'enter'})]
	assert_str(str(HenSaveAction.default_phase(enter_only))).is_equal('enter')


# --- target classes ---------------------------------------------------------


const FIX_COLOR: String = 'res://addons/hengo/actions/render/change_color.gd'


# the same action emits the 2d path when the script extends a Node2D
func test_target_class_dispatches_to_node_2d() -> void:
	_add_action(_register(FIX_COLOR), &'update')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref.modulate = Color(')
	assert_str(code).not_contains('albedo_color')


# and the 3d path when it extends a Node3D, from the very same macro file
func test_target_class_dispatches_to_node_3d() -> void:
	save_data.identity.type = 'MeshInstance3D'
	_add_action(_register(FIX_COLOR), &'update')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('albedo_color = Color(')
	assert_str(code).not_contains('_ref.modulate')


# both branches must be valid gdscript under their own base class
func test_target_class_bodies_compile() -> void:
	save_data.identity.type = 'MeshInstance3D'
	_add_action(_register(FIX_COLOR), &'update')

	var script := GDScript.new()
	script.source_code = HenTest.get_all_code()

	assert_int(script.reload()).is_equal(OK)


# emits the body for the owner and asserts the generated script compiles
func _color_code_for(_owner: String) -> String:
	save_data.identity.type = _owner
	_add_action(_register(FIX_COLOR), &'update')

	var code: String = HenTest.get_all_code()
	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).override_failure_message('change_color does not compile for ' + _owner + ':\n' + code).is_equal(OK)
	return code


# a 2d light owns its color, so it writes .color instead of tinting via modulate
func test_target_class_dispatches_to_light_2d() -> void:
	var code: String = _color_code_for('PointLight2D')

	assert_str(code).contains('(_ref as Light2D).color = Color(')
	assert_str(code).not_contains('_ref.modulate')


# a 3d light writes light_color, never touching a material override
func test_target_class_dispatches_to_light_3d() -> void:
	var code: String = _color_code_for('OmniLight3D')

	assert_str(code).contains('(_ref as Light3D).light_color = Color(')
	assert_str(code).not_contains('albedo_color')


# a 3d sprite tints via modulate, not the albedo path meshes take
func test_target_class_dispatches_to_sprite_3d() -> void:
	var code: String = _color_code_for('Sprite3D')

	assert_str(code).contains('(_ref as SpriteBase3D).modulate = Color(')
	assert_str(code).not_contains('albedo_color')


# a polygon writes its fill color prop directly
func test_target_class_dispatches_to_polygon_2d() -> void:
	assert_str(_color_code_for('Polygon2D')).contains('(_ref as Polygon2D).color = Color(')


# a canvas modulate tints the whole canvas through its color prop
func test_target_class_dispatches_to_canvas_modulate() -> void:
	assert_str(_color_code_for('CanvasModulate')).contains('(_ref as CanvasModulate).color = Color(')


# a line writes default_color, the prop that drives its stroke
func test_target_class_dispatches_to_line_2d() -> void:
	assert_str(_color_code_for('Line2D')).contains('(_ref as Line2D).default_color = Color(')


# a macro is offered to whoever inherits from its targets, and to no one else
func test_macro_is_offered_only_to_declared_classes() -> void:
	var color: HenSaveMacro = _register(FIX_COLOR)

	assert_bool(color.serves_class(&'Sprite2D')).is_true()
	assert_bool(color.serves_class(&'MeshInstance3D')).is_true()
	# change_color absorbed set_modulate, so it targets CanvasItem too (Control included)
	assert_bool(color.serves_class(&'Button')).is_true()
	assert_bool(color.serves_class(&'Timer')).is_false()

	var only_control: HenSaveMacro = HenSaveMacro.new()
	only_control.target_classes = [&'Control']

	assert_bool(only_control.serves_class(&'Button')).is_true()
	assert_bool(only_control.serves_class(&'Sprite2D')).is_false()

	# no targets declared -> every class, and an unknown base never hides the pool
	var universal: HenSaveMacro = HenSaveMacro.new()

	assert_bool(universal.serves_class(&'Sprite2D')).is_true()
	assert_bool(only_control.serves_class(&'MyCustomBase')).is_true()


# the recipe is mtime-cached, so the targets must survive the real loader path
func test_native_loader_carries_target_classes() -> void:
	HenScriptMacroLoader.load_native_actions()

	var color: HenSaveMacro = null
	for macro: HenSaveMacro in (Engine.get_singleton(&'Global') as HenGlobal).action_macros:
		if macro.id == &'change_color':
			color = macro

	assert_object(color).is_not_null()
	assert_array(color.target_classes).contains([&'CanvasItem', &'Node3D'])


# --- categories -------------------------------------------------------------


# the category is the folder, so it survives the mtime-cached recipe
func test_native_loader_assigns_category_from_folder() -> void:
	HenScriptMacroLoader.load_native_actions()

	var by_id: Dictionary = {}
	for macro: HenSaveMacro in (Engine.get_singleton(&'Global') as HenGlobal).action_macros:
		by_id[str(macro.id)] = macro

	assert_str(by_id['if_condition'].category).is_equal('flow')
	assert_str(by_id['set_value'].category).is_equal('variable')
	assert_str(by_id['math_operator'].category).is_equal('math')
	assert_str(by_id['array_add'].category).is_equal('array')


# a macro that declares no color takes the one of its folder
func test_category_supplies_presentation_defaults() -> void:
	HenScriptMacroLoader.load_native_actions()

	var variable_color: String = str(HenActionCategories.get_data('variable').color)

	for macro: HenSaveMacro in (Engine.get_singleton(&'Global') as HenGlobal).action_macros:
		if macro.category == 'variable':
			assert_str(macro.color).is_equal(variable_color)


# unknown folders must render, not crash; order drives the grouped search list
func test_category_registry_sorts_and_falls_back() -> void:
	var unknown: Dictionary = HenActionCategories.get_data('my_macros')

	assert_str(str(unknown.name)).is_equal('My Macros')
	assert_bool(str(unknown.icon).is_empty()).is_false()

	# known folders first in table order, unknown ones last
	assert_array(HenActionCategories.sorted(['math', 'my_macros', 'flow'])).is_equal(['flow', 'math', 'my_macros'])


# a nested file is found and a deleted one leaves the cache
func test_loader_recurses_and_evicts_nested_files() -> void:
	var dir_path: String = HenScriptMacroLoader.MACRO_PATH + '/testcat'
	var file_path: String = dir_path + '/tmp_macro.gd'

	DirAccess.make_dir_recursive_absolute(dir_path)
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string("extends HenScriptMacroBase\n\n\nfunc get_id() -> StringName:\n\treturn &'tmp_macro'\n")
	file.close()

	HenScriptMacroLoader.load_script_macros()

	var global: HenGlobal = Engine.get_singleton(&'Global')
	var found: HenSaveMacro = null
	for macro: HenSaveMacro in global.script_macros:
		if macro.id == &'tmp_macro':
			found = macro

	assert_object(found).is_not_null()
	assert_str(found.category).is_equal('testcat')

	DirAccess.remove_absolute(file_path)
	DirAccess.remove_absolute(dir_path)
	HenScriptMacroLoader.load_script_macros()

	for macro: HenSaveMacro in global.script_macros:
		assert_str(str(macro.id)).is_not_equal('tmp_macro')


# --- lvalue inputs ----------------------------------------------------------


# an assignment target left as a literal would emit `0 = 5`, which never compiles
func test_lvalue_input_must_be_bound() -> void:
	HenScriptMacroLoader.load_native_actions()

	var set_value: HenSaveMacro = HenActionsPanel.find_macro(&'set_value')
	var action: HenSaveAction = _add_action(set_value, &'update')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('must be bound to a variable or property')
	assert_str(code).not_contains(' = 0')

	var my_var: HenSaveVar = save_data.add_var(false)
	my_var.name = 'score'
	my_var.type = 'float'
	action.input_bindings['target'] = HenUtils.bind_code_for_var(my_var)

	assert_str(HenTest.get_all_code()).contains('_ref.score = ')


# --- option inputs ----------------------------------------------------------


# an option is a code fragment: it must land in the script unquoted
func test_option_input_emits_verbatim() -> void:
	HenScriptMacroLoader.load_native_actions()

	var my_var: HenSaveVar = save_data.add_var(false)
	my_var.name = 'score'
	my_var.type = 'float'

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'math_operator'), &'update')
	action.output_bindings['result'] = HenUtils.bind_code_for_var(my_var)

	for param: HenSaveParam in action.inputs:
		match str(param.id):
			'a': param.default_value = 3.0
			'b': param.default_value = 2.0
			'op': param.default_value = '*'

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref.score = 3.0 * 2.0')
	assert_str(code).not_contains("'*'")

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# the loader must carry the options onto the pool param, or the inspector shows
# a plain text field instead of the picker
func test_native_loader_carries_options_and_raw() -> void:
	HenScriptMacroLoader.load_native_actions()

	var math: HenSaveMacro = HenActionsPanel.find_macro(&'math_operator')
	var op: HenSaveParam = null

	for param: HenSaveParam in math.inputs:
		if str(param.id) == 'op':
			op = param

	assert_object(op).is_not_null()
	assert_array(op.options).contains(['+', '-', '*', '/'])
	assert_bool(op.raw).is_true()


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

	# a declared signal, so emit_signal has a real name to fire instead of ''
	var sig: HenSaveSignal = save_data.add_signal(false)
	sig.name = 'swept_signal'

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
					signal_param.default_value = sig.name

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


# --- native value sources ---------------------------------------------------


# a native source rides the plain bind path: the code goes out after `_ref.`,
# while the ui shows its human name
func test_native_source_binds_like_a_property() -> void:
	HenScriptMacroLoader.load_native_actions()

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'look_at_2d'), &'update')
	action.input_bindings['target'] = 'get_global_mouse_position()'

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref.look_at(_ref.get_global_mouse_position())')

	assert_str(HenUtils.get_bind_label(save_data, 'get_global_mouse_position()')).is_equal('Mouse Position')
	assert_str(HenUtils.get_bound_source_type(save_data, 'get_global_mouse_position()')).is_equal('Vector2')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# the mouse only exists for canvas owners, so a 3d script must not be offered it
func test_native_source_declares_the_class_it_needs() -> void:
	for source: Dictionary in HenUtils.NATIVE_SOURCES:
		var needs: String = str(source.needs_class)

		# empty means every owner; anything else has to be a real class or the
		# filter silently hides the source
		assert_bool(needs.is_empty() or ClassDB.class_exists(needs)).is_true()

	assert_bool(ClassDB.is_parent_class(&'Sprite2D', &'CanvasItem')).is_true()
	assert_bool(ClassDB.is_parent_class(&'Node3D', &'CanvasItem')).is_false()


# an engine-global source stands alone: prefixing `_ref.` would call a method the
# owner does not have
func test_global_native_source_emits_without_the_ref_prefix() -> void:
	HenScriptMacroLoader.load_native_actions()

	var my_var: HenSaveVar = save_data.add_var(false)
	my_var.name = 'score'
	my_var.type = 'float'

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'set_value'), &'update')
	action.input_bindings['target'] = HenUtils.bind_code_for_var(my_var)
	action.input_bindings['value'] = 'randf()'

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref.score = randf()')
	assert_str(code).not_contains('_ref.randf()')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# a source substitutes mid-expression, so anything that is not a single call has
# to carry its own parentheses
func test_native_sources_are_atomic_expressions() -> void:
	for source: Dictionary in HenUtils.NATIVE_SOURCES:
		# a parameterized source is only atomic once the argument is in place
		var code: String = HenUtils.native_source_code(source, 'sample')
		var depth: int = 0
		var loose_operator: bool = false

		for i: int in code.length():
			var c: String = code[i]

			if c == '(':
				depth += 1
			elif c == ')':
				depth -= 1
			elif depth == 0 and '+-*/%<>=!&|'.contains(c):
				loose_operator = true

		assert_bool(loose_operator).override_failure_message(code + ' is not atomic').is_false()


# every source must compile in the state class scope
func test_native_sources_compile() -> void:
	# _ref stands for the owner inside a state class, so the harness declares one
	var lines: PackedStringArray = ['extends Node2D', '', 'var _ref = self', '', 'func _test() -> void:']

	for i: int in HenUtils.NATIVE_SOURCES.size():
		var source: Dictionary = HenUtils.NATIVE_SOURCES[i]
		var expression: String = HenUtils.native_source_code(source, 'ui_accept')

		if not bool(source.global):
			# a source needing a class Node2D lacks is read off the untyped _ref, so its
			# property access still parses without that exact base type on self
			var needs: StringName = source.needs_class
			if needs == &'' or ClassDB.is_parent_class(&'Node2D', needs):
				expression = 'self.' + expression
			else:
				expression = '_ref.' + expression

		lines.append('\tvar _v' + str(i) + ' = ' + expression)

	var script := GDScript.new()
	script.source_code = '\n'.join(lines) + '\n'

	assert_int(script.reload()).is_equal(OK)


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


# --- physics phase ----------------------------------------------------------


# the fixed tick is where a body must be moved; super(delta) propagates to the sub-state
func test_action_runs_in_physics_with_super() -> void:
	HenScriptMacroLoader.load_native_actions()
	save_data.identity.type = 'CharacterBody2D'

	_add_action(HenActionsPanel.find_macro(&'move_and_slide'), &'physics')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('func physics(delta) -> void:\n\t\tsuper(delta)\n\t\t_ref.move_and_slide()')


# the macro names the phase a new action lands on, and it still has to declare a body
func test_default_phase_follows_the_macro_hint() -> void:
	HenScriptMacroLoader.load_native_actions()

	assert_str(str(HenSaveAction.default_phase(HenActionsPanel.find_macro(&'move_and_slide')))).is_equal('physics')
	assert_str(str(HenSaveAction.default_phase(HenActionsPanel.find_macro(&'wait')))).is_equal('update')
	assert_str(str(HenSaveAction.default_phase(HenActionsPanel.find_macro(&'print_value')))).is_equal('update')

	var phases: Array = HenSaveAction.supported_phases(HenActionsPanel.find_macro(&'move_and_slide'))

	assert_array(phases).contains([&'physics', &'update'])


# an action saved before the physics phase existed must keep compiling
func test_physics_macro_still_runs_on_update() -> void:
	HenScriptMacroLoader.load_native_actions()
	save_data.identity.type = 'CharacterBody2D'

	_add_action(HenActionsPanel.find_macro(&'move_and_slide'), &'update')

	assert_str(HenTest.get_all_code()).contains('func update(delta) -> void:\n\t\tsuper(delta)\n\t\t_ref.move_and_slide()')


# --- action state -----------------------------------------------------------


# the counter lives in the state class and is zeroed on entry, so re-entering the
# state restarts the wait
func test_wait_declares_its_counter_and_resets_on_enter() -> void:
	HenScriptMacroLoader.load_native_actions()

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'done state'

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'wait'), &'update')
	action.branches['finished'] = {state_id = target.id, label = ''}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('\tvar wait_' + str(action.id) + ': float = 0.0')
	assert_str(code).contains('func enter() -> void:\n\t\twait_' + str(action.id) + ' = 0.0')
	assert_str(code).contains('wait_' + str(action.id) + ' += delta')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# two waits in the same state get their own counter, or one would eat the other
func test_two_waits_do_not_share_a_counter() -> void:
	HenScriptMacroLoader.load_native_actions()

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'done state'

	var macro: HenSaveMacro = HenActionsPanel.find_macro(&'wait')
	var first: HenSaveAction = _add_action(macro, &'update')
	var second: HenSaveAction = _add_action(macro, &'update')

	first.branches['finished'] = {state_id = target.id, label = ''}
	second.branches['finished'] = {state_id = target.id, label = ''}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('var wait_' + str(first.id))
	assert_str(code).contains('var wait_' + str(second.id))

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# a sub-state class is nested one level deeper, so every declaration line has to
# carry the extra indent — not just the first
func test_action_state_indents_inside_a_sub_state() -> void:
	HenScriptMacroLoader.load_native_actions()

	state.add_sub_state(save_data)
	var sub: HenSaveState = state.get_sub_states(save_data).get(0)
	sub.name = 'sub wait'

	var action: HenSaveAction = HenSaveAction.create(HenActionsPanel.find_macro(&'wait'))
	action.phase = &'update'
	action.branches['finished'] = {state_id = state.id, label = ''}
	save_data.add_state_action(sub.id, action)

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('\t\tvar wait_' + str(action.id) + ': float = 0.0')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# --- node path binding ------------------------------------------------------


# a sibling node reaches the slot without declaring a variable for it
func test_bind_to_a_node_path() -> void:
	HenScriptMacroLoader.load_native_actions()

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'play_sound'), &'enter')
	action.input_bindings['player'] = HenUtils.BIND_PATH_PREFIX + 'Audio/Hit'

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref.get_node("Audio/Hit").play()')

	# the raw prefix must never reach the screen, and the row reads it as a node
	assert_str(HenUtils.get_bind_label(save_data, 'path:Audio/Hit')).is_equal('Audio/Hit')
	assert_str(HenActionsPanel.value_preview(action)).contains('Audio/Hit')

	# a node path IS a node, so type_from can follow it
	assert_str(HenUtils.get_bound_source_type(save_data, 'path:Audio/Hit')).is_equal('Node')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# an empty path is not a binding, it would emit `_ref.` and break the line
func test_empty_node_path_is_treated_as_missing() -> void:
	HenScriptMacroLoader.load_native_actions()

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'play_sound'), &'enter')
	action.input_bindings['player'] = HenUtils.BIND_PATH_PREFIX

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('must be bound to a variable or property')
	assert_str(code).not_contains('_ref..play()')


# --- write targets vs must-bind reads ---------------------------------------


# a write target only accepts a variable or a property: `randf() = 5` and
# `get_node("x") = 5` are hard compile errors
func test_write_target_refuses_call_shaped_bindings() -> void:
	HenScriptMacroLoader.load_native_actions()

	# an in-place target (set_value) still rejects a call binding through the input gate
	var set_action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'set_value'), &'update')
	set_action.input_bindings['target'] = 'randf()'

	var set_code: String = HenTest.get_all_code()

	assert_str(set_code).contains('must be bound to a variable or property')
	assert_str(set_code).not_contains('randf() = ')

	# an output's store is assignable too: a call there drops the line, never `randf() = ...`
	var rng: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'random_int'), &'update')
	rng.output_bindings['result'] = 'randf()'

	assert_str(HenTest.get_all_code()).not_contains('randf() = randi_range')


# the picker must not offer what codegen refuses: a Store slot gets variables and
# properties only, while a node slot gets the paths and the engine values too
func test_bind_picker_narrows_a_write_target() -> void:
	HenScriptMacroLoader.load_native_actions()

	var inspector := HenInspector.new()
	var write: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'set_value'), &'update')
	var read: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'play_sound'), &'enter')

	var write_names: Array = _option_names(inspector, write, 'target')
	var read_names: Array = _option_names(inspector, read, 'player')

	assert_array(write_names).not_contains(['Node path...', 'Mouse Position', 'Random Float (0-1)'])
	assert_array(read_names).contains(['Node path...'])

	inspector.free()


func _option_names(_inspector: HenInspector, _action: HenSaveAction, _key: String) -> Array:
	var macro_params: Dictionary = {}

	for p: HenSaveParam in HenActionsPanel.find_macro(_action.macro_id).inputs:
		macro_params[str(p.id)] = p

	var param: HenSaveParam = null

	for p: HenSaveParam in _action.inputs:
		if str(p.id) == _key:
			param = p

	var options: Array = _inspector._build_bind_options({
		param = param,
		bind_store = _action.input_bindings,
		bind_key = _key,
		macro_params = macro_params,
		indent = 0
	})

	return options.map(func(o: Dictionary) -> String: return str(o.name))


# --- signal actions ---------------------------------------------------------


func _signal_action(_id: StringName, _target: HenSaveState, _emitter: String) -> HenSaveAction:
	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(_id), &'update')
	action.input_bindings['emitter'] = HenUtils.BIND_PATH_PREFIX + _emitter
	action.branches['received'] = {state_id = _target.id, label = ''}
	return action


# the connection is armed in enter and dropped in exit, both guarded: reconnecting
# on re-entry is an engine error, and the emitter may be gone by exit time
func test_signal_action_connects_on_enter_and_disconnects_on_exit() -> void:
	HenScriptMacroLoader.load_native_actions()

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'hit state'

	var action: HenSaveAction = _signal_action(&'on_body_entered', target, 'Area2D')
	var code: String = HenTest.get_all_code()
	var id: String = str(action.id)

	assert_str(code).contains('emitter_' + id + ' = _ref.get_node("Area2D")')
	assert_str(code).contains("not emitter_" + id + ".is_connected('body_entered', _on_signal_" + id + ")")
	assert_str(code).contains("emitter_" + id + ".connect('body_entered', _on_signal_" + id + ")")

	# teardown lands in exit, right after the super() the base needs
	assert_str(code).contains('func exit() -> void:\n\t\tsuper()\n\t\tif is_instance_valid(emitter_' + id + ')')
	assert_str(code).contains(".disconnect('body_entered', _on_signal_" + id + ")")

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# the store line lives in the phase body, the only path that substitutes inputs.
# the sweep never reaches it because it leaves optional slots empty
func test_signal_action_stores_the_argument_when_bound() -> void:
	HenScriptMacroLoader.load_native_actions()

	var body_var: HenSaveVar = save_data.add_var(false)
	body_var.name = 'ultimo corpo'
	body_var.type = 'Node2D'

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'hit state'

	var action: HenSaveAction = _signal_action(&'on_body_entered', target, 'Area2D')
	action.input_bindings['store_arg'] = HenUtils.bind_code_for_var(body_var)

	var code: String = HenTest.get_all_code()
	var id: String = str(action.id)

	# no placeholder may survive into the script base
	assert_str(code).not_contains('{{')
	assert_str(code).contains('_ref.ultimo_corpo = value_' + id)
	assert_str(code).contains('_ref._STATE_CONTROLLER.change_state("hit_state")')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# leaving the optional slot empty drops the value instead of skipping the action
func test_signal_action_without_store_still_compiles() -> void:
	HenScriptMacroLoader.load_native_actions()

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'hit state'

	var action: HenSaveAction = _signal_action(&'on_body_entered', target, 'Area2D')
	var code: String = HenTest.get_all_code()

	assert_str(code).not_contains('# hengo:')
	assert_str(code).not_contains(' = value_' + str(action.id))
	assert_str(code).contains('var value_' + str(action.id))


# two listeners in the same state need their own flag, emitter and value
func test_two_signal_actions_do_not_share_state() -> void:
	HenScriptMacroLoader.load_native_actions()

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'hit state'

	var first: HenSaveAction = _signal_action(&'on_body_entered', target, 'Area2D')
	var second: HenSaveAction = _signal_action(&'on_body_exited', target, 'Area2D')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('var fired_' + str(first.id))
	assert_str(code).contains('var fired_' + str(second.id))
	assert_str(code).contains('_on_signal_' + str(first.id))
	assert_str(code).contains('_on_signal_' + str(second.id))

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# the generic action takes any signal, and refuses an empty name instead of
# emitting connect("", cb), which compiles and silently never fires
func test_generic_on_signal_takes_a_name_and_refuses_a_blank_one() -> void:
	HenScriptMacroLoader.load_native_actions()

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'hit state'

	var action: HenSaveAction = _signal_action(&'on_signal', target, 'Timer')

	for param: HenSaveParam in action.inputs:
		if str(param.id) == 'signal_name':
			param.default_value = 'timeout'

	assert_str(HenTest.get_all_code()).contains(".connect('timeout', _on_signal_" + str(action.id) + ")")

	for param: HenSaveParam in action.inputs:
		if str(param.id) == 'signal_name':
			param.default_value = ''

	var blank: String = HenTest.get_all_code()

	assert_str(blank).contains('the signal name is empty')

	# a skipped action must leave NOTHING behind: the marker alone is a half-truth
	# while enter still runs connect('', cb) and exit the matching disconnect
	assert_str(blank).not_contains("connect('',")
	assert_str(blank).not_contains('_on_signal_' + str(action.id))
	assert_str(blank).not_contains('emitter_' + str(action.id))


# the `Sends` option drives the callback signature: godot refuses a callable that
# expects more arguments than the signal provides
func test_generic_on_signal_arity_follows_the_option() -> void:
	HenScriptMacroLoader.load_native_actions()

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'hit state'

	var action: HenSaveAction = _signal_action(&'on_signal', target, 'Timer')

	for param: HenSaveParam in action.inputs:
		if str(param.id) == 'signal_name':
			param.default_value = 'timeout'

	assert_str(HenTest.get_all_code()).contains('func _on_signal_' + str(action.id) + '() -> void:')

	for param: HenSaveParam in action.inputs:
		if str(param.id) == 'args':
			param.default_value = 'one value'

	assert_str(HenTest.get_all_code()).contains('func _on_signal_' + str(action.id) + '(arg_' + str(action.id) + ') -> void:')


# the only test that proves the callback signature matches the signal: godot does
# not document the arity rule and GDScript.reload() never checks it. it also
# exercises the connect/disconnect for real
func test_signal_action_fires_at_runtime() -> void:
	HenScriptMacroLoader.load_native_actions()
	save_data.identity.type = 'Node2D'
	state.start = true

	# Variant on purpose: a var typed Node2D makes gen_variable emit Node2D.new()
	# as its default, which leaks an orphan node and is a separate known debt
	var body_var: HenSaveVar = save_data.add_var(false)
	body_var.name = 'ultimo corpo'
	body_var.type = 'Variant'

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'hit state'

	var action: HenSaveAction = _signal_action(&'on_body_entered', target, 'Area2D')
	action.input_bindings['store_arg'] = HenUtils.bind_code_for_var(body_var)

	var script := GDScript.new()
	script.source_code = HenTest.get_all_code()

	assert_int(script.reload()).is_equal(OK)

	# freed by hand at the end: auto_free runs after the orphan check, and the
	# intruder never joins the tree
	var owner_node: Node2D = Node2D.new()
	var area: Area2D = Area2D.new()
	area.name = 'Area2D'
	owner_node.add_child(area)
	owner_node.set_script(script)
	add_child(owner_node)

	# _ready ran, so the start state is active and the signal is connected
	assert_bool(area.is_connected('body_entered', Callable(owner_node.get('_STATE_CONTROLLER').current_state, '_on_signal_' + str(action.id)))).is_true()

	var intruder: Node2D = Node2D.new()
	area.body_entered.emit(intruder)

	# the flag only becomes a transition on the next tick of the action's phase
	owner_node._process(0.016)

	assert_object(owner_node.get('ultimo_corpo')).is_same(intruder)
	assert_str(str(owner_node.get('_STATE_CONTROLLER')._last_debug_name)).is_equal('hit_state')

	owner_node.free()
	intruder.free()


# the owner itself is the emitter whenever the script sits on the node that has
# the signal — a Button script listening to its own `pressed`
func test_self_can_be_the_emitter() -> void:
	HenScriptMacroLoader.load_native_actions()
	save_data.identity.type = 'Button'

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'clicked state'

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'on_button_pressed'), &'update')
	action.input_bindings['emitter'] = '_ref'
	action.branches['received'] = {state_id = target.id, label = ''}

	var code: String = HenTest.get_all_code()
	var id: String = str(action.id)

	# _ref stands alone: prefixing it would emit _ref._ref
	assert_str(code).contains('emitter_' + id + ' = _ref\n')
	assert_str(code).not_contains('_ref._ref')
	assert_str(code).contains("emitter_" + id + ".connect('pressed', _on_signal_" + id + ")")

	assert_str(HenUtils.get_bind_label(save_data, '_ref')).is_equal('Self (this node)')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# Self must reach any node slot, and never a write target (`_ref = x`)
func test_self_is_offered_to_node_slots_only() -> void:
	HenScriptMacroLoader.load_native_actions()

	var inspector := HenInspector.new()
	var listener: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'on_button_pressed'), &'update')
	var write: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'set_value'), &'update')

	assert_array(_option_names(inspector, listener, 'emitter')).contains(['Self (this node)'])
	assert_array(_option_names(inspector, write, 'target')).not_contains(['Self (this node)'])

	inspector.free()


# --- script scope and virtual overrides -------------------------------------


func _look_action(_phase: StringName) -> HenSaveAction:
	save_data.identity.type = 'CharacterBody3D'
	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'mouse_look'), _phase)
	action.input_bindings['camera'] = HenUtils.BIND_PATH_PREFIX + 'Camera3D'
	return action


# _input runs on the node, so both the override and the variables it reads have to
# land at script scope — inside the state class they would be unreachable
func test_action_reaches_script_scope_and_virtuals() -> void:
	HenScriptMacroLoader.load_native_actions()

	var action: HenSaveAction = _look_action(&'physics')
	var code: String = HenTest.get_all_code()
	var id: String = str(action.id)

	var scope_at: int = code.find('var look_on_' + id)
	var class_at: int = code.find('class StateTest')

	assert_int(scope_at).is_greater(-1)
	assert_int(scope_at).is_less(class_at)

	# the override keeps its parameter, or the body would reference an unknown event
	assert_str(code).contains('func _input(event: InputEvent) -> void:\n\tif look_on_' + id)
	assert_int(code.find('func _input')).is_less(class_at)

	# the state class reaches script scope through _ref
	assert_str(code).contains('_ref.look_on_' + id + ' = true')
	assert_str(code).contains('_ref.look_on_' + id + ' = false')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# two actions overriding the same virtual share one func, they do not emit two
func test_two_actions_share_one_virtual_override() -> void:
	HenScriptMacroLoader.load_native_actions()

	var first: HenSaveAction = _look_action(&'physics')
	var second: HenSaveAction = _look_action(&'update')

	var code: String = HenTest.get_all_code()

	assert_int(code.count('func _input(')).is_equal(1)
	assert_str(code).contains('look_move_' + str(first.id) + ' += event.relative')
	assert_str(code).contains('look_move_' + str(second.id) + ' += event.relative')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# a skipped action must not leave an override or a declaration behind, the same
# rule the signal connect follows
func test_skipped_action_leaves_no_override() -> void:
	HenScriptMacroLoader.load_native_actions()

	var action: HenSaveAction = _look_action(&'physics')
	action.input_bindings.erase('camera')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('must be bound to a variable or property')
	assert_str(code).not_contains('func _input')
	assert_str(code).not_contains('look_on_' + str(action.id))


# headless has no input and reload() proves nothing about behaviour: this drives a
# real InputEventMouseMotion through the generated script and checks that the look
# both works AND stops once the state is left
func test_mouse_look_arms_and_disarms_at_runtime() -> void:
	HenScriptMacroLoader.load_native_actions()
	state.start = true

	var idle: HenSaveState = save_data.add_state(false)
	idle.name = 'parked'

	var action: HenSaveAction = _look_action(&'physics')

	# leaving the state is what must switch the listener off
	var leave: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'transition'), &'update')
	leave.branches['to'] = {state_id = idle.id, label = ''}

	var script := GDScript.new()
	script.source_code = HenTest.get_all_code()

	assert_int(script.reload()).is_equal(OK)

	var body: CharacterBody3D = CharacterBody3D.new()
	var cam: Camera3D = Camera3D.new()
	cam.name = 'Camera3D'
	body.add_child(cam)
	body.set_script(script)
	add_child(body)

	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(100, 40)

	body._input(motion)
	body._physics_process(0.016)

	var turned: float = body.rotation.y
	var pitched: float = cam.rotation.x

	assert_bool(is_zero_approx(turned)).override_failure_message('the body did not turn').is_false()
	assert_bool(is_zero_approx(pitched)).override_failure_message('the camera did not pitch').is_false()

	# now leave the state: update runs the transition, whose exit drops the listener
	body._process(0.016)

	body._input(motion)

	# checked on the accumulator, not on the rotation: the body stops running once
	# the state is left, so the rotation would freeze even with the listener still on
	assert_vector(body.get('look_move_' + str(action.id))) \
		.override_failure_message('_input kept accumulating after the state exited') \
		.is_equal(Vector2.ZERO)

	body._physics_process(0.016)

	assert_float(body.rotation.y).is_equal_approx(turned, 0.0001)
	assert_float(cam.rotation.x).is_equal_approx(pitched, 0.0001)

	body.free()


# --- sub-state transitions and go back ---------------------------------------


func _sub_state(_parent: HenSaveState, _name: String) -> HenSaveState:
	_parent.add_sub_state(save_data)
	var subs: Array = _parent.get_sub_states(save_data)
	var sub: HenSaveState = subs[subs.size() - 1]
	sub.name = _name
	return sub


# a sub-state changing to a SIBLING has to go through the parent: emitting
# change_state would look the name up in the top level dict and print "not found"
func test_sub_state_transitions_to_a_sibling() -> void:
	HenScriptMacroLoader.load_native_actions()

	var ready: HenSaveState = _sub_state(state, 'ready state')
	var busy: HenSaveState = _sub_state(state, 'busy state')

	var action: HenSaveAction = HenSaveAction.create(HenActionsPanel.find_macro(&'transition'))
	action.phase = &'update'
	action.branches['to'] = {state_id = ready.id, label = ''}
	save_data.add_state_action(busy.id, action)

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref._STATE_CONTROLLER.current_state.change_sub_state("ready_state")')
	assert_str(code).not_contains('_STATE_CONTROLLER.change_state("ready_state")')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# a sub-state of a state that is not running cannot be reached, and saying so is
# better than emitting a change_state that fails at runtime
func test_branch_to_an_unreachable_sub_state_is_refused() -> void:
	HenScriptMacroLoader.load_native_actions()

	var other: HenSaveState = save_data.add_state(false)
	other.name = 'other top'

	var stranger: HenSaveState = _sub_state(other, 'stranger')

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'transition'), &'update')
	action.branches['to'] = {state_id = stranger.id, label = ''}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('points at a sub-state of another state')
	assert_str(code).not_contains('change_sub_state("stranger")')


# Go Back needs no target: the state asks whoever handed control to it
func test_go_back_emits_a_targetless_return() -> void:
	HenScriptMacroLoader.load_native_actions()

	var sub: HenSaveState = _sub_state(state, 'quick state')

	var action: HenSaveAction = HenSaveAction.create(HenActionsPanel.find_macro(&'go_back'))
	action.phase = &'enter'
	save_data.add_state_action(sub.id, action)

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('go_back()')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# --- parameterized bind sources ----------------------------------------------


# a source that takes an argument is stored as "key:arg" and formats its own code
func test_parameterized_source_emits_its_argument() -> void:
	HenScriptMacroLoader.load_native_actions()

	var speed: HenSaveVar = save_data.add_var(false)
	speed.name = 'speed'
	speed.type = 'float'

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'set_value'), &'update')
	action.input_bindings['target'] = HenUtils.bind_code_for_var(speed)
	action.input_bindings['value'] = 'action_strength:ui_right'

	var code: String = HenTest.get_all_code()

	# Input.* stands alone: prefixing it with _ref. would call a method the node lacks
	assert_str(code).contains('_ref.speed = Input.get_action_strength("ui_right")')
	assert_str(code).not_contains('_ref.Input')

	assert_str(HenUtils.get_bind_label(save_data, 'action_strength:ui_right')).is_equal('Action strength (ui_right)')
	assert_str(HenUtils.get_bound_source_type(save_data, 'action_strength:ui_right')).is_equal('float')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# path: became a row of the same table, so saved data has to keep emitting the
# exact same call
func test_node_path_still_emits_get_node() -> void:
	HenScriptMacroLoader.load_native_actions()

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'play_sound'), &'enter')
	action.input_bindings['player'] = 'path:Audio/Hit'

	assert_str(HenTest.get_all_code()).contains('_ref.get_node("Audio/Hit").play()')
	assert_str(HenUtils.get_bind_label(save_data, 'path:Audio/Hit')).is_equal('Audio/Hit')


# an unknown key is not a property name: `foo:bar` is not valid gdscript, so it
# has to degrade to unbound. this is what proves the classification sits in one place
func test_unknown_bind_key_degrades_to_unbound() -> void:
	HenScriptMacroLoader.load_native_actions()

	assert_str(HenUtils.resolve_bind_code(save_data, 'foo:bar')).is_empty()
	assert_str(HenUtils.bind_expression(save_data, 'foo:bar')).is_empty()

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'print_value'), &'update')
	action.input_bindings['value'] = 'foo:bar'

	assert_str(HenTest.get_all_code()).not_contains('foo:bar')


# an empty argument would emit ("") and still read as bound while doing nothing
func test_empty_source_argument_is_not_a_binding() -> void:
	HenScriptMacroLoader.load_native_actions()

	assert_str(HenUtils.resolve_bind_code(save_data, 'action_strength:')).is_empty()

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'print_value'), &'update')
	action.input_bindings['value'] = 'action_strength:'

	var code: String = HenTest.get_all_code()

	assert_str(code).not_contains('get_action_strength("")')
	assert_str(HenActionsPanel.value_preview(action)).not_contains('Action strength')


# --- check mouse button ------------------------------------------------------


func _mouse_action(_when: String, _target: HenSaveState) -> HenSaveAction:
	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'mouse_button'), &'update')
	action.branches['true'] = {state_id = _target.id, label = ''}

	for param: HenSaveParam in action.inputs:
		if str(param.id) == 'when':
			param.default_value = _when

	return action


# Held is a plain per-frame check: it must not drag an _input override along
func test_mouse_button_held_declares_nothing() -> void:
	HenScriptMacroLoader.load_native_actions()

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'firing'

	_mouse_action('Held', target)

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):')
	assert_str(code).not_contains('func _input')
	assert_str(code).not_contains('click_on_')


# a moment needs the event, and a double click has to rule out the plain click
func test_mouse_button_double_click_uses_the_event() -> void:
	HenScriptMacroLoader.load_native_actions()

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'firing'

	var action: HenSaveAction = _mouse_action('Double Click', target)
	var code: String = HenTest.get_all_code()
	var id: String = str(action.id)

	assert_str(code).contains('func _input(event: InputEvent) -> void:')
	assert_str(code).contains('event.pressed and event.double_click')
	assert_str(code).contains('_ref.click_on_' + id + ' = true')
	assert_str(code).contains('_ref.click_on_' + id + ' = false')
	assert_str(code).not_contains('Input.is_mouse_button_pressed')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# renaming the display name must reach an action saved under the old one
func test_renamed_macro_shows_the_new_name() -> void:
	HenScriptMacroLoader.load_native_actions()

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'mouse_button'), &'update')
	action.name = 'Mouse Button'

	assert_str(HenActionsPanel.display_name(action)).is_equal('Check Mouse Button')


# nothing else can reach this: headless has no input and reload() only proves the
# code parses. drives real mouse events through the generated script
func test_double_click_fires_only_on_a_double_click() -> void:
	HenScriptMacroLoader.load_native_actions()
	save_data.identity.type = 'Node2D'
	state.start = true

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'firing'

	var action: HenSaveAction = _mouse_action('Double Click', target)

	var script := GDScript.new()
	script.source_code = HenTest.get_all_code()

	assert_int(script.reload()).is_equal(OK)

	var node: Node2D = Node2D.new()
	node.set_script(script)
	add_child(node)

	var single := InputEventMouseButton.new()
	single.button_index = MOUSE_BUTTON_LEFT
	single.pressed = true

	node._input(single)
	node._process(0.016)

	assert_str(str(node.get('_STATE_CONTROLLER')._last_debug_name)) \
		.override_failure_message('a single click fired the double click branch') \
		.is_equal('state_test')

	var double := InputEventMouseButton.new()
	double.button_index = MOUSE_BUTTON_LEFT
	double.pressed = true
	double.double_click = true

	node._input(double)
	node._process(0.016)

	assert_str(str(node.get('_STATE_CONTROLLER')._last_debug_name)).is_equal('firing')

	# the state changed, so the listener was disarmed on the way out
	node._input(double)

	assert_bool(bool(node.get('click_on_' + str(action.id)))) \
		.override_failure_message('_input kept listening after the state exited') \
		.is_false()

	node.free()


# --- data outputs ------------------------------------------------------------


# a producer with no output stored contributes nothing, so it is skipped loud
# instead of leaving the phase method empty
func test_producer_without_a_stored_output_is_skipped() -> void:
	HenScriptMacroLoader.load_native_actions()

	_add_action(HenActionsPanel.find_macro(&'random_int'), &'update')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('no output stored')
	assert_str(code).not_contains('randi_range')


# each declared output is optional and independent: a raycast can expose collider,
# point and normal, and an unbound one simply drops its line
func test_multiple_outputs_each_optional() -> void:
	HenScriptMacroLoader.load_native_actions()
	save_data.identity.type = 'CharacterBody3D'

	var hit: HenSaveState = save_data.add_state(false)
	hit.name = 'hit state'
	var miss: HenSaveState = save_data.add_state(false)
	miss.name = 'miss state'

	var collider: HenSaveVar = save_data.add_var(false)
	collider.name = 'who'
	collider.type = 'Variant'
	var point: HenSaveVar = save_data.add_var(false)
	point.name = 'where'
	point.type = 'Vector3'

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'raycast_check'), &'physics')
	action.input_bindings['ray'] = HenUtils.BIND_PATH_PREFIX + 'Ray'
	action.branches['hit'] = {state_id = hit.id, label = ''}
	action.branches['miss'] = {state_id = miss.id, label = ''}
	action.output_bindings['collider'] = HenUtils.bind_code_for_var(collider)
	action.output_bindings['point'] = HenUtils.bind_code_for_var(point)

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref.who = ray_' + str(action.id) + '.get_collider()')
	assert_str(code).contains('_ref.where = ray_' + str(action.id) + '.get_collision_point()')
	# normal was left unbound: its line must vanish, not linger as a placeholder
	assert_str(code).not_contains('get_collision_normal')
	assert_str(code).not_contains('{{out:')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# an input's effective type follows type_from to the output binding. this is what
# the inspector and the cli read to coerce a literal, so a Math slot knows to store
# a number instead of a string. tested on the resolver, since codegen only formats
# an already-coerced value
func test_input_type_follows_the_output_variable() -> void:
	HenScriptMacroLoader.load_native_actions()

	var total: HenSaveVar = save_data.add_var(false)
	total.name = 'total'
	total.type = 'float'

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'math_operator'), &'update')
	var a_input: Dictionary = {type = 'Variant', type_from = 'result'}

	# unbound: the slot stays Variant
	assert_str(HenGeneratorAction.effective_type(save_data, action, a_input)).is_equal('Variant')

	# bound to a float output: the slot follows it
	action.output_bindings['result'] = HenUtils.bind_code_for_var(total)

	assert_str(HenGeneratorAction.effective_type(save_data, action, a_input)).is_equal('float')


# a variable deleted behind an output degrades to unbound: no empty left side,
# and a pure producer that zeroes out falls to the marker
func test_output_to_a_deleted_variable_drops_the_line() -> void:
	HenScriptMacroLoader.load_native_actions()

	var roll: HenSaveVar = save_data.add_var(false)
	roll.name = 'roll'
	roll.type = 'int'

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'random_int'), &'update')
	action.output_bindings['result'] = HenUtils.bind_code_for_var(roll)

	save_data.variables.erase(roll)

	var code: String = HenTest.get_all_code()

	assert_str(code).not_contains(' = randi_range')
	assert_str(code).not_contains('\t = ')
	assert_str(code).contains('no output stored')


# output_bindings survive a save/reload round-trip, like branches do
func test_output_bindings_round_trip() -> void:
	var action := HenSaveAction.new()
	action.macro_id = &'random_int'
	action.output_bindings['result'] = 'var:42'

	var path: String = 'user://out_rt.tres'
	ResourceSaver.save(action, path)
	var loaded: HenSaveAction = ResourceLoader.load(path, '', ResourceLoader.CACHE_MODE_IGNORE) as HenSaveAction

	assert_str(str(loaded.output_bindings.get('result', ''))).is_equal('var:42')


# a producer shows where its output goes in the panel row, not just its inputs
func test_panel_row_shows_a_stored_output() -> void:
	HenScriptMacroLoader.load_native_actions()

	var roll: HenSaveVar = save_data.add_var(false)
	roll.name = 'roll'
	roll.type = 'int'

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'random_int'), &'update')

	# unbound: nothing about the result on the row
	assert_str(HenActionsPanel.value_preview(action)).not_contains('->')

	action.output_bindings['result'] = HenUtils.bind_code_for_var(roll)

	assert_str(HenActionsPanel.value_preview(action)).contains('-> roll')


# two quick-created outputs of the same name must not collide: the second gets a
# suffix, or both emit `var collider` and the script fails to parse
func test_unique_var_name_avoids_collisions() -> void:
	var first: HenSaveVar = save_data.add_var(false)
	first.name = 'collider'

	# same base -> suffixed
	assert_str(save_data.unique_var_name('collider')).is_equal('collider2')

	# a free name is returned untouched
	assert_str(save_data.unique_var_name('normal')).is_equal('normal')

	# five vars from the same base end up with five distinct emitted identifiers
	var ids: Dictionary = {}
	for i: int in 5:
		var v: HenSaveVar = save_data.add_var(false)
		v.name = save_data.unique_var_name('collider')
		ids[v.name.to_snake_case()] = true

	# 5 new + the first 'collider' = 6 unique identifiers, none shared
	assert_int(ids.size()).is_equal(5)
	assert_bool(ids.has('collider')).is_false()


# --- loops ------------------------------------------------------------------


func _nested(_macro_id: StringName) -> HenSaveAction:
	var action := HenSaveAction.new()
	action.macro_id = _macro_id
	action.id = (Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()
	return action


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


# a fire-and-forget tween has nowhere to run per frame, so it only offers enter
func test_tween_is_enter_only() -> void:
	HenScriptMacroLoader.load_native_actions()

	var macro: HenSaveMacro = HenActionsPanel.find_macro(&'tween_move')

	assert_array(HenSaveAction.supported_phases(macro)).is_equal([&'enter'])
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


# --- new categories ---------------------------------------------------------


# the two new folders carry their label, icon and color
func test_tween_and_control_categories_are_registered() -> void:
	var tween: Dictionary = HenActionCategories.get_data('tween')
	var control: Dictionary = HenActionCategories.get_data('control')

	assert_str(str(tween.name)).is_equal('Tween')
	assert_str(str(tween.icon)).is_equal('sparkles')
	assert_str(str(tween.color)).is_equal('#fb7185')

	assert_str(str(control.name)).is_equal('Control')
	assert_str(str(control.icon)).is_equal('sliders-horizontal')
	assert_str(str(control.color)).is_equal('#60a5fa')


# the category is the folder, so the loader tags the new actions from where they live
func test_new_actions_take_their_folder_category() -> void:
	HenScriptMacroLoader.load_native_actions()

	var by_id: Dictionary = {}
	for macro: HenSaveMacro in (Engine.get_singleton(&'Global') as HenGlobal).action_macros:
		by_id[str(macro.id)] = macro

	assert_str(by_id['tween_move'].category).is_equal('tween')
	assert_str(by_id['tween_fade'].category).is_equal('tween')
	assert_str(by_id['set_text'].category).is_equal('control')
	assert_str(by_id['set_control_value'].category).is_equal('control')
	assert_str(by_id['get_nearest'].category).is_equal('scene')


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
	loop.output_bindings['item'] = HenUtils.bind_code_for_var(item)

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
