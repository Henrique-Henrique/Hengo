extends HenActionTestSuite

# covers actions nested as the value of another action: emission, resolution
# and the ui that builds them.

const FIX_VEC_XY: String = 'res://addons/hengo/actions/vector/get_vector2_xy.gd'
const FIX_MOVE: String = 'res://addons/hengo/actions/physics2d/move_and_collide.gd'


# --- inline actions ---------------------------------------------------------


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
