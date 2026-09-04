extends HenActionTestSuite

# covers an input fed by a value another step already produced: emission, the
# reverse lookup that keeps the producer alive, and the checks around a bad wire.

const FIX_RAY: String = 'res://addons/hengo/actions/physics3d/raycast_check.gd'
const FIX_GET_NODE: String = 'res://addons/hengo/actions/scene/get_node.gd'
const FIX_SET: String = 'res://addons/hengo/actions/variable/set_value.gd'


func _wire(_consumer: HenSaveAction, _key: String, _producer: HenSaveAction, _output: String) -> void:
	_consumer.input_wires[_key] = {
		action_id = StringName(str(_producer.id)),
		output = StringName(_output)
	}


func _store() -> HenSaveVar:
	var kept: HenSaveVar = save_data.add_var(false)
	kept.name = 'kept'
	kept.type = 'Variant'
	return kept


# --- emission ---------------------------------------------------------------


# a branching producer keeps its value in a local, and that local is what the
# reader gets instead of a second call
func test_a_wire_reads_the_local_the_producer_declared() -> void:
	HenScriptMacroLoader.load_native_actions()
	save_data.identity.type = 'Node3D'

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'done'

	var lookup: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'get_node'), &'physics')
	lookup.branches['found'] = {state_id = target.id, label = ''}

	var setter: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'set_value'), &'physics')
	setter.input_bindings['target'] = HenUtils.bind_code_for_var(_store())
	_wire(setter, 'value', lookup, 'result')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref.kept = (node_' + str(lookup.id) + ')')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# with nothing branching off it the producer has no local of its own, so the
# reader takes the whole expression
func test_a_wire_to_a_plain_producer_takes_the_expression() -> void:
	HenScriptMacroLoader.load_native_actions()
	save_data.identity.type = 'Node3D'

	var lookup: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'get_node'), &'physics')
	lookup.inputs[1].default_value = 'Cube'

	var setter: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'set_value'), &'physics')
	setter.input_bindings['target'] = HenUtils.bind_code_for_var(_store())
	_wire(setter, 'value', lookup, 'result')

	assert_str(HenTest.get_all_code()).contains("get_node_or_null('Cube')")


# the node a ray hit is the value a later step wants most, and that slot is
# bind_only, which only rules out being assigned to
func test_a_wire_feeds_a_node_ref_slot() -> void:
	HenScriptMacroLoader.load_native_actions()
	save_data.identity.type = 'Node3D'

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'done'

	var ray: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'raycast_check'), &'physics')
	ray.input_bindings['ray'] = HenUtils.BIND_PATH_PREFIX + 'Ray'

	# the collider only exists on the hit path, so the reader belongs in that branch
	var lookup: HenSaveAction = _nested(&'get_node')
	lookup.branches['found'] = {state_id = target.id, label = ''}
	_wire(lookup, 'ref', ray, 'collider')
	ray.branch_actions['hit'] = [lookup] as Array[HenSaveAction]

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('.get_collider()).get_node_or_null(')
	assert_str(code).not_contains('# hengo:')


# --- the producer stays alive ------------------------------------------------


# its body is only its outputs and nothing stores them, but a reader downstream
# is what it exists for, so it must not be called dead
func test_a_producer_read_only_by_a_wire_is_not_dropped() -> void:
	HenScriptMacroLoader.load_native_actions()
	save_data.identity.type = 'Node3D'

	var lookup: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'get_node'), &'physics')

	assert_str(HenTest.get_all_code()).contains('no output stored')

	var setter: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'set_value'), &'physics')
	setter.input_bindings['target'] = HenUtils.bind_code_for_var(_store())
	_wire(setter, 'value', lookup, 'result')

	assert_str(HenTest.get_all_code()).not_contains('no output stored')


# --- a wire that cannot be resolved ------------------------------------------


func test_a_wire_to_a_missing_step_is_refused() -> void:
	HenScriptMacroLoader.load_native_actions()
	save_data.identity.type = 'Node3D'

	var setter: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'set_value'), &'physics')
	setter.input_bindings['target'] = HenUtils.bind_code_for_var(_store())
	setter.input_wires['value'] = {action_id = &'9999', output = &'result'}

	assert_str(HenTest.get_all_code()).contains('reads a step that no longer exists')


func test_a_wire_to_an_output_the_step_lacks_is_refused() -> void:
	HenScriptMacroLoader.load_native_actions()
	save_data.identity.type = 'Node3D'

	var lookup: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'get_node'), &'physics')

	var setter: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'set_value'), &'physics')
	setter.input_bindings['target'] = HenUtils.bind_code_for_var(_store())
	_wire(setter, 'value', lookup, 'nope')

	assert_str(HenTest.get_all_code()).contains('reads an output that step does not have')


