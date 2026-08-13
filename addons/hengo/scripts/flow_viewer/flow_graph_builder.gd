@tool
class_name HenFlowGraphBuilder
extends RefCounted

# turns a state's action list into the node graph the flow view draws. it reads
# the same data the codegen reads and stores nothing, so the picture cannot drift
# from what the script actually does


static func build(_save_data: HenSaveData, _state: HenSaveState) -> HenFlowGraphTypes.FlowGraph:
	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphTypes.FlowGraph.new()

	if not _save_data or not _state:
		return graph

	graph.state_id = StringName(str(_state.id))

	var actions: Array = _save_data.get_state_actions(graph.state_id)
	var groups: Dictionary = HenActionsPanel.group_by_phase(actions)
	var entry: HenFlowGraphTypes.FlowNode = _entry_node(_state)

	graph.entry = entry
	graph.add_node(entry)

	# phase order is run order, and a phase with no action gets no port at all
	for phase: StringName in HenSaveAction.PHASE_ORDER:
		var bucket: Array = groups.get(str(phase), [])

		if bucket.is_empty():
			continue

		entry.add_pin(HenFlowGraphTypes.FlowPin.new(phase, &'exec_out', str(phase)))
		_chain(graph, _save_data, bucket, entry, phase)
		_add_tail(graph, bucket, phase)

	# a state with no action at all still needs somewhere to put the first one
	if graph.nodes.size() == 1:
		entry.add_pin(HenFlowGraphTypes.FlowPin.new(&'update', &'exec_out', 'update'))
		_add_tail(graph, [], &'update')

	return graph


# the end of a phase chain is where a new step lands, and the graph is the only
# place that knows where that is
static func _add_tail(_graph: HenFlowGraphTypes.FlowGraph, _bucket: Array, _phase: StringName) -> void:
	var node: HenFlowGraphTypes.FlowNode = HenFlowGraphTypes.FlowNode.new()

	node.id = StringName('add_' + str(_phase))
	node.kind = &'add'
	node.title = 'Add action'
	node.accent = HenActionVisuals.FALLBACK_COLOR
	node.phase = _phase

	node.add_pin(HenFlowGraphTypes.FlowPin.new(HenFlowGraphTypes.ENTER_PIN, &'exec_in'))

	_graph.add_node(node)

	var last: Variant = _bucket.back() if not _bucket.is_empty() else null

	if last:
		_graph.connect_pins(&'exec', _graph.nodes[_index_of(_graph, StringName('a' + str(last.id)))], HenFlowGraphTypes.THEN_PIN, node, HenFlowGraphTypes.ENTER_PIN)
	else:
		_graph.connect_pins(&'exec', _graph.entry, _phase, node, HenFlowGraphTypes.ENTER_PIN)


# walks one action list in order, wiring each action's `then` into the next
static func _chain(
	_graph: HenFlowGraphTypes.FlowGraph,
	_save_data: HenSaveData,
	_actions: Array,
	_from: HenFlowGraphTypes.FlowNode,
	_from_pin: StringName
) -> void:
	var previous: HenFlowGraphTypes.FlowNode = _from
	var previous_pin: StringName = _from_pin

	for action: HenSaveAction in _actions:
		var node: HenFlowGraphTypes.FlowNode = _action_node(_graph, _save_data, action, &'action')

		_graph.connect_pins(&'exec', previous, previous_pin, node, HenFlowGraphTypes.ENTER_PIN)

		previous = node
		previous_pin = HenFlowGraphTypes.THEN_PIN


static func _entry_node(_state: HenSaveState) -> HenFlowGraphTypes.FlowNode:
	var node: HenFlowGraphTypes.FlowNode = HenFlowGraphTypes.FlowNode.new()

	node.id = StringName('s' + str(_state.id))
	node.kind = &'state_entry'
	node.title = _state.name
	node.icon = 'circle-play'
	node.accent = HenActionVisuals.FALLBACK_COLOR

	return node


static func _action_node(
	_graph: HenFlowGraphTypes.FlowGraph,
	_save_data: HenSaveData,
	_action: HenSaveAction,
	_kind: StringName
) -> HenFlowGraphTypes.FlowNode:
	var macro: HenSaveMacro = HenActionsPanel.find_macro(_action.macro_id)
	var node: HenFlowGraphTypes.FlowNode = HenFlowGraphTypes.FlowNode.new()

	node.id = StringName('a' + str(_action.id))
	node.kind = _kind
	node.action = _action
	node.title = macro.name if macro else _action.name
	node.icon = macro.icon if macro else ''
	node.accent = HenActionVisuals.accent_of(macro).to_html(false)

	_graph.add_node(node)

	node.add_pin(HenFlowGraphTypes.FlowPin.new(HenFlowGraphTypes.ENTER_PIN, &'exec_in'))

	_add_input_pins(_graph, _save_data, _action, node)

	if macro:
		for output: HenSaveParam in macro.outputs:
			node.add_pin(HenFlowGraphTypes.FlowPin.new(output.id, &'data_out', output.name))

	# a producer is pulled in by a wire, so it never carries the sequence
	if _kind != &'producer':
		node.add_pin(HenFlowGraphTypes.FlowPin.new(HenFlowGraphTypes.THEN_PIN, &'exec_out'))

	_add_branch_pins(_graph, _save_data, _action, macro, node)

	if macro and macro.has_body:
		node.add_pin(HenFlowGraphTypes.FlowPin.new(HenFlowGraphTypes.BODY_PIN, &'exec_out', 'Body'))
		_chain(_graph, _save_data, _action.body_actions, node, HenFlowGraphTypes.BODY_PIN)

		for child: HenSaveAction in _action.body_actions:
			node.body.append(_graph.nodes[_index_of(_graph, StringName('a' + str(child.id)))])

	return node


