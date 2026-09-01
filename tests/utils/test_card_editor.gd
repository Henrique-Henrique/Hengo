@tool
class_name TestHenCardEditor extends HenTestSuite

# the index the add-above and add-below entries hand to open_add: it is a
# position inside the phase bucket, not inside the whole action list


const FIX_PHASES: String = 'res://tests/fixtures/action_phases.gd'
const FIX_LOOP: String = 'res://addons/hengo/actions/flow/repeat.gd'
const FIX_IF: String = 'res://addons/hengo/actions/flow/if_condition.gd'

var state: HenSaveState
var editor: HenStateViewerCardEditor


func before_test() -> void:
	super ()
	state = save_data.add_state(false)
	state.name = 'Play'
	editor = HenStateViewerCardEditor.new()
	editor.target(save_data, StringName(str(state.id)))


func _register(_path: String) -> HenSaveMacro:
	var instance: HenScriptMacroBase = (load(_path) as GDScript).new()
	var macro: HenSaveMacro = HenSaveMacro.new()

	macro.id = instance.get_id()
	macro.name = _path.get_file().get_basename()
	macro.is_script_macro = true
	macro.script_path = _path
	macro.has_body = instance.get_has_body()

	for input: Dictionary in instance.get_inputs():
		macro.inputs.append(HenSaveParam.create(input))

	# supported_phases reads these, so a macro registered without them only ever
	# offers update
	for flow_input: Dictionary in instance.get_flow_inputs():
		macro.flow_inputs.append(HenSaveFlowParam.create(flow_input))

	for flow_output: Dictionary in instance.get_flow_outputs():
		macro.flow_outputs.append(HenSaveFlowParam.create(flow_output))

	(Engine.get_singleton(&'Global') as HenGlobal).action_macros.append(macro)

	return macro


func _add(_macro: HenSaveMacro, _phase: StringName) -> HenSaveAction:
	var action: HenSaveAction = HenSaveAction.create(_macro)

	action.phase = _phase
	save_data.add_state_action(state.id, action)

	return action


func _node_for(_graph: HenFlowGraphTypes.FlowGraph, _action: HenSaveAction) -> HenFlowGraphTypes.FlowNode:
	for node: HenFlowGraphTypes.FlowNode in _graph.nodes:
		if node.action == _action:
			return node

	return null


func test_the_index_counts_inside_the_phase_and_not_the_list() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)

	_add(macro, &'enter')
	_add(macro, &'update')

	var second: HenSaveAction = _add(macro, &'update')

	assert_int(editor.index_around(second, false)).is_equal(1)
	assert_int(editor.index_around(second, true)).is_equal(2)


func test_the_index_of_a_nested_step_counts_inside_the_body() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)
	var loop_macro: HenSaveMacro = _register(FIX_LOOP)
	var loop: HenSaveAction = _add(loop_macro, &'update')
	var first: HenSaveAction = HenSaveAction.create(macro)
	var second: HenSaveAction = HenSaveAction.create(macro)

	loop.body_actions.append(first)
	loop.body_actions.append(second)

	assert_int(editor.index_around(second, false)).is_equal(1)
	assert_int(editor.index_around(second, true)).is_equal(2)


func test_an_action_outside_the_state_has_no_index() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)

	assert_int(editor.index_around(HenSaveAction.create(macro), false)).is_equal(-1)


# the tail of an empty phase is the whole point of showing one per phase: what it
# adds has to land there and not on the macro default
func test_the_tail_of_a_phase_adds_to_that_phase() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)

	editor._do_insert(macro, save_data, StringName(str(state.id)), null, &'exit', -1)

	var actions: Array = save_data.get_state_actions(state.id)

	assert_int(actions.size()).is_equal(1)
	assert_str(str((actions[0] as HenSaveAction).phase)).is_equal('exit')


func test_a_phase_the_macro_cannot_run_falls_back_to_its_default() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)

	editor._do_insert(macro, save_data, StringName(str(state.id)), null, &'physics', -1)

	var actions: Array = save_data.get_state_actions(state.id)

	assert_str(str((actions[0] as HenSaveAction).phase)).is_equal('update')


# a step of a branch is drawn hanging off that branch pin, so the chain the graph
# shows is what tells a wrong list apart from a right one
func _branch_chain(_host: HenSaveAction, _key: StringName) -> Array[HenSaveAction]:
	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphBuilder.build(save_data, state)
	var node: HenFlowGraphTypes.FlowNode = null
	var out: Array[HenSaveAction] = []

	for candidate: HenFlowGraphTypes.FlowNode in graph.nodes:
		if candidate.action == _host:
			node = candidate

	var pin: StringName = _key

	while node:
		var next: HenFlowGraphTypes.FlowNode = null

		for edge: HenFlowGraphTypes.FlowEdge in graph.edges_of(&'exec'):
			if edge.from_node == node and edge.from_pin == pin:
				next = edge.to_node

		if not next or not next.action:
			break

		out.append(next.action)

		node = next
		pin = HenFlowGraphTypes.THEN_PIN

	return out


