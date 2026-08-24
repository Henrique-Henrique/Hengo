@tool
class_name TestHenFlowStoreLayout extends HenTestSuite

# the formatter owns every position, and a node it never places lands on the origin
# and sits on top of whatever is there. these are the shapes that broke it

const FIX_LOOP: String = 'res://addons/hengo/actions/flow/repeat.gd'
const FIX_DISTANCE: String = 'res://addons/hengo/actions/node2d/get_distance.gd'
const FIX_RAY: String = 'res://addons/hengo/actions/physics2d/cast_ray.gd'
const FIX_PRINT: String = 'res://addons/hengo/actions/debug/print_value.gd'

# a loop that also branches: the body and the branch row share the same card
const FIX_GATE: String = 'res://addons/hengo/actions/flow/do_n_times.gd'
const CARD: Vector2 = Vector2(190.0, 74.0)
const FLOW_ROW: float = 22.0

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

	for flow: Dictionary in instance.get_flow_outputs():
		macro.flow_outputs.append(HenSaveFlowParam.create(flow))

	(Engine.get_singleton(&'Global') as HenGlobal).action_macros.append(macro)

	return macro


func _add(_macro: HenSaveMacro) -> HenSaveAction:
	var action: HenSaveAction = HenSaveAction.create(_macro)

	action.phase = &'update'
	save_data.add_state_action(state.id, action)

	return action


func _store_into(_action: HenSaveAction, _macro: HenSaveMacro, _index: int = 0) -> void:
	_action.output_bindings[str(_macro.outputs[_index].id)] = HenUtils.bind_code_for_var(save_data.add_var(false))


# the add tail is drawn much smaller than a card, and a placement that only holds
# for equal boxes would pass here and still stack them on screen
func _laid_out() -> HenFlowGraphTypes.FlowGraph:
	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphBuilder.build(save_data, state)

	for node: HenFlowGraphTypes.FlowNode in graph.nodes:
		node.size = HenFlowNodeCard.ADD_TAIL_SIZE if node.kind == &'add' else CARD

	HenFlowFormatter.format(graph)

	return graph


# two nodes the sequence connects have to keep the gap the formatter promises,
# or they read as one block on screen
func _tight_links(_graph: HenFlowGraphTypes.FlowGraph) -> Array[String]:
	var hits: Array[String] = []

	for edge: HenFlowGraphTypes.FlowEdge in _graph.edges:
		if edge.kind != &'exec' or edge.to_node.kind == &'transition':
			continue

		# a body member hangs off the loop that contains it, not below it
		if not edge.from_node.body.is_empty():
			continue

		# a long run is cut into columns on purpose, and the next column starts at
		# the top: only two steps of the same column stack vertically
		if absf(edge.from_node.position.x - edge.to_node.position.x) > 1.0:
			continue

		var gap: float = edge.to_node.position.y - (edge.from_node.position.y + edge.from_node.size.y)

		if gap < 1.0:
			hits.append(str(edge.from_node.id) + ' -> ' + str(edge.to_node.id) + ' gap ' + str(snappedf(gap, 0.1)))

	return hits


# a node the formatter forgot keeps the position it was born with
func _overlaps(_graph: HenFlowGraphTypes.FlowGraph) -> Array[String]:
	var hits: Array[String] = []
	var nodes: Array = _graph.nodes

	for i: int in range(nodes.size()):
		for j: int in range(i + 1, nodes.size()):
			var a: HenFlowGraphTypes.FlowNode = nodes[i]
			var b: HenFlowGraphTypes.FlowNode = nodes[j]

			# a loop owns the box its body sits in, so it contains it on purpose
			if a.body.has(b) or b.body.has(a) or not a.body.is_empty() or not b.body.is_empty():
				continue

			if Rect2(a.position, a.size).intersects(Rect2(b.position, b.size)):
				hits.append(str(a.id) + ' over ' + str(b.id))

	return hits


func test_a_plain_run_does_not_stack_cards() -> void:
	var macro: HenSaveMacro = _register(FIX_PRINT)

	for i: int in range(4):
		_add(macro)

	var graph: HenFlowGraphTypes.FlowGraph = _laid_out()

	assert_array(_overlaps(graph)).is_empty()
	assert_array(_tight_links(graph)).is_empty()


