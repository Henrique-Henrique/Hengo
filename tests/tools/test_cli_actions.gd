extends HenTestSuite

# covers the json -> actions builder behind tools/hengo_cli.gd: the fixture must
# build a full state machine whose code has no unresolved action, and every
# malformed reference must be reported instead of silently emitted.

const FIXTURE: String = 'res://tests/fixtures/cli_actions.json'
# codegen marks an action it could not emit with this prefix
const UNRESOLVED: String = '# hengo: action '

var spec: Dictionary


func before_test() -> void:
	super ()
	HenScriptMacroLoader.load_native_actions()

	spec = _read_fixture()
	save_data.identity.type = spec.get('extends', 'Node')


# the cli passes each script spec through declare() then build_actions()
func _build(_spec: Dictionary) -> String:
	var err: String = HenHengoActions.declare(save_data, _spec)

	if not err.is_empty():
		return err

	return HenHengoActions.build_actions(save_data, _spec, {})


# first script of the fixture, minus the cross-script actions (they need a second
# save data, which only the cli owns)
func _read_fixture() -> Dictionary:
	var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	var script: Dictionary = (json.scripts as Array)[0]

	for state: Dictionary in script.states:
		var actions: Array = []

		for action: Dictionary in state.get('actions', []):
			if not _targets_another_script(action):
				actions.append(action)

		state.actions = actions

	return script


func _targets_another_script(_action: Dictionary) -> bool:
	for target: Variant in _action.get('branches', {}).values():
		if target is Dictionary and (target as Dictionary).has('script'):
			return true

	return false


# a fresh state name per call, so several builds can share one save data
func _build_one(_id: String, _phase: String, _inputs: Dictionary = {}, _branches: Dictionary = {}, _vars: Array = []) -> String:
	return _build({
		name = 'solo',
		vars = _vars,
		states = [ {
			name = 'Solo' + str(save_data.states.size()),
			start = true,
			actions = [ {id = _id, phase = _phase, inputs = _inputs, branches = _branches}]
		}]
	})


# --- building ---------------------------------------------------------------


func test_fixture_builds_states_and_vars() -> void:
	assert_str(_build(spec)).is_empty()

	var names: Array[String] = []
	for state: HenSaveState in save_data.states:
		names.append(state.name)

	assert_array(names).contains(['Idle', 'Run'])
	assert_object(HenHengoActions.find_var(save_data, 'speed')).is_not_null()

	# a vector var is written as a json array and cast by the declared type
	assert_that(HenHengoActions.find_var(save_data, 'dir').default_value).is_equal(Vector2(1, 0))


func test_fixture_emits_every_action() -> void:
	assert_str(_build(spec)).is_empty()

	var code: String = HenTest.get_all_code()

	assert_str(code).not_contains(UNRESOLVED)
	# literal, property binding, expression with bound words and native source
	assert_str(code).contains('print("idle")')
	assert_str(code).contains('_ref.velocity = (_ref.dir * _ref.speed)')
	assert_str(code).contains('if Input.is_action_just_pressed(&"ui_accept"):')
	assert_str(code).contains('print(_ref.get_process_delta_time())')


func test_branches_and_sub_states_reach_their_targets() -> void:
	assert_str(_build(spec)).is_empty()

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('class Breathing extends HengoState:')
	assert_str(code).contains('change_sub_state("breathing")')
	assert_str(code).contains('_ref._STATE_CONTROLLER.change_state("run")')
	# the phase drives which lifecycle method the action lands in
	assert_str(code).contains('func physics(delta) -> void:')


# json numbers are always floats, so an int slot must not emit 2.0
func test_literal_follows_the_bound_target_type() -> void:
	var err: String = _build_one('add_to_value', 'update',
		{target = {bind = 'count'}, amount = 2}, {},
		[ {name = 'count', type = 'int', value = 0}])

	assert_str(err).is_empty()
	assert_str(HenTest.get_all_code()).contains('_ref.count += 2').not_contains('+= 2.0')


# --- validation -------------------------------------------------------------


func test_unknown_action_id_lists_the_available_ones() -> void:
	var err: String = _build_one('set_valu', 'enter')

	assert_str(err).contains('unknown action id "set_valu"')
	assert_str(err).contains('did you mean "set_value"?')


func test_unknown_input_and_branch_are_reported() -> void:
	assert_str(_build_one('print_value', 'enter', {valu = 1})) \
		.contains('input "valu" is not declared (valid: value)')

	assert_str(_build_one('transition', 'enter', {}, {too = 'Solo'})) \
		.contains('branch "too" is not a flow output (valid: to)')


func test_unsupported_phase_is_reported() -> void:
	assert_str(_build_one('set_value', 'physics')) \
		.contains('phase "physics" is not supported')


func test_broken_references_are_reported() -> void:
	assert_str(_build_one('print_value', 'enter', {value = {bind = 'nope'}})) \
		.contains('unknown var "nope"')

	assert_str(_build_one('print_value', 'enter', {value = {native = 'Nope'}})) \
		.contains('unknown native source "Nope"')

	assert_str(_build_one('transition', 'enter', {}, {to = 'Nowhere'})) \
		.contains('unknown state "Nowhere"')


# a dropped feature (funcs, signals, lifecycle flows) must not pass in silence
func test_unknown_schema_key_is_reported() -> void:
	assert_str(_build({name = 'solo', funcs = []})) \
		.contains('unknown key "funcs"')

	assert_str(_build({name = 'solo', states = [ {name = 'Solo', ready = []}]})) \
		.contains('state "Solo": unknown key "ready"')


# an action the script's class can't use never reaches codegen
func test_action_not_serving_the_class_is_reported() -> void:
	save_data.identity.type = 'Node'

	assert_str(_build_one('move_and_slide', 'physics')) \
		.contains('does not serve Node')