# one data pin per declared input; an input fed by another action gets a wire and
# the producer that feeds it, anything else keeps the chip it has in the row today
static func _add_input_pins(
	_graph: HenFlowGraphTypes.FlowGraph,
	_save_data: HenSaveData,
	_action: HenSaveAction,
	_node: HenFlowGraphTypes.FlowNode
) -> void:
	# value_parts lists the declared inputs first, in order, then outputs and branches
	var parts: Array = HenActionsPanel.value_parts(_action, _save_data)

	for i: int in range(_action.inputs.size()):
		var param: HenSaveParam = _action.inputs[i]
		var pin: HenFlowGraphTypes.FlowPin = HenFlowGraphTypes.FlowPin.new(param.id, &'data_in', param.name)
		var key: String = str(param.id)

		_node.add_pin(pin)

		if not _action.input_actions.has(key):
			if i < parts.size():
				pin.part = parts[i]
			continue

		var ref: Variant = _action.input_actions[key]
		var child: HenSaveAction = HenActionsPanel.inline_child(ref)

		if not child:
			continue

		var producer: HenFlowGraphTypes.FlowNode = _action_node(_graph, _save_data, child, &'producer')

		_graph.connect_pins(&'data', producer, _producer_output(ref, producer), _node, param.id)


# the chip text is baked into the pin when the graph is built, so an edit that
# leaves the graph alone still has to re-derive the parts before anything re-measures
static func refresh_parts(_save_data: HenSaveData, _node: HenFlowGraphTypes.FlowNode) -> void:
	if not _save_data or not _node or not _node.action:
		return

	var parts: Array = HenActionsPanel.value_parts(_node.action, _save_data)
	var pins: Array[HenFlowGraphTypes.FlowPin] = _node.pins_of(&'data_in')

	for i: int in range(mini(_node.action.inputs.size(), mini(parts.size(), pins.size()))):
		if _node.action.input_actions.has(str(_node.action.inputs[i].id)):
			continue

		pins[i].part = parts[i]


# the stored {action, output} names the port; older data stored the action alone
static func _producer_output(_ref: Variant, _producer: HenFlowGraphTypes.FlowNode) -> StringName:
	if _ref is Dictionary:
		var stored: StringName = StringName(str((_ref as Dictionary).get('output', '')))

		if not stored.is_empty():
			return stored

	var outputs: Array[HenFlowGraphTypes.FlowPin] = _producer.pins_of(&'data_out')

	return outputs[0].id if not outputs.is_empty() else &''


# a branch with a target leaves the state, so it gets its own node; one without a
# target is a `pass` in the emitted code and stays a bare port
static func _add_branch_pins(
	_graph: HenFlowGraphTypes.FlowGraph,
	_save_data: HenSaveData,
	_action: HenSaveAction,
	_macro: HenSaveMacro,
	_node: HenFlowGraphTypes.FlowNode
) -> void:
	if not _macro:
		return

	for flow: HenSaveFlowParam in _macro.flow_outputs:
		_node.add_pin(HenFlowGraphTypes.FlowPin.new(flow.id, &'exec_out', flow.name))

		var target: HenSaveState = HenGeneratorAction.branch_target(_save_data, _action, str(flow.id))

		if not target:
			continue

		var transition: HenFlowGraphTypes.FlowNode = HenFlowGraphTypes.FlowNode.new()

		transition.id = StringName('t' + str(_action.id) + ':' + str(flow.id))
		transition.kind = &'transition'
		transition.title = target.name
		transition.icon = 'arrow-right-to-line'
		transition.accent = HenActionVisuals.PHASE_COLORS.get('update', HenActionVisuals.FALLBACK_COLOR)

		transition.add_pin(HenFlowGraphTypes.FlowPin.new(HenFlowGraphTypes.ENTER_PIN, &'exec_in'))

		_graph.add_node(transition)
		_graph.connect_pins(&'exec', _node, flow.id, transition, HenFlowGraphTypes.ENTER_PIN)


static func _index_of(_graph: HenFlowGraphTypes.FlowGraph, _id: StringName) -> int:
	for i: int in range(_graph.nodes.size()):
		if _graph.nodes[i].id == _id:
			return i

	return 0
