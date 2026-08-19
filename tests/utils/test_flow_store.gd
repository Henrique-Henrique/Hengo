@tool
class_name TestHenFlowStore extends HenTestSuite

# an action whose only job is to produce a value stops reading as a step of the
# sequence: the store takes its place in the chain and pulls it in as a source

const FIX_RAY: String = 'res://addons/hengo/actions/physics2d/cast_ray.gd'
const FIX_XYZ: String = 'res://addons/hengo/actions/vector/get_vector3_xyz.gd'
const FIX_DISTANCE: String = 'res://addons/hengo/actions/node2d/get_distance.gd'

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


func _add(_macro: HenSaveMacro) -> HenSaveAction:
	var action: HenSaveAction = HenSaveAction.create(_macro)

	action.phase = &'update'
	save_data.add_state_action(state.id, action)

	return action


func _store_nodes(_graph: HenFlowGraphTypes.FlowGraph) -> Array:
	var out: Array = []

	for node: HenFlowGraphTypes.FlowNode in _graph.nodes:
		if node.kind == &'store':
			out.append(node)

	return out


func _node_for(_graph: HenFlowGraphTypes.FlowGraph, _action: HenSaveAction) -> HenFlowGraphTypes.FlowNode:
	for node: HenFlowGraphTypes.FlowNode in _graph.nodes:
		if node.action == _action:
			return node

	return null


func test_an_output_with_no_destination_adds_no_node() -> void:
	var macro: HenSaveMacro = _register(FIX_DISTANCE)
	_add(macro)

	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphBuilder.build(save_data, state)

	assert_int(_store_nodes(graph).size()).is_equal(0)


func test_a_stored_output_adds_one_node_with_one_port() -> void:
	var macro: HenSaveMacro = _register(FIX_DISTANCE)
	var action: HenSaveAction = _add(macro)
	var variable: HenSaveVar = save_data.add_var(false)

	action.output_bindings[str(macro.outputs[0].id)] = HenUtils.bind_code_for_var(variable)

	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphBuilder.build(save_data, state)
	var stores: Array = _store_nodes(graph)

	assert_int(stores.size()).is_equal(1)
	assert_str(stores[0].title).is_equal('Store In')
	assert_int((stores[0] as HenFlowGraphTypes.FlowNode).pins_of(&'data_in').size()).is_equal(1)


func test_three_stored_outputs_share_one_node() -> void:
	var macro: HenSaveMacro = _register(FIX_XYZ)
	var action: HenSaveAction = _add(macro)

	for output: HenSaveParam in macro.outputs:
		var variable: HenSaveVar = save_data.add_var(false)
		action.output_bindings[str(output.id)] = HenUtils.bind_code_for_var(variable)

	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphBuilder.build(save_data, state)
	var stores: Array = _store_nodes(graph)

	assert_int(stores.size()).is_equal(1)
	assert_int((stores[0] as HenFlowGraphTypes.FlowNode).pins_of(&'data_in').size()).is_equal(3)


func test_the_store_stands_in_the_chain_and_the_action_feeds_it() -> void:
	var macro: HenSaveMacro = _register(FIX_DISTANCE)
	var action: HenSaveAction = _add(macro)
	var variable: HenSaveVar = save_data.add_var(false)

	action.output_bindings[str(macro.outputs[0].id)] = HenUtils.bind_code_for_var(variable)

	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphBuilder.build(save_data, state)
	var store: HenFlowGraphTypes.FlowNode = _store_nodes(graph)[0]
	var producer: HenFlowGraphTypes.FlowNode = _node_for(graph, action)

	# the action left the sequence: it is pulled in by a wire, like an inline producer
	assert_str(str(producer.kind)).is_equal('producer')
	assert_int(producer.pins_of(&'exec_out').size()).is_equal(0)
	assert_int(store.pins_of(&'exec_in').size()).is_equal(1)
	assert_int(store.pins_of(&'exec_out').size()).is_equal(1)

	var wired: bool = false
	var entered: bool = false

	for edge: HenFlowGraphTypes.FlowEdge in graph.edges:
		if edge.kind == &'data' and edge.from_node == producer and edge.to_node == store:
			wired = true
		if edge.kind == &'exec' and edge.to_node == store and edge.from_node == graph.entry:
			entered = true

	assert_bool(wired).is_true()
	assert_bool(entered).is_true()


# the left column is where the formatter already puts every source, and the store
# is what keeps the run in the middle
func test_the_action_lands_left_of_its_store() -> void:
	var macro: HenSaveMacro = _register(FIX_DISTANCE)
	var action: HenSaveAction = _add(macro)
	var variable: HenSaveVar = save_data.add_var(false)

	action.output_bindings[str(macro.outputs[0].id)] = HenUtils.bind_code_for_var(variable)

	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphBuilder.build(save_data, state)

	for node: HenFlowGraphTypes.FlowNode in graph.nodes:
		node.size = Vector2(180, 70)

	HenFlowFormatter.format(graph)

	var store: HenFlowGraphTypes.FlowNode = _store_nodes(graph)[0]
	var producer: HenFlowGraphTypes.FlowNode = _node_for(graph, action)

	assert_float(producer.position.x).is_less(store.position.x)


# a branching action still runs the sequence itself, so it keeps its place and the
# store follows it instead of replacing it
func test_a_branching_action_keeps_its_place_and_the_store_follows() -> void:
	var macro: HenSaveMacro = _register(FIX_RAY)
	var action: HenSaveAction = _add(macro)
	var variable: HenSaveVar = save_data.add_var(false)

	action.output_bindings[str(macro.outputs[0].id)] = HenUtils.bind_code_for_var(variable)

	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphBuilder.build(save_data, state)
	var node: HenFlowGraphTypes.FlowNode = _node_for(graph, action)
	var stores: Array = _store_nodes(graph)

	assert_int(stores.size()).is_equal(1)
	assert_str(str(node.kind)).is_equal('action')

	var follows: bool = false

	for edge: HenFlowGraphTypes.FlowEdge in graph.edges:
		if edge.kind == &'exec' and edge.from_node == node and edge.to_node == stores[0]:
			follows = true

	assert_bool(follows).is_true()
