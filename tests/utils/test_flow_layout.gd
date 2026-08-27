@tool
class_name TestHenFlowLayout extends GdUnitTestSuite

# guards the layout invariants the temp/ probes measure by hand: a subtree lands
# on the side of the cell that feeds it, the sequence drops straight, sibling
# runs take distinct depths and a wire never overshoots its target

var _wrap_before: Variant


# wrap is a project setting the plugin writes to disk, so whoever last touched the
# editor decided whether these run against a wrapped layout or a straight one
func before_test() -> void:
	_wrap_before = ProjectSettings.get_setting(HenSettings.FLOW_WRAP_PATH) if ProjectSettings.has_setting(HenSettings.FLOW_WRAP_PATH) else null
	ProjectSettings.set_setting(HenSettings.FLOW_WRAP_PATH, true)


func after_test() -> void:
	ProjectSettings.set_setting(HenSettings.FLOW_WRAP_PATH, _wrap_before)


func _node(
	_graph: HenFlowGraphTypes.FlowGraph,
	_id: String,
	_kind: StringName,
	_size: Vector2
) -> HenFlowGraphTypes.FlowNode:
	var node: HenFlowGraphTypes.FlowNode = HenFlowGraphTypes.FlowNode.new()

	node.id = StringName(_id)
	node.kind = _kind
	node.size = _size

	var enter: HenFlowGraphTypes.FlowPin = node.add_pin(
		HenFlowGraphTypes.FlowPin.new(HenFlowGraphTypes.ENTER_PIN, &'exec_in')
	)

	enter.rect = Rect2(Vector2(_size.x * 0.5 - 1.0, 0.0), Vector2(2.0, 2.0))
	_graph.add_node(node)

	return node


# same pin order as the builder: `then` first, cells after it
func _action(_graph: HenFlowGraphTypes.FlowGraph, _id: String, _size: Vector2) -> HenFlowGraphTypes.FlowNode:
	var node: HenFlowGraphTypes.FlowNode = _node(_graph, _id, &'action', _size)

	_cell(node, HenFlowGraphTypes.THEN_PIN, '', _size.x * 0.5)

	return node


func _cell(_owner: HenFlowGraphTypes.FlowNode, _id: StringName, _label: String, _cx: float) -> void:
	var pin: HenFlowGraphTypes.FlowPin = _owner.add_pin(
		HenFlowGraphTypes.FlowPin.new(_id, &'exec_out', _label)
	)

	pin.rect = Rect2(Vector2(_cx - 1.0, _owner.size.y - 2.0), Vector2(2.0, 2.0))


func _chain(
	_graph: HenFlowGraphTypes.FlowGraph,
	_from: HenFlowGraphTypes.FlowNode,
	_pin: StringName,
	_to: HenFlowGraphTypes.FlowNode
) -> void:
	_graph.connect_pins(&'exec', _from, _pin, _to, HenFlowGraphTypes.ENTER_PIN)


func _cx(_of: HenFlowGraphTypes.FlowNode) -> float:
	return _of.position.x + _of.size.x * 0.5


func test_a_branch_subtree_lands_on_its_cell_side() -> void:
	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphTypes.FlowGraph.new()
	var entry: HenFlowGraphTypes.FlowNode = _node(graph, 'entry', &'state_entry', Vector2(150, 70))
	var check: HenFlowGraphTypes.FlowNode = _action(graph, 'check', Vector2(200, 100))
	var next: HenFlowGraphTypes.FlowNode = _action(graph, 'next', Vector2(150, 70))
	var run: HenFlowGraphTypes.FlowNode = _node(graph, 'run', &'transition', Vector2(150, 70))
	var walk: HenFlowGraphTypes.FlowNode = _node(graph, 'walk', &'transition', Vector2(150, 70))

	graph.entry = entry
	_cell(entry, &'update', 'update', 75.0)
	_cell(check, &'true', 'True', 50.0)
	_cell(check, &'false', 'False', 150.0)

	_chain(graph, entry, &'update', check)
	_chain(graph, check, &'true', run)
	_chain(graph, check, &'false', walk)
	_chain(graph, check, HenFlowGraphTypes.THEN_PIN, next)

	HenFlowFormatter.format(graph)

	assert_float(_cx(next)).is_equal_approx(_cx(check), 0.5)
	assert_bool(_cx(run) < _cx(check)).is_true()
	assert_bool(_cx(walk) > _cx(check)).is_true()


