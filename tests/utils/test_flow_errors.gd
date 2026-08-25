@tool
class_name TestHenFlowErrors extends HenTestSuite

# the graph carries the reason the codegen drops a step, so a broken action reads
# as broken on the canvas instead of only in the generated file

const FIX_SET_VALUE: String = 'res://addons/hengo/actions/variable/set_value.gd'
const FIX_DISTANCE: String = 'res://addons/hengo/actions/node2d/get_distance.gd'
const FIX_MATH: String = 'res://addons/hengo/actions/math/math_operator.gd'

var state: HenSaveState


func before_test() -> void:
	super ()
	save_data.identity.type = 'Sprite2D'
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


func _node_for(_graph: HenFlowGraphTypes.FlowGraph, _action: HenSaveAction, _kind: StringName) -> HenFlowGraphTypes.FlowNode:
	for node: HenFlowGraphTypes.FlowNode in _graph.nodes:
		if node.action == _action and node.kind == _kind:
			return node

	return null


func test_a_broken_step_takes_its_reason() -> void:
	var action: HenSaveAction = _add(_register(FIX_SET_VALUE))
	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphBuilder.build(save_data, state)
	var node: HenFlowGraphTypes.FlowNode = _node_for(graph, action, &'action')

	assert_bool(HenFlowGraphBuilder.refresh_error(save_data, state, node)).is_true()
	assert_str(node.error).contains('Target')


func test_a_sound_step_takes_no_error() -> void:
	var speed: HenSaveVar = save_data.add_var(false)
	speed.name = 'speed'
	speed.type = 'float'

	var action: HenSaveAction = _add(_register(FIX_SET_VALUE))
	action.input_bindings['target'] = HenUtils.bind_code_for_var(speed)

	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphBuilder.build(save_data, state)
	var node: HenFlowGraphTypes.FlowNode = _node_for(graph, action, &'action')

	assert_bool(HenFlowGraphBuilder.refresh_error(save_data, state, node)).is_false()
	assert_str(node.error).is_empty()


# the store stands in the chain for its action, so it goes red with it
func test_the_store_takes_the_same_error() -> void:
	var macro: HenSaveMacro = _register(FIX_DISTANCE)
	var action: HenSaveAction = _add(macro)

	action.output_bindings[str(macro.outputs[0].id)] = HenUtils.bind_code_for_var(save_data.add_var(false))

	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphBuilder.build(save_data, state)
	var producer: HenFlowGraphTypes.FlowNode = _node_for(graph, action, &'producer')
	var store: HenFlowGraphTypes.FlowNode = _node_for(graph, action, &'store')

	HenFlowGraphBuilder.refresh_error(save_data, state, producer)
	HenFlowGraphBuilder.refresh_error(save_data, state, store)

	assert_str(producer.error).contains('Target')
	assert_str(store.error).is_equal(producer.error)


# a fault inside an inline producer is reported on the action that pulls it in
func test_an_inline_producer_is_not_asked() -> void:
	var speed: HenSaveVar = save_data.add_var(false)
	speed.name = 'speed'
	speed.type = 'float'

	var child: HenSaveAction = HenSaveAction.create(_register(FIX_MATH))
	var parent: HenSaveAction = _add(_register(FIX_SET_VALUE))

	parent.input_bindings['target'] = HenUtils.bind_code_for_var(speed)
	parent.input_actions['value'] = {action = child, output = &'result'}

	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphBuilder.build(save_data, state)
	var node: HenFlowGraphTypes.FlowNode = _node_for(graph, child, &'producer')

	assert_bool(HenFlowGraphBuilder.refresh_error(save_data, state, node)).is_false()
	assert_str(node.error).is_empty()


# binding the slot clears the mark without rebuilding the graph
func test_refresh_error_clears_a_fixed_step() -> void:
	var speed: HenSaveVar = save_data.add_var(false)
	speed.name = 'speed'
	speed.type = 'float'

	var action: HenSaveAction = _add(_register(FIX_SET_VALUE))
	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphBuilder.build(save_data, state)
	var node: HenFlowGraphTypes.FlowNode = _node_for(graph, action, &'action')

	HenFlowGraphBuilder.refresh_error(save_data, state, node)
	action.input_bindings['target'] = HenUtils.bind_code_for_var(speed)

	assert_bool(HenFlowGraphBuilder.refresh_error(save_data, state, node)).is_true()
	assert_str(node.error).is_empty()
