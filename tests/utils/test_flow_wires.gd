@tool
class_name TestHenFlowWires extends HenTestSuite

# a wire is an edge of its own kind in the graph: the router leaves it undrawn, the
# layout does not treat its producer as an inline source, and the card can find it

const FIX_RAY: String = 'res://addons/hengo/actions/physics3d/raycast_check.gd'
const FIX_SET: String = 'res://addons/hengo/actions/variable/set_value.gd'

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

	for input: Dictionary in instance.get_inputs():
		macro.inputs.append(HenSaveParam.create(input))

	for output: Dictionary in instance.get_outputs():
		macro.outputs.append(HenSaveParam.create(output))

	for flow: Dictionary in instance.get_flow_outputs():
		macro.flow_outputs.append(HenSaveFlowParam.create(flow))

	(Engine.get_singleton(&'Global') as HenGlobal).action_macros.append(macro)

	return macro


func _add(_macro: HenSaveMacro, _phase: StringName) -> HenSaveAction:
	var action: HenSaveAction = HenSaveAction.create(_macro)
	action.phase = _phase
	save_data.add_state_action(state.id, action)
	return action


func _build() -> HenFlowGraphTypes.FlowGraph:
	return HenFlowGraphBuilder.build(save_data, state)


# it draws where an inline producer would, so it reaches the slot as a data edge
func test_a_wired_input_gets_a_reference_card() -> void:
	var ray: HenSaveAction = _add(_register(FIX_RAY), &'physics')
	var setter: HenSaveAction = _add(_register(FIX_SET), &'physics')

	setter.input_wires['value'] = {
		action_id = StringName(str(ray.id)),
		output = &'collider'
	}

	var graph: HenFlowGraphTypes.FlowGraph = _build()
	var refs: Array = graph.nodes_of(&'wire_ref')
	var data: Array = graph.edges_of(&'data')

	assert_int(refs.size()).is_equal(1)
	assert_str((refs[0] as HenFlowGraphTypes.FlowNode).title).is_equal('Collider')
	assert_int(data.size()).is_equal(1)
	assert_object((data[0] as HenFlowGraphTypes.FlowEdge).from_node).is_same(refs[0])
	assert_str(str((data[0] as HenFlowGraphTypes.FlowEdge).to_pin)).is_equal('value')


# the reference stands in for the step, it does not become a second copy of it
func test_the_reference_is_not_a_second_copy_of_the_step() -> void:
	var ray: HenSaveAction = _add(_register(FIX_RAY), &'physics')

	for i: int in 2:
		var setter: HenSaveAction = _add(_register(FIX_SET), &'physics')
		setter.input_wires['value'] = {
			action_id = StringName(str(ray.id)),
			output = &'collider'
		}

	var graph: HenFlowGraphTypes.FlowGraph = _build()
	var steps: int = 0

	for node: HenFlowGraphTypes.FlowNode in graph.nodes:
		if node.action == ray and node.kind != &'wire_ref':
			steps += 1

	assert_int(steps).is_equal(1)
	assert_int(graph.nodes_of(&'wire_ref').size()).is_equal(2)
	assert_int(ray.input_wires.size()).is_equal(0)


# --- inline producer --------------------------------------------------------


const FIX_NODE: String = 'res://addons/hengo/actions/scene/get_node.gd'


func _inline(_owner: HenSaveAction, _input: StringName, _macro: HenSaveMacro, _output: StringName) -> HenSaveAction:
	var child: HenSaveAction = HenSaveAction.create(_macro)

	_owner.input_actions[str(_input)] = {action = child, output = _output}

	return child


# the inline copy is only ever asked for its value, so the branches it would draw
# as a step point nowhere and read as dead pins on the card
func test_an_inline_producer_draws_no_branch() -> void:
	var node_macro: HenSaveMacro = _register(FIX_NODE)
	var setter: HenSaveAction = _add(_register(FIX_SET), &'physics')

	_inline(setter, &'value', node_macro, &'result')

	var producer: HenFlowGraphTypes.FlowNode = null

	for node: HenFlowGraphTypes.FlowNode in _build().nodes:
		if node.kind == &'producer':
			producer = node

	assert_object(producer).is_not_null()
	assert_array(producer.pins_of(&'exec_out')).is_empty()
	assert_array(producer.pins_of(&'data_out')).is_not_empty()


# the same action as a step keeps every branch it declares
func test_the_same_action_as_a_step_keeps_its_branches() -> void:
	_add(_register(FIX_NODE), &'physics')

	var step: HenFlowGraphTypes.FlowNode = null

	for node: HenFlowGraphTypes.FlowNode in _build().nodes:
		if node.kind == &'action':
			step = node

	var branches: Array[String] = []

	for pin: HenFlowGraphTypes.FlowPin in step.pins_of(&'exec_out'):
		branches.append(str(pin.id))

	assert_array(branches).contains(['found', 'missing'])
