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

	# every phase gets a port, used or not: the cell is what a step is added through,
	# so a step lands on the phase it belongs to instead of on update
	for phase: StringName in HenSaveAction.PHASE_ORDER:
		var bucket: Array = groups.get(str(phase), [])

		entry.add_pin(HenFlowGraphTypes.FlowPin.new(phase, &'exec_out', HenActionVisuals.phase_label(phase)))

		if bucket.is_empty():
			continue

		_chain(graph, _save_data, bucket, entry, phase, phase, 0)
		_add_tail(graph, bucket, phase)

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
	_graph.connect_pins(&'exec', _head_of(_graph, _bucket.back().id), HenFlowGraphTypes.THEN_PIN, node, HenFlowGraphTypes.ENTER_PIN)


# the end of a branch chain, the same affordance a body gets. it is wired after
# the last step, so a branch that only transitions never grows one
static func _branch_tail(
	_graph: HenFlowGraphTypes.FlowGraph,
	_action: HenSaveAction,
	_branch: StringName,
	_owner: HenFlowGraphTypes.FlowNode,
	_chain: Array[HenFlowGraphTypes.FlowNode]
) -> HenFlowGraphTypes.FlowNode:
	var node: HenFlowGraphTypes.FlowNode = HenFlowGraphTypes.FlowNode.new()

	node.id = StringName('addr' + str(_action.id) + ':' + str(_branch))
	node.kind = &'add'
	node.title = 'Add action'
	node.accent = HenActionVisuals.FALLBACK_COLOR
	node.phase = _owner.phase
	node.body_parent = _action
	node.body_branch = _branch

	node.add_pin(HenFlowGraphTypes.FlowPin.new(HenFlowGraphTypes.ENTER_PIN, &'exec_in'))

	_graph.add_node(node)

	if _chain.is_empty():
		_graph.connect_pins(&'exec', _owner, _branch, node, HenFlowGraphTypes.ENTER_PIN)
	else:
		_graph.connect_pins(&'exec', _chain.back(), HenFlowGraphTypes.THEN_PIN, node, HenFlowGraphTypes.ENTER_PIN)

	return node


# a body carries its own end the way a phase chain does: without it an empty body
# has nowhere to drop the first step and the card draws as if it had no body
static func _body_tail(
	_graph: HenFlowGraphTypes.FlowGraph,
	_action: HenSaveAction,
	_owner: HenFlowGraphTypes.FlowNode,
	_chain: Array[HenFlowGraphTypes.FlowNode],
	_phase: StringName
) -> HenFlowGraphTypes.FlowNode:
	var node: HenFlowGraphTypes.FlowNode = HenFlowGraphTypes.FlowNode.new()

	node.id = StringName('addb' + str(_action.id))
	node.kind = &'add'
	node.title = 'Add action'
	node.accent = HenActionVisuals.FALLBACK_COLOR
	node.phase = _phase
	node.body_parent = _action

	node.add_pin(HenFlowGraphTypes.FlowPin.new(HenFlowGraphTypes.ENTER_PIN, &'exec_in'))

	_graph.add_node(node)

	if _chain.is_empty():
		_graph.connect_pins(&'exec', _owner, HenFlowGraphTypes.BODY_PIN, node, HenFlowGraphTypes.ENTER_PIN)
	else:
		_graph.connect_pins(&'exec', _chain.back(), HenFlowGraphTypes.THEN_PIN, node, HenFlowGraphTypes.ENTER_PIN)

	return node