# a run card wider than the corridor used to land on the branch beside it
func test_the_run_column_does_not_touch_a_branch_beside_it() -> void:
	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphTypes.FlowGraph.new()
	var entry: HenFlowGraphTypes.FlowNode = _node(graph, 'entry', &'state_entry', Vector2(150, 70))
	var check: HenFlowGraphTypes.FlowNode = _action(graph, 'check', Vector2(200, 100))
	var jump: HenFlowGraphTypes.FlowNode = _action(graph, 'jump', Vector2(150, 100))
	var tail: HenFlowGraphTypes.FlowNode = _node(graph, 'tail', &'add', Vector2(132, 30))
	var wide: HenFlowGraphTypes.FlowNode = _action(graph, 'wide', Vector2(420, 90))

	graph.entry = entry
	_cell(entry, &'update', 'update', 75.0)
	_cell(check, &'true', 'True', 50.0)

	_chain(graph, entry, &'update', check)
	_chain(graph, check, &'true', jump)
	_chain(graph, jump, HenFlowGraphTypes.THEN_PIN, tail)
	_chain(graph, check, HenFlowGraphTypes.THEN_PIN, wide)

	HenFlowFormatter.format(graph)

	for side: HenFlowGraphTypes.FlowNode in [jump, tail]:
		assert_bool(
			Rect2(side.position, side.size).intersects(Rect2(wide.position, wide.size))
		).is_false()

	assert_float(wide.position.x).is_greater(tail.position.x + tail.size.x)


# the run sits below the branch row, and not below the run that branch carries
func test_the_run_does_not_wait_under_a_tall_branch() -> void:
	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphTypes.FlowGraph.new()
	var entry: HenFlowGraphTypes.FlowNode = _node(graph, 'entry', &'state_entry', Vector2(150, 70))
	var check: HenFlowGraphTypes.FlowNode = _action(graph, 'check', Vector2(200, 100))
	var next: HenFlowGraphTypes.FlowNode = _action(graph, 'next', Vector2(150, 70))
	var walk: HenFlowGraphTypes.FlowNode = _action(graph, 'walk', Vector2(150, 70))
	var deep: HenFlowGraphTypes.FlowNode = _action(graph, 'deep', Vector2(150, 70))

	graph.entry = entry
	_cell(entry, &'update', 'update', 75.0)
	_cell(check, &'true', 'True', 50.0)
	_cell(check, &'false', 'False', 150.0)

	_chain(graph, entry, &'update', check)
	_chain(graph, check, HenFlowGraphTypes.THEN_PIN, next)
	_chain(graph, check, &'false', walk)
	_chain(graph, walk, HenFlowGraphTypes.THEN_PIN, deep)

	var tall: HenFlowGraphTypes.FlowNode = deep

	for i: int in range(4):
		var step: HenFlowGraphTypes.FlowNode = _action(graph, 'tall%d' % i, Vector2(150, 200))

		_chain(graph, tall, HenFlowGraphTypes.THEN_PIN, step)
		tall = step

	HenFlowFormatter.format(graph)

	assert_float(next.position.y).is_greater(walk.position.y + walk.size.y)
	assert_float(next.position.y - (walk.position.y + walk.size.y)) 		.is_less_equal(HenFlowFormatter.MIDDLE_Y_GAP + 0.5)
	assert_bool(next.position.y < tall.position.y).is_true()
	assert_bool(_cx(walk) > _cx(next) + next.size.x * 0.5).is_true()


func test_a_lone_branch_target_sits_under_its_cell() -> void:
	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphTypes.FlowGraph.new()
	var entry: HenFlowGraphTypes.FlowNode = _node(graph, 'entry', &'state_entry', Vector2(150, 70))
	var check: HenFlowGraphTypes.FlowNode = _action(graph, 'check', Vector2(200, 100))
	var fire: HenFlowGraphTypes.FlowNode = _node(graph, 'fire', &'transition', Vector2(150, 70))

	graph.entry = entry
	_cell(entry, &'update', 'update', 75.0)
	_cell(check, &'true', 'True', 50.0)

	_chain(graph, entry, &'update', check)
	_chain(graph, check, &'true', fire)

	HenFlowFormatter.format(graph)

	assert_float(_cx(fire)).is_equal_approx(check.position.x + 50.0, 0.5)