func test_a_stored_producer_does_not_stack_cards() -> void:
	var print_macro: HenSaveMacro = _register(FIX_PRINT)
	var macro: HenSaveMacro = _register(FIX_DISTANCE)

	_add(print_macro)
	_store_into(_add(macro), macro)
	_add(print_macro)

	var graph: HenFlowGraphTypes.FlowGraph = _laid_out()

	assert_array(_overlaps(graph)).is_empty()
	assert_array(_tight_links(graph)).is_empty()


func test_a_branch_with_a_store_does_not_stack_cards() -> void:
	var macro: HenSaveMacro = _register(FIX_RAY)

	_store_into(_add(macro), macro)
	_add(_register(FIX_PRINT))

	var graph: HenFlowGraphTypes.FlowGraph = _laid_out()

	assert_array(_overlaps(graph)).is_empty()
	assert_array(_tight_links(graph)).is_empty()


# the shape that broke: a loop whose body holds a stored producer
func test_a_loop_body_with_a_store_does_not_stack_cards() -> void:
	var loop_macro: HenSaveMacro = _register(FIX_LOOP)
	var macro: HenSaveMacro = _register(FIX_DISTANCE)
	var print_macro: HenSaveMacro = _register(FIX_PRINT)
	var loop: HenSaveAction = _add(loop_macro)
	var inner: HenSaveAction = HenSaveAction.create(macro)

	_store_into(inner, macro)
	loop.body_actions.append(inner)
	loop.body_actions.append(HenSaveAction.create(print_macro))

	var graph: HenFlowGraphTypes.FlowGraph = _laid_out()

	assert_array(_overlaps(graph)).is_empty()
	assert_array(_tight_links(graph)).is_empty()


# a stored producer draws as two boxes, and neither one used to be a drag handle
func test_a_stored_producer_keeps_a_drag_handle() -> void:
	var macro: HenSaveMacro = _register(FIX_DISTANCE)
	var action: HenSaveAction = _add(macro)

	_store_into(action, macro)

	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphBuilder.build(save_data, state)
	var kinds: Array[String] = []

	for node: HenFlowGraphTypes.FlowNode in graph.nodes:
		if node.action == action and node.step:
			kinds.append(str(node.kind))

	assert_array(kinds).contains(['store', 'producer'])


# a producer feeding an input is not a step, and dragging it would pull it out of
# the action it belongs to
func test_an_inline_producer_is_not_a_drag_handle() -> void:
	var print_macro: HenSaveMacro = _register(FIX_PRINT)
	var macro: HenSaveMacro = _register(FIX_DISTANCE)
	var host: HenSaveAction = _add(print_macro)
	var inline: HenSaveAction = HenSaveAction.create(macro)

	host.input_actions[str(print_macro.inputs[0].id)] = {
		action = inline,
		output = str(macro.outputs[0].id)
	}

	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphBuilder.build(save_data, state)

	for node: HenFlowGraphTypes.FlowNode in graph.nodes:
		if node.action == inline:
			assert_bool(node.step).is_false()


# an action with a body AND branches keeps its branch row at the bottom of the
# card, so the nested chain has to stop above it instead of covering the cells
func test_a_body_stops_above_the_branch_row() -> void:
	var gate: HenSaveAction = _add(_register(FIX_GATE))

	gate.body_actions.append(HenSaveAction.create(_register(FIX_PRINT)))

	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphBuilder.build(save_data, state)

	for node: HenFlowGraphTypes.FlowNode in graph.nodes:
		node.size = HenFlowNodeCard.ADD_TAIL_SIZE if node.kind == &'add' else CARD

		if node.action == gate:
			node.flow_row_h = FLOW_ROW

	HenFlowFormatter.format(graph)

	for node: HenFlowGraphTypes.FlowNode in graph.nodes:
		if node.action != gate:
			continue

		var limit: float = node.position.y + node.size.y - FLOW_ROW

		for child: HenFlowGraphTypes.FlowNode in node.body:
			assert_bool(child.position.y + child.size.y <= limit).is_true()

		return

	fail('the loop node is missing from the graph')


