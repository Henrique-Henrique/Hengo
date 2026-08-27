extends HenActionTestSuite

# covers what an action reads: literals, bindings to variables, properties and
# node paths, expressions, options and write targets.

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
	_sink(action, &'result', my_var)

	for param: HenSaveParam in action.inputs:
		match str(param.id):
			'a': param.default_value = 3.0
			'b': param.default_value = 2.0
			'op': param.default_value = '*'

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref.score = (3.0 * 2.0)')
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
		# not every argument is an input action: a key one is an engine constant
		var expression: String = HenUtils.native_source_code(source, str(source.get('arg_example', 'ui_accept')))

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


# --- parameterized bind sources ---------------------------------------------


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
