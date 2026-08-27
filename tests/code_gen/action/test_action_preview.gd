extends HenActionTestSuite

# covers how an action reads in the ui: pool names, row previews and the
# category a macro takes from its folder.

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
func test_slot_type_follows_the_bound_target() -> void:
	var my_var: HenSaveVar = save_data.add_var(false)
	my_var.name = 'my_speed'
	my_var.type = 'float'

	var action: HenSaveAction = _add_action(_register(FIX_TYPED), &'update')
	action.input_bindings['target'] = 'my_speed'

	assert_str(str(HenActionsPanel.value_parts(action)[1].slot.type)).is_equal('float')


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


# --- pickers ----------------------------------------------------------------


# an input naming something the project already declares has to offer the list:
# typing an input action or a group by hand is how a silent typo gets in
func test_named_slots_offer_their_picker() -> void:
	HenScriptMacroLoader.load_native_actions()

	var expected: Dictionary = {action = 'input_action', group = 'group'}
	var missing: Array[String] = []

	for macro: HenSaveMacro in (Engine.get_singleton(&'Global') as HenGlobal).action_macros:
		for param: HenSaveParam in macro.inputs:
			var wanted: String = str(expected.get(str(param.id), ''))

			if wanted.is_empty() or str(param.type) != 'StringName':
				continue

			if str(param.picker) != wanted:
				missing.append('%s.%s wants the %s picker, has "%s"' % [macro.id, param.id, wanted, param.picker])

	assert_array(missing).override_failure_message('\n'.join(missing)).is_empty()
