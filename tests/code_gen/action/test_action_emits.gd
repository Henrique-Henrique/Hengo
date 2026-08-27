extends HenActionTestSuite

# covers the emitted-code report behind --preview and --export-actions --with-code,
# and sweeps the shipped pool for the two mistakes it can now catch: an output with
# no rhs and a body token that names no slot.


func _pool() -> Array:
	HenScriptMacroLoader.load_native_actions()

	return HenHengoActions.pool()


func _find(_id: StringName) -> HenSaveMacro:
	HenScriptMacroLoader.load_native_actions()

	return HenActionsPanel.find_macro(_id)


# --- the report -------------------------------------------------------------


# a macro that dispatches on the node type emits two different bodies, and one of
# them alone would be a coin flip
func test_class_dispatch_reports_one_variant_per_class() -> void:
	var report: Array = HenActionEmits.of(_find(&'change_color'))

	assert_int(report.size()).is_equal(2)
	assert_str(str(report[0].target_class)).is_equal('CanvasItem')
	assert_str(str(report[0].code['update'])).contains('.modulate =')
	assert_str(str(report[1].target_class)).is_equal('Node3D')
	assert_str(str(report[1].code['update'])).contains('albedo_color')


func test_a_single_shape_collapses_to_one_variant() -> void:
	var report: Array = HenActionEmits.of(_find(&'set_property'))

	assert_int(report.size()).is_equal(1)
	assert_str(str(report[0].target_class)).is_empty()
	assert_str(str(report[0].code['update'])).contains('.set({{name}}, {{value}})')


# an action whose branches drop the `if` when nobody wires them would report a
# shape it only emits in that one case
func test_branches_are_reported_as_wired() -> void:
	var report: Array = HenActionEmits.of(_find(&'get_node'))

	assert_str(str(report[0].code['enter'])).contains('{{found}}')
	assert_str(str(report[0].code['enter'])).contains('{{missing}}')


func test_outputs_report_their_right_side() -> void:
	var report: Array = HenActionEmits.of(_find(&'get_property'))

	assert_str(str(report[0].outputs['result'])).is_equal('{{node}}.get_indexed({{name}})')


func test_stateful_actions_report_what_they_declare() -> void:
	var declares: Dictionary = HenActionEmits.of(_find(&'double_tap'))[0].declares

	assert_str(str(declares['state_vars'])).contains('var tap_at_{{VCNODE_ID}}')
	assert_str(str(declares['reset'])).contains('tap_at_{{VCNODE_ID}} = -99.0')


# the cli reads a color as a plain array, so the copyable json has to hand one back
func test_usage_json_carries_the_defaults_the_cli_takes() -> void:
	var usage: Dictionary = HenActionEmits.usage(_find(&'change_color'))

	assert_str(str(usage.id)).is_equal('change_color')
	assert_str(str(usage.phase)).is_equal('update')
	assert_array(usage.inputs['color']).is_equal([1.0, 1.0, 1.0, 1.0])
	assert_dict(usage.inputs['ref']).contains_keys(['bind'])


func test_usage_json_lists_the_branches() -> void:
	assert_dict(HenActionEmits.usage(_find(&'double_tap')).branches).contains_keys(['tapped', 'waiting'])


func test_text_prints_the_options_of_a_picker_input() -> void:
	assert_str(HenActionEmits.text(_find(&'double_tap'))).contains('options: KEY_SPACE')


# --- pool sweeps ------------------------------------------------------------


# _output_rhs falls back to 'null' when the method is missing, so a typo in
# get_output_<id> ships an action that quietly stores nothing
func test_every_output_has_a_right_side() -> void:
	var broken: Array = []

	for macro: HenSaveMacro in _pool():
		for variant: Dictionary in HenActionEmits.of(macro):
			for id: String in (variant.outputs as Dictionary):
				if str(variant.outputs[id]) == 'null':
					broken.append(str(macro.id) + '.' + id)

	assert_array(broken).override_failure_message('outputs with no get_output_<id>(): ' + str(broken)).is_empty()


func test_every_body_token_names_a_slot() -> void:
	var unknown: Array = []

	for macro: HenSaveMacro in _pool():
		var known: Array = HenActionEmits.known_tokens(macro)

		for token: String in HenActionEmits.tokens_of(macro):
			if not known.has(token):
				unknown.append(str(macro.id) + ': {{' + token + '}}')

	assert_array(unknown).override_failure_message('body tokens that match no input, output or branch: ' + str(unknown)).is_empty()


func test_every_action_emits_something() -> void:
	var silent: Array = []

	for macro: HenSaveMacro in _pool():
		var report: Array = HenActionEmits.of(macro)

		if report.is_empty() or (report[0].code as Dictionary).is_empty():
			silent.append(str(macro.id))

	assert_array(silent).override_failure_message('actions with no body in any phase: ' + str(silent)).is_empty()