# walks one action list in order, wiring each action's `then` into the next
# returns the nodes that ended up carrying the sequence, in order: an action that
# left its place to a store is not one of them, the store is
static func _chain(
	_graph: HenFlowGraphTypes.FlowGraph,
	_save_data: HenSaveData,
	_actions: Array,
	_from: HenFlowGraphTypes.FlowNode,
	_from_pin: StringName,
	_phase: StringName,
	_depth: int
) -> Array[HenFlowGraphTypes.FlowNode]:
	var links: Array[HenFlowGraphTypes.FlowNode] = []
	var previous: HenFlowGraphTypes.FlowNode = _from
	var previous_pin: StringName = _from_pin

	for action: HenSaveAction in _actions:
		var node: HenFlowGraphTypes.FlowNode = _action_node(
			_graph, _save_data, action, &'action', _phase, _depth
		)

		node.step = true

		_graph.connect_pins(&'exec', previous, previous_pin, node, HenFlowGraphTypes.ENTER_PIN)

		previous = node
		previous_pin = HenFlowGraphTypes.THEN_PIN
		links.append(node)

	return links


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
	_kind: StringName,
	_phase: StringName,
	_depth: int
) -> HenFlowGraphTypes.FlowNode:
	var macro: HenSaveMacro = HenActionsPanel.find_macro(_action.macro_id)
	var node: HenFlowGraphTypes.FlowNode = HenFlowGraphTypes.FlowNode.new()

	node.id = StringName('a' + str(_action.id))
	node.kind = _kind
	node.action = _action
	node.title = macro.name if macro else _action.name
	node.icon = macro.icon if macro else ''
	node.accent = HenActionVisuals.accent_of(macro).to_html(false)
	node.phase = _phase
	node.depth = _depth

	_graph.add_node(node)

	node.add_pin(HenFlowGraphTypes.FlowPin.new(HenFlowGraphTypes.ENTER_PIN, &'exec_in'))

	_add_input_pins(_graph, _save_data, _action, node, _depth)

	if macro:
		for output: HenSaveParam in macro.outputs:
			node.add_pin(HenFlowGraphTypes.FlowPin.new(output.id, &'data_out', output.name))

	# a producer is pulled in by a wire, so it never carries the sequence
	if _kind != &'producer':
		node.add_pin(HenFlowGraphTypes.FlowPin.new(HenFlowGraphTypes.THEN_PIN, &'exec_out'))

	_add_branch_pins(_graph, _save_data, _action, macro, node, _depth)

	if macro and macro.has_body:
		node.add_pin(HenFlowGraphTypes.FlowPin.new(HenFlowGraphTypes.BODY_PIN, &'exec_out', 'Body'))

		# the body is the nodes that carry its sequence, which is not the same list
		# as its actions: a stored action hands that place to its store
		var chain: Array[HenFlowGraphTypes.FlowNode] = _chain(
			_graph, _save_data, _action.body_actions, node, HenFlowGraphTypes.BODY_PIN, _phase, _depth + 1
		)

		chain.append(_body_tail(_graph, _action, node, chain, _phase))
		node.body.assign(chain)

	return node


# one data pin per declared input; an input fed by another action gets a wire and
# the producer that feeds it, anything else keeps the chip it has in the row today
static func _add_input_pins(
	_graph: HenFlowGraphTypes.FlowGraph,
	_save_data: HenSaveData,
	_action: HenSaveAction,
	_node: HenFlowGraphTypes.FlowNode,
	_depth: int
) -> void:
	# value_parts lists the declared inputs first, in order, then outputs and branches
	var parts: Array = HenActionsPanel.value_parts(_action, _save_data)

	for i: int in range(_action.inputs.size()):
		var param: HenSaveParam = _action.inputs[i]
		var pin: HenFlowGraphTypes.FlowPin = HenFlowGraphTypes.FlowPin.new(param.id, &'data_in', param.name)
		var key: String = str(param.id)

		_node.add_pin(pin)

		if _action.input_wires.has(key):
			_connect_wire(_graph, _action.input_wires[key], _node, param.id)
			continue

		if not _action.input_actions.has(key):
			if i < parts.size():
				pin.part = parts[i]
			continue

		var ref: Variant = _action.input_actions[key]
		var child: HenSaveAction = HenActionsPanel.inline_child(ref)

		if not child:
			continue

		var producer: HenFlowGraphTypes.FlowNode = _action_node(
			_graph, _save_data, child, &'producer', _node.phase, _depth
		)

		_graph.connect_pins(&'data', producer, _producer_output(ref, producer), _node, param.id)


# a wire is an edge of its own kind, so the router leaves it undrawn and the card
# is free to show it as a chip and reveal the route only on demand
static func _connect_wire(
	_graph: HenFlowGraphTypes.FlowGraph,
	_wire: Variant,
	_node: HenFlowGraphTypes.FlowNode,
	_pin: StringName
) -> void:
	if not _wire is Dictionary:
		return

	var spec: Dictionary = _wire as Dictionary
	var producer: HenFlowGraphTypes.FlowNode = _node_of_action(_graph, StringName(str(spec.get('action_id', ''))))

	if not producer:
		return

	var output: StringName = StringName(str(spec.get('output', '')))
	var source: HenFlowGraphTypes.FlowPin = producer.pin(output)
	var reader: HenFlowGraphTypes.FlowPin = _node.pin(_pin)

	if source:
		source.wires += 1

	if reader:
		reader.wired = true

	# a reference draws where an inline producer would: the value has to be followed
	# by eye from the slot that uses it, which a mark on the slot never gives
	var proxy: HenFlowGraphTypes.FlowNode = HenFlowGraphTypes.FlowNode.new()

	proxy.id = StringName('w' + str(_node.id) + '_' + str(_pin))
	proxy.kind = &'wire_ref'
	# no action on purpose: it is a mirror of a step, so the menu, the two adds and
	# the inspector all belong to the card it points at. the wire edge is the link
	proxy.action = null
	# the value names it and the icon says which step made it, the way a transition
	# names the state and not the action that leaves for it
	proxy.title = source.label if source else str(output)
	proxy.icon = producer.icon
	proxy.accent = producer.accent
	proxy.phase = _node.phase
	proxy.depth = _node.depth
	proxy.wire_owner = _node.action
	proxy.wire_input = _pin
	proxy.wire_source = producer.action
	proxy.add_pin(HenFlowGraphTypes.FlowPin.new(output, &'data_out', source.label if source else str(output)))

	_graph.add_node(proxy)
	_graph.connect_pins(&'data', proxy, output, _node, _pin)
	_graph.connect_pins(&'wire', producer, output, proxy, output)