func _branching_host() -> HenSaveAction:
	var host: HenSaveAction = HenSaveAction.create(_register(FIX_IF))

	host.phase = &'update'
	save_data.add_state_action(state.id, host)

	return host


func _fill_branch(_host: HenSaveAction, _key: String, _macro: HenSaveMacro, _count: int) -> Array[HenSaveAction]:
	var steps: Array[HenSaveAction] = []

	for i: int in range(_count):
		steps.append(HenSaveAction.create(_macro))

	var stored: Array[HenSaveAction] = steps.duplicate()

	_host.branch_actions[_key] = stored

	return steps


func test_a_step_of_a_branch_reports_that_branch() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)
	var host: HenSaveAction = _branching_host()
	var steps: Array[HenSaveAction] = _fill_branch(host, 'false', macro, 2)

	assert_str(str(editor._branch_key_of(steps[1]))).is_equal('false')
	assert_object(editor._parent_of(steps[1])).is_same(host)


func test_a_step_of_a_body_reports_no_branch() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)
	var loop: HenSaveAction = _add(_register(FIX_LOOP), &'update')
	var step: HenSaveAction = HenSaveAction.create(macro)

	loop.body_actions.append(step)

	assert_str(str(editor._branch_key_of(step))).is_equal('')


# replacing the middle step of a branch used to drop the branch and send the new
# step to the body, where nothing draws it and nothing emits it
func test_replacing_a_branch_step_stays_in_that_branch() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)
	var host: HenSaveAction = _branching_host()
	var steps: Array[HenSaveAction] = _fill_branch(host, 'false', macro, 3)
	var slot: Dictionary = editor._slot_around(steps[1], false)

	save_data.remove_action_anywhere(state.id, steps[1])
	editor._do_insert(macro, save_data, StringName(str(state.id)), slot.parent, &'update', slot.at, slot.branch)

	var branch: Array = host.branch_actions['false']

	assert_int(branch.size()).is_equal(3)
	assert_object(branch[0]).is_same(steps[0])
	assert_object(branch[2]).is_same(steps[2])
	assert_int(host.body_actions.size()).is_equal(0)
	assert_int(save_data.get_state_actions(state.id).size()).is_equal(1)

	var chain: Array[HenSaveAction] = _branch_chain(host, &'false')

	assert_int(chain.size()).is_equal(3)
	assert_object(chain[1]).is_same(branch[1])


func test_adding_below_a_branch_step_stays_in_that_branch() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)
	var host: HenSaveAction = _branching_host()
	var steps: Array[HenSaveAction] = _fill_branch(host, 'false', macro, 2)
	var slot: Dictionary = editor._slot_around(steps[0], true)

	editor._do_insert(macro, save_data, StringName(str(state.id)), slot.parent, &'update', slot.at, slot.branch)

	var branch: Array = host.branch_actions['false']

	assert_int(branch.size()).is_equal(3)
	assert_object(branch[0]).is_same(steps[0])
	assert_object(branch[2]).is_same(steps[1])
	assert_int(save_data.get_state_actions(state.id).size()).is_equal(1)


func test_pasting_next_to_a_branch_step_stays_in_that_branch() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)
	var host: HenSaveAction = _branching_host()
	var steps: Array[HenSaveAction] = _fill_branch(host, 'false', macro, 1)
	var copy: HenSaveAction = HenSaveAction.create(macro)

	assert_bool(editor.paste_around([copy], steps[0])).is_true()

	assert_int((host.branch_actions['false'] as Array).size()).is_equal(2)
	assert_int(save_data.get_state_actions(state.id).size()).is_equal(1)

	var chain: Array[HenSaveAction] = _branch_chain(host, &'false')

	assert_int(chain.size()).is_equal(2)
	assert_object(chain[1]).is_same(copy)


func test_a_renamed_action_reaches_the_flow_node() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)
	var action: HenSaveAction = _add(macro, &'update')

	action.label = 'Hit Counter'

	var node: HenFlowGraphTypes.FlowNode = _node_for(HenFlowGraphBuilder.build(save_data, state), action)

	assert_object(node).is_not_null()
	assert_str(node.title).is_equal('Hit Counter')

	action.label = ''

	node = _node_for(HenFlowGraphBuilder.build(save_data, state), action)

	assert_str(node.title).is_equal(macro.name)