# a loop inside a loop: the inner tail belongs to the inner body, so it is moved
# by the inner loop only. moved once per ancestor it lands outside the card, and
# the nested loop draws with no way to add its first step
func test_a_loop_inside_a_loop_keeps_its_tail_inside() -> void:
	var macro: HenSaveMacro = _register(FIX_LOOP)
	var outer: HenSaveAction = _add(macro)
	var inner: HenSaveAction = HenSaveAction.create(macro)

	outer.body_actions.append(inner)

	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphBuilder.build(save_data, state)

	for node: HenFlowGraphTypes.FlowNode in graph.nodes:
		node.size = HenFlowNodeCard.ADD_TAIL_SIZE if node.kind == &'add' else CARD

	HenFlowFormatter.format(graph)

	for node: HenFlowGraphTypes.FlowNode in graph.nodes:
		if node.action != inner:
			continue

		assert_int(node.body.size()).is_equal(1)

		var tail: HenFlowGraphTypes.FlowNode = node.body[0]

		assert_bool(Rect2(node.position, node.size).encloses(Rect2(tail.position, tail.size))).is_true()

		return

	fail('the nested loop is missing from the graph')


# the shape the branch steps made possible: a gate with a chain on each branch and
# the run carrying on below it. the sides used to clear only the head of that run,
# which was enough while a branch was a single transition card sitting high
func test_branch_chains_clear_the_run_below_them() -> void:
	var gate: HenSaveAction = _add(_register(FIX_GATE))
	var print_macro: HenSaveMacro = _register(FIX_PRINT)

	gate.branch_actions['within'] = [
		HenSaveAction.create(print_macro), HenSaveAction.create(print_macro)
	] as Array[HenSaveAction]
	gate.branch_actions['done'] = [HenSaveAction.create(print_macro)] as Array[HenSaveAction]

	# the run goes on after the gate, and its own branches make it wide
	var next: HenSaveAction = _add(_register(FIX_GATE))

	next.branch_actions['within'] = [HenSaveAction.create(print_macro)] as Array[HenSaveAction]

	var graph: HenFlowGraphTypes.FlowGraph = _laid_out()

	assert_array(_overlaps(graph)).is_empty()


# a branch that runs steps draws them hanging off its pin, ending in a tail that
# knows which branch a new step lands on
func test_a_branch_chain_ends_in_its_own_tail() -> void:
	var gate: HenSaveAction = _add(_register(FIX_GATE))
	var step: HenSaveAction = HenSaveAction.create(_register(FIX_PRINT))

	gate.branch_actions['done'] = [step] as Array[HenSaveAction]

	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphBuilder.build(save_data, state)
	var tail: HenFlowGraphTypes.FlowNode = null

	for node: HenFlowGraphTypes.FlowNode in graph.nodes:
		if node.kind == &'add' and node.body_parent == gate:
			tail = node

	assert_object(tail).is_not_null()
	assert_str(str(tail.body_branch)).is_equal('done')

	for node: HenFlowGraphTypes.FlowNode in graph.nodes:
		node.size = HenFlowNodeCard.ADD_TAIL_SIZE if node.kind == &'add' else CARD

	HenFlowFormatter.format(graph)

	# the formatter owns every position: a node it never placed sits on the origin
	assert_bool(tail.position != Vector2.ZERO).is_true()
	assert_array(_overlaps(graph)).is_empty()


# an empty body still ends with its tail: without it there is nowhere to drop the
# first nested step and the card draws as if it had no body at all
func test_an_empty_body_keeps_its_tail() -> void:
	var loop: HenSaveAction = _add(_register(FIX_LOOP))

	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphBuilder.build(save_data, state)

	for node: HenFlowGraphTypes.FlowNode in graph.nodes:
		if node.action != loop:
			continue

		assert_int(node.body.size()).is_equal(1)

		var tail: HenFlowGraphTypes.FlowNode = node.body[0]

		assert_str(str(tail.kind)).is_equal('add')
		assert_bool(tail.body_parent == loop).is_true()

		return

	fail('the loop node is missing from the graph')