# a wire only ever points at a step that already ran, so its node is always built
static func _node_of_action(_graph: HenFlowGraphTypes.FlowGraph, _id: StringName) -> HenFlowGraphTypes.FlowNode:
	for node: HenFlowGraphTypes.FlowNode in _graph.nodes:
		if node.action and StringName(str(node.action.id)) == _id:
			return node

	return null


# the chip text is baked into the pin when the graph is built, so an edit that
# leaves the graph alone still has to re-derive the parts before anything re-measures
static func refresh_parts(_save_data: HenSaveData, _node: HenFlowGraphTypes.FlowNode) -> void:
	if not _save_data or not _node or not _node.action:
		return

	var parts: Array = HenActionsPanel.value_parts(_node.action, _save_data)
	var pins: Array[HenFlowGraphTypes.FlowPin] = _node.pins_of(&'data_in')

	for i: int in range(mini(_node.action.inputs.size(), mini(parts.size(), pins.size()))):
		var key: String = str(_node.action.inputs[i].id)

		if _node.action.input_actions.has(key) or _node.action.input_wires.has(key):
			continue

		pins[i].part = parts[i]


# the rebuild never asks this: a macro instance per action costs too much there
static func refresh_error(_save_data: HenSaveData, _state: HenSaveState, _node: HenFlowGraphTypes.FlowNode) -> bool:
	if not _node or not _node.action or not _node.step:
		return false

	var reason: String = HenGeneratorAction.action_error(_save_data, _state, _node.action, _node.phase, _node.depth)

	if reason == _node.error:
		return false

	_node.error = reason

	return true


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
	_node: HenFlowGraphTypes.FlowNode,
	_depth: int
) -> void:
	if not _macro:
		return

	for flow: HenSaveFlowParam in _macro.flow_outputs:
		_node.add_pin(HenFlowGraphTypes.FlowPin.new(flow.id, &'exec_out', flow.name))

		# a branch runs its own steps without leaving the state, so they hang off the
		# branch pin the way a transition card does
		var steps: Array = HenGeneratorAction.branch_steps(_action, str(flow.id))
		var chain: Array[HenFlowGraphTypes.FlowNode] = []

		if not steps.is_empty():
			chain = _chain(_graph, _save_data, steps, _node, flow.id, _node.phase, _depth)
			_branch_tail(_graph, _action, flow.id, _node, chain)

		var target: HenSaveState = HenGeneratorAction.branch_target(_save_data, _action, str(flow.id))

		if not target:
			continue

		var transition: HenFlowGraphTypes.FlowNode = HenFlowGraphTypes.FlowNode.new()

		transition.id = StringName('t' + str(_action.id) + ':' + str(flow.id))
		transition.kind = &'transition'
		transition.title = target.name
		transition.icon = 'arrow-right-to-line'
		transition.accent = HenActionVisuals.PHASE_COLORS.get('update', HenActionVisuals.FALLBACK_COLOR)
		transition.phase = _node.phase

		transition.add_pin(HenFlowGraphTypes.FlowPin.new(HenFlowGraphTypes.ENTER_PIN, &'exec_in'))

		_graph.add_node(transition)

		# a branch goes to a state or it runs steps, never both, so a transition only
		# ever hangs off the branch port itself
		if chain.is_empty():
			_graph.connect_pins(&'exec', _node, flow.id, transition, HenFlowGraphTypes.ENTER_PIN)
		else:
			_graph.connect_pins(&'exec', chain.back(), HenFlowGraphTypes.THEN_PIN, transition, HenFlowGraphTypes.ENTER_PIN)


# the node that carries an action in the sequence: its store when it has one,
# since a stored action hangs off that store instead of the chain
static func _head_of(_graph: HenFlowGraphTypes.FlowGraph, _action_id: Variant) -> HenFlowGraphTypes.FlowNode:
	var store_id: StringName = StringName('st' + str(_action_id))

	for node: HenFlowGraphTypes.FlowNode in _graph.nodes:
		if node.id == store_id:
			return node

	return _graph.nodes[_index_of(_graph, StringName('a' + str(_action_id)))]


static func _index_of(_graph: HenFlowGraphTypes.FlowGraph, _id: StringName) -> int:
	for i: int in range(_graph.nodes.size()):
		if _graph.nodes[i].id == _id:
			return i

	return 0
