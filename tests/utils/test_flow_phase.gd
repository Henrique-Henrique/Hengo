@tool
class_name TestHenFlowPhase extends HenTestSuite

# the wire colour of a whole run is read off the node it leaves, so every node
# the builder emits has to name the phase it runs in


const FIX_PHASES: String = 'res://tests/fixtures/action_phases.gd'
const FIX_LOOP: String = 'res://addons/hengo/actions/flow/repeat.gd'

var state: HenSaveState


func before_test() -> void:
	super ()
	state = save_data.add_state(false)
	state.name = 'Play'


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

	for output: Dictionary in instance.get_outputs():
		macro.outputs.append(HenSaveParam.create(output))

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


func test_every_step_of_a_run_carries_its_phase() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)
	var first: HenSaveAction = _add(macro, &'physics')
	var second: HenSaveAction = _add(macro, &'physics')
	var other: HenSaveAction = _add(macro, &'update')

	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphBuilder.build(save_data, state)

	assert_str(str(_node_for(graph, first).phase)).is_equal('physics')
	assert_str(str(_node_for(graph, second).phase)).is_equal('physics')
	assert_str(str(_node_for(graph, other).phase)).is_equal('update')


func _tail_phases(_graph: HenFlowGraphTypes.FlowGraph) -> Array:
	var out: Array = []

	for node: HenFlowGraphTypes.FlowNode in _graph.nodes:
		if node.kind == &'add':
			out.append(str(node.phase))

	return out


func _ports(_graph: HenFlowGraphTypes.FlowGraph) -> Array:
	var out: Array = []

	for pin: HenFlowGraphTypes.FlowPin in _graph.entry.pins_of(&'exec_out'):
		out.append(str(pin.id))

	return out


# the cell is what a step is added through, so an empty phase has to keep its port
func test_an_empty_state_offers_every_phase() -> void:
	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphBuilder.build(save_data, state)

	assert_array(_ports(graph)).contains_exactly(['enter', 'update', 'physics', 'exit'])


# a tail per phase widened every state, so only a chain that exists gets one
func test_only_a_phase_in_use_gets_a_tail() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)

	_add(macro, &'update')

	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphBuilder.build(save_data, state)

	assert_array(_tail_phases(graph)).contains_exactly(['update'])
	assert_array(_ports(graph)).contains_exactly(['enter', 'update', 'physics', 'exit'])


func test_an_empty_state_draws_nothing_but_its_entry() -> void:
	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphBuilder.build(save_data, state)

	assert_int(graph.nodes.size()).is_equal(1)
	assert_array(_tail_phases(graph)).is_empty()


# the port reads as a moment in time, and the raw key is the codegen's own word
func test_a_phase_port_is_labelled_for_a_reader() -> void:
	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphBuilder.build(save_data, state)

	assert_str(graph.entry.pin(&'enter').label).is_equal(HenActionVisuals.phase_label(&'enter'))
	assert_str(graph.entry.pin(&'enter').label).is_not_equal('enter')


func test_a_loop_body_inherits_the_phase() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)
	var loop_macro: HenSaveMacro = _register(FIX_LOOP)
	var loop: HenSaveAction = _add(loop_macro, &'physics')
	var inner: HenSaveAction = HenSaveAction.create(macro)

	loop.body_actions.append(inner)

	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphBuilder.build(save_data, state)

	assert_str(str(_node_for(graph, inner).phase)).is_equal('physics')
