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
) -> void:
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
		var macro: HenSaveMacro = HenActionsPanel.find_macro(action.macro_id)
		var stored: bool = wants_store(action, macro)
		# an action that only produces a value leaves the sequence to its store; one
		# that also runs the flow keeps its place and the store follows it
		var pulled: bool = stored and is_pure_producer(macro)
		var node: HenFlowGraphTypes.FlowNode = _action_node(
			_graph, _save_data, action, &'producer' if pulled else &'action', _phase, _depth
		)

		# a pulled producer left the sequence to its store, but it is still the step
		# the list holds, so it stays a drag handle
		node.step = true

		if not pulled:
			_graph.connect_pins(&'exec', previous, previous_pin, node, HenFlowGraphTypes.ENTER_PIN)

			previous = node
			previous_pin = HenFlowGraphTypes.THEN_PIN
			links.append(node)

		if stored:
			var store: HenFlowGraphTypes.FlowNode = _store_node(_graph, _save_data, action, macro, node)

			store.step = true
			store.depth = _depth

			_graph.connect_pins(&'exec', previous, previous_pin, store, HenFlowGraphTypes.ENTER_PIN)

			previous = store
			previous_pin = HenFlowGraphTypes.THEN_PIN
			links.append(store)

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


# an action gets a store as soon as one of its results has somewhere to land
static func wants_store(_action: HenSaveAction, _macro: HenSaveMacro) -> bool:
	if not _macro or _macro.outputs.is_empty():
		return false

	for output: HenSaveParam in _macro.outputs:
		if not str(_action.output_bindings.get(str(output.id), '')).is_empty():
			return true

	return false


# an action whose whole job is to produce a value reads as a step of the sequence,
# which it is not: the store takes that place and pulls the action in as a source,
# the same shape an inline producer already has. one that branches or owns a body
# does run the sequence, so it stays where it is
static func is_pure_producer(_macro: HenSaveMacro) -> bool:
	return _macro != null and not _macro.has_body and _macro.flow_outputs.is_empty()


# where the results of an action land: one node per action, with a port per stored
# output, standing in the chain in place of the action that feeds it
static func _store_node(
	_graph: HenFlowGraphTypes.FlowGraph,
	_save_data: HenSaveData,
	_action: HenSaveAction,
	_macro: HenSaveMacro,
	_node: HenFlowGraphTypes.FlowNode
) -> HenFlowGraphTypes.FlowNode:
	var store: HenFlowGraphTypes.FlowNode = HenFlowGraphTypes.FlowNode.new()

	store.id = StringName('st' + str(_action.id))
	store.kind = &'store'
	store.action = _action
	store.title = 'Store In'
	store.icon = 'save'
	store.accent = str(HenActionCategories.get_data('variable').color)
	store.phase = _node.phase

	store.add_pin(HenFlowGraphTypes.FlowPin.new(HenFlowGraphTypes.ENTER_PIN, &'exec_in'))

	for part: Dictionary in HenActionsPanel.output_parts(_action, _macro, _save_data):
		var id: StringName = StringName(str(part.get('output_id', '')))
		var pin: HenFlowGraphTypes.FlowPin = HenFlowGraphTypes.FlowPin.new(id, &'data_in', str(part.get('output_name', '')))

		pin.part = part
		store.add_pin(pin)

	store.add_pin(HenFlowGraphTypes.FlowPin.new(HenFlowGraphTypes.THEN_PIN, &'exec_out'))

	_graph.add_node(store)

	for pin: HenFlowGraphTypes.FlowPin in store.pins_of(&'data_in'):
		_graph.connect_pins(&'data', _node, pin.id, store, pin.id)

	return store


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

		# with steps on the branch the transition is what the chain ends on, so it
		# reads in the order it runs
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
