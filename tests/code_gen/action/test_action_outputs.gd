extends HenActionTestSuite

# covers what an action writes back: the variables its outputs are stored into.

# --- data outputs -----------------------------------------------------------


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