# the body block has to hold the nodes that carry its sequence, or the loop is
# measured around an empty box and the body spills over it
func test_a_loop_body_lists_the_store_that_carries_it() -> void:
	var loop_macro: HenSaveMacro = _register(FIX_LOOP)
	var macro: HenSaveMacro = _register(FIX_DISTANCE)
	var loop: HenSaveAction = _add(loop_macro)
	var inner: HenSaveAction = HenSaveAction.create(macro)

	_store_into(inner, macro)
	loop.body_actions.append(inner)

	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphBuilder.build(save_data, state)

	for node: HenFlowGraphTypes.FlowNode in graph.nodes:
		if node.action != loop:
			continue

		# the store plus the tail every body ends with
		assert_int(node.body.size()).is_equal(2)
		assert_str(str((node.body[0] as HenFlowGraphTypes.FlowNode).kind)).is_equal('store')
		assert_str(str((node.body[1] as HenFlowGraphTypes.FlowNode).kind)).is_equal('add')

		return

	fail('the loop node is missing from the graph')


# the toggle in the top bar: off, a long run stops being cut into columns and
# every step keeps the same x
func test_turning_wrap_off_keeps_the_run_in_one_column() -> void:
	var macro: HenSaveMacro = _register(FIX_PRINT)

	for i: int in range(8):
		_add(macro)

	var wrapped: HenFlowGraphTypes.FlowGraph = _laid_out()
	var columns: Dictionary = {}

	for node: HenFlowGraphTypes.FlowNode in wrapped.nodes:
		columns[snappedf(node.position.x, 1.0)] = true

	assert_int(columns.size()).is_greater(1)

	# the setting is global and a save() anywhere would carry it to project.godot,
	# so what was there before is put back, absent included
	var had: bool = ProjectSettings.has_setting(HenSettings.FLOW_WRAP_PATH)
	var before: Variant = ProjectSettings.get_setting(HenSettings.FLOW_WRAP_PATH) if had else null

	ProjectSettings.set_setting(HenSettings.FLOW_WRAP_PATH, false)

	var straight: HenFlowGraphTypes.FlowGraph = _laid_out()
	var xs: Dictionary = {}
	var previous: float = -INF
	var ordered: bool = true

	for node: HenFlowGraphTypes.FlowNode in straight.nodes:
		if node.kind != &'action':
			continue

		xs[snappedf(node.position.x, 1.0)] = true

		if node.position.y < previous:
			ordered = false

		previous = node.position.y

	ProjectSettings.set_setting(HenSettings.FLOW_WRAP_PATH, before if had else null)

	assert_int(xs.size()).is_equal(1)
	assert_bool(ordered).is_true()


# a loop inside a loop is measured before the one that holds it, so the outer card
# is inflated around a body that already grew
func test_a_nested_loop_fits_inside_the_loop_that_holds_it() -> void:
	var loop_macro: HenSaveMacro = _register(FIX_LOOP)
	var macro: HenSaveMacro = _register(FIX_DISTANCE)
	var print_macro: HenSaveMacro = _register(FIX_PRINT)
	var outer: HenSaveAction = _add(loop_macro)
	var inner: HenSaveAction = HenSaveAction.create(loop_macro)
	var deep: HenSaveAction = HenSaveAction.create(macro)

	_store_into(deep, macro)
	inner.body_actions.append(deep)
	inner.body_actions.append(HenSaveAction.create(print_macro))
	outer.body_actions.append(inner)

	var graph: HenFlowGraphTypes.FlowGraph = _laid_out()
	var outer_node: HenFlowGraphTypes.FlowNode = null
	var inner_node: HenFlowGraphTypes.FlowNode = null

	for node: HenFlowGraphTypes.FlowNode in graph.nodes:
		if node.action == outer:
			outer_node = node
		elif node.action == inner:
			inner_node = node

	assert_object(outer_node).is_not_null()
	assert_object(inner_node).is_not_null()
	assert_bool(Rect2(outer_node.position, outer_node.size).encloses(Rect2(inner_node.position, inner_node.size))).is_true()