func test_the_entry_centres_over_the_chain_heads() -> void:
	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphTypes.FlowGraph.new()
	var entry: HenFlowGraphTypes.FlowNode = _node(graph, 'entry', &'state_entry', Vector2(150, 70))
	var first: HenFlowGraphTypes.FlowNode = _action(graph, 'first', Vector2(150, 70))
	var second: HenFlowGraphTypes.FlowNode = _action(graph, 'second', Vector2(400, 70))

	graph.entry = entry
	_cell(entry, &'enter', 'enter', 37.5)
	_cell(entry, &'update', 'update', 112.5)

	_chain(graph, entry, &'enter', first)
	_chain(graph, entry, &'update', second)

	HenFlowFormatter.format(graph)

	assert_float(_cx(entry)).is_equal_approx((_cx(first) + _cx(second)) * 0.5, 0.5)


# the satellite widens one step's box on one side, which is what used to bend the
# spine when the wrap centred boxes instead of cards
func test_wrapped_steps_align_on_the_card_centres() -> void:
	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphTypes.FlowGraph.new()
	var entry: HenFlowGraphTypes.FlowNode = _node(graph, 'entry', &'state_entry', Vector2(150, 70))

	graph.entry = entry
	_cell(entry, &'update', 'update', 75.0)

	var previous: HenFlowGraphTypes.FlowNode = entry
	var previous_pin: StringName = &'update'

	for i: int in range(6):
		var step: HenFlowGraphTypes.FlowNode = _action(graph, 'a%d' % i, Vector2(200, 140))

		_chain(graph, previous, previous_pin, step)

		if i == 2:
			var out: HenFlowGraphTypes.FlowNode = _node(graph, 'out', &'transition', Vector2(150, 70))

			_cell(step, &'true', 'True', 50.0)
			_chain(graph, step, &'true', out)

		previous = step
		previous_pin = HenFlowGraphTypes.THEN_PIN

	HenFlowFormatter.format(graph)

	assert_int(graph.lanes.size()).is_greater(0)

	var misaligned: int = 0

	for edge: HenFlowGraphTypes.FlowEdge in graph.edges_of(&'exec'):
		if edge.from_pin != HenFlowGraphTypes.THEN_PIN or edge.to_node.kind != &'action':
			continue

		if absf(_cx(edge.from_node) - _cx(edge.to_node)) > 0.5:
			misaligned += 1

	assert_int(misaligned).is_equal(graph.lanes.size())


func test_sibling_runs_take_distinct_depths() -> void:
	var wires: HenFlowWires = auto_free(HenFlowWires.new())

	assert_float(wires._band_between(0.0, 100.0, 0)).is_equal_approx(14.0, 0.01)
	assert_float(wires._band_between(0.0, 100.0, 1)).is_equal_approx(24.0, 0.01)
	assert_float(wires._band_between(0.0, 100.0, 2)).is_equal_approx(34.0, 0.01)
	assert_float(wires._band_between(0.0, 30.0, 2)).is_equal_approx(16.0, 0.01)


func test_siblings_on_one_band_sink_a_single_step() -> void:
	var wires: HenFlowWires = auto_free(HenFlowWires.new())

	wires._bands = PackedFloat32Array([50.0])

	assert_float(wires._band_between(0.0, 100.0, 0)).is_equal_approx(50.0, 0.01)
	assert_float(wires._band_between(0.0, 100.0, 1)).is_equal_approx(60.0, 0.01)
	assert_float(wires._band_between(0.0, 100.0, 3)).is_equal_approx(60.0, 0.01)
	assert_float(wires._band_between(0.0, 55.0, 1)).is_equal_approx(50.0, 0.01)


func test_a_short_hop_zigzags_through_its_own_gap() -> void:
	var wires: HenFlowWires = auto_free(HenFlowWires.new())
	var path: PackedVector2Array = wires._exec_path(Vector2(0.0, 0.0), Vector2(80.0, 20.0))

	assert_int(path.size()).is_equal(4)
	assert_vector(path[3]).is_equal(Vector2(80.0, 20.0))

	for point: Vector2 in path:
		assert_bool(point.x <= 80.0 and point.y <= 20.0).is_true()