# --- scope ------------------------------------------------------------------


# the collider is written inside the hit branch, so a sibling after the ray reads a
# name that is not declared on the path it runs on
func test_a_wire_out_of_the_producing_branch_is_refused() -> void:
	HenScriptMacroLoader.load_native_actions()
	save_data.identity.type = 'Node3D'

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'done'

	var ray: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'raycast_check'), &'physics')
	ray.input_bindings['ray'] = HenUtils.BIND_PATH_PREFIX + 'Ray'
	ray.branches['hit'] = {state_id = target.id, label = ''}

	var setter: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'set_value'), &'physics')
	setter.input_bindings['target'] = HenUtils.bind_code_for_var(_store())
	_wire(setter, 'value', ray, 'collider')

	assert_str(HenTest.get_all_code()).contains('only exists inside the hit branch')


# the value is produced on the fixed tick and read on the idle one, which are two
# different calls with nothing surviving between them
func test_a_wire_across_phases_is_refused() -> void:
	HenScriptMacroLoader.load_native_actions()
	save_data.identity.type = 'Node3D'

	var lookup: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'get_node'), &'physics')

	var setter: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'set_value'), &'update')
	setter.input_bindings['target'] = HenUtils.bind_code_for_var(_store())
	_wire(setter, 'value', lookup, 'result')

	assert_str(HenTest.get_all_code()).contains('runs on physics, not on update')


func test_a_wire_to_a_later_step_is_refused() -> void:
	HenScriptMacroLoader.load_native_actions()
	save_data.identity.type = 'Node3D'

	var setter: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'set_value'), &'physics')
	setter.input_bindings['target'] = HenUtils.bind_code_for_var(_store())

	var lookup: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'get_node'), &'physics')
	_wire(setter, 'value', lookup, 'result')

	assert_str(HenTest.get_all_code()).contains('only runs after it')


# a step of a loop body leaves nothing behind for the step after the loop
func test_a_wire_out_of_a_loop_body_is_refused() -> void:
	HenScriptMacroLoader.load_native_actions()
	save_data.identity.type = 'Node3D'

	var loop: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'repeat'), &'physics')
	var lookup: HenSaveAction = _nested(&'get_node')
	loop.body_actions.append(lookup)

	var setter: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'set_value'), &'physics')
	setter.input_bindings['target'] = HenUtils.bind_code_for_var(_store())
	_wire(setter, 'value', lookup, 'result')

	assert_str(HenTest.get_all_code()).contains('does not exist on this path')


# --- fan out ----------------------------------------------------------------


# array pop makes this correctness and not taste: two reads of a recomputed value
# would run the producer twice
func test_two_readers_of_a_recomputed_value_park_it_once() -> void:
	HenScriptMacroLoader.load_native_actions()
	save_data.identity.type = 'Node3D'

	var kept: HenSaveVar = _store()

	var ray: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'raycast_check'), &'physics')
	ray.input_bindings['ray'] = HenUtils.BIND_PATH_PREFIX + 'Ray'

	var steps: Array[HenSaveAction] = []

	for i: int in 2:
		var setter: HenSaveAction = _nested(&'set_value')
		setter.input_bindings['target'] = HenUtils.bind_code_for_var(kept)
		_wire(setter, 'value', ray, 'collider')
		steps.append(setter)

	ray.branch_actions['hit'] = steps

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('var wire_' + str(ray.id) + '_collider = ')
	assert_int(code.count('.get_collider()')).is_equal(1)

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# the producer already keeps it, so a second reader costs nothing and parking it
# again would only add a name
func test_a_value_already_in_a_local_is_not_parked_again() -> void:
	HenScriptMacroLoader.load_native_actions()
	save_data.identity.type = 'Node3D'

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'done'

	var kept: HenSaveVar = _store()

	var lookup: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'get_node'), &'physics')
	lookup.branches['found'] = {state_id = target.id, label = ''}

	for i: int in 2:
		var setter: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'set_value'), &'physics')
		setter.input_bindings['target'] = HenUtils.bind_code_for_var(kept)
		_wire(setter, 'value', lookup, 'result')

	var code: String = HenTest.get_all_code()

	assert_str(code).not_contains('var wire_')
	assert_int(code.count('_ref.kept = (node_' + str(lookup.id) + ')')).is_equal(2)