func test_the_body_anchor_rides_the_first_nested_action() -> void:
	var host: Control = auto_free(Control.new())

	add_child(host)

	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphTypes.FlowGraph.new()
	var loop: HenFlowGraphTypes.FlowNode = _action(graph, 'loop', Vector2(300, 100))
	var inner: HenFlowGraphTypes.FlowNode = _action(graph, 'inner', Vector2(150, 70))

	loop.add_pin(HenFlowGraphTypes.FlowPin.new(HenFlowGraphTypes.BODY_PIN, &'exec_out', 'Body'))
	loop.body.append(inner)

	var card: HenFlowNodeCard = HenFlowNodeCard.new()

	host.add_child(card)
	card.setup(host, loop)
	card.compute_size()

	loop.position = Vector2(100.0, 40.0)
	loop.size = loop.size + Vector2(0.0, 120.0)
	inner.position = loop.position + Vector2(60.0, loop.size.y - 100.0)

	card.apply_size(loop.size)

	var body: HenFlowGraphTypes.FlowPin = loop.pin(HenFlowGraphTypes.BODY_PIN)

	assert_float(body.rect.get_center().x) \
		.is_equal_approx(inner.position.x - loop.position.x + inner.size.x * 0.5, 0.5)


func test_a_wire_wears_its_cell_colour() -> void:
	var wires: HenFlowWires = auto_free(HenFlowWires.new())
	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphTypes.FlowGraph.new()
	var entry: HenFlowGraphTypes.FlowNode = _node(graph, 'entry', &'state_entry', Vector2(150, 70))
	var check: HenFlowGraphTypes.FlowNode = _action(graph, 'check', Vector2(200, 100))
	var target: HenFlowGraphTypes.FlowNode = _node(graph, 'target', &'transition', Vector2(150, 70))

	_cell(entry, &'enter', 'enter', 37.5)
	_cell(entry, &'update', 'update', 112.5)
	_cell(check, &'true', 'True', 50.0)
	_cell(check, &'false', 'False', 150.0)

	var enter_color: Color = wires._exec_color(_edge(entry, &'enter', target))
	var update_color: Color = wires._exec_color(_edge(entry, &'update', target))
	var true_color: Color = wires._exec_color(_edge(check, &'true', target))
	var false_color: Color = wires._exec_color(_edge(check, &'false', target))
	var then_color: Color = wires._exec_color(_edge(check, HenFlowGraphTypes.THEN_PIN, target))

	assert_that(then_color).is_equal(HenFlowWires.EXEC_COLOR)
	assert_that(enter_color).is_not_equal(update_color)
	assert_that(true_color).is_not_equal(false_color)
	assert_that(true_color).is_not_equal(HenFlowWires.EXEC_COLOR)


func test_a_run_keeps_the_colour_of_its_phase() -> void:
	var wires: HenFlowWires = auto_free(HenFlowWires.new())
	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphTypes.FlowGraph.new()
	var entry: HenFlowGraphTypes.FlowNode = _node(graph, 'entry', &'state_entry', Vector2(150, 70))
	var steer: HenFlowGraphTypes.FlowNode = _action(graph, 'steer', Vector2(200, 100))
	var move: HenFlowGraphTypes.FlowNode = _action(graph, 'move', Vector2(200, 100))

	_cell(entry, &'physics', 'physics', 75.0)
	_cell(steer, &'true', 'True', 50.0)
	_cell(move, HenFlowGraphTypes.BODY_PIN, 'Body', 100.0)
	steer.phase = &'physics'
	move.phase = &'physics'

	var entry_color: Color = wires._exec_color(_edge(entry, &'physics', steer))
	var then_color: Color = wires._exec_color(_edge(steer, HenFlowGraphTypes.THEN_PIN, move))
	var body_color: Color = wires._exec_color(_edge(move, HenFlowGraphTypes.BODY_PIN, steer))
	var true_color: Color = wires._exec_color(_edge(steer, &'true', move))

	assert_that(then_color).is_equal(entry_color)
	assert_that(body_color).is_equal(entry_color)
	assert_that(then_color).is_not_equal(HenFlowWires.EXEC_COLOR)
	assert_that(true_color).is_not_equal(entry_color)


func _edge(
	_from: HenFlowGraphTypes.FlowNode,
	_pin: StringName,
	_to: HenFlowGraphTypes.FlowNode
) -> HenFlowGraphTypes.FlowEdge:
	return HenFlowGraphTypes.FlowEdge.new(&'exec', _from, _pin, _to, HenFlowGraphTypes.ENTER_PIN)
