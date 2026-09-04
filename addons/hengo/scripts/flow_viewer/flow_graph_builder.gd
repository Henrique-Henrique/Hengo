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


# a use of a macro reads as what it hands the definition and what it fills in: the
# values, the places the macro left for it, its own phases and the ways out
static func build_macro_use(_save_data: HenSaveData, _use: HenSaveState) -> HenFlowGraphTypes.FlowGraph:
	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphTypes.FlowGraph.new()

	graph.state_id = StringName(str(_use.id))

	var macro: HenSaveStateMacro = _use.get_macro(_save_data)
	var entry: HenFlowGraphTypes.FlowNode = _entry_node(_use)

	graph.entry = entry
	graph.add_node(entry)

	if not macro:
		return graph

	for param: HenSaveParam in _use.macro_inputs:
		var pin: HenFlowGraphTypes.FlowPin = HenFlowGraphTypes.FlowPin.new(param.id, &'data_in', param.name)

		pin.part = _use_input_part(_save_data, _use, param)
		entry.add_pin(pin)

	# the places the macro left come first: they are what this use is here to fill
	for flow: HenSaveFlowParam in macro.flow_inputs:
		_use_chain(graph, _save_data, _use, entry, StringName(str(flow.id)), flow.name)

	for phase: StringName in HenSaveAction.PHASE_ORDER:
		_use_chain(graph, _save_data, _use, entry, phase, HenActionVisuals.phase_label(phase))

	for flow: HenSaveFlowParam in macro.flow_outputs:
		_use_way_out(graph, _save_data, _use, entry, flow)

	return graph


# one port of a use plus whatever it holds, the way a phase of a state works
static func _use_chain(
	_graph: HenFlowGraphTypes.FlowGraph,
	_save_data: HenSaveData,
	_use: HenSaveState,
	_entry: HenFlowGraphTypes.FlowNode,
	_id: StringName,
	_label: String
) -> void:
	var bucket: Array = HenGeneratorAction.hook_steps(_save_data, _use, _id)

	_entry.add_pin(HenFlowGraphTypes.FlowPin.new(_id, &'exec_out', _label))

	if bucket.is_empty():
		return

	_chain(_graph, _save_data, bucket, _entry, _id, _id, 0)
	_add_tail(_graph, bucket, _id)


# a way out is a port too: it carries the transition this use wired it to
static func _use_way_out(
	_graph: HenFlowGraphTypes.FlowGraph,
	_save_data: HenSaveData,
	_use: HenSaveState,
	_entry: HenFlowGraphTypes.FlowNode,
	_flow: HenSaveFlowParam
) -> void:
	var pin_id: StringName = StringName(HenFlowGraphTypes.WAY_OUT_PIN + str(_flow.id))

	_entry.add_pin(HenFlowGraphTypes.FlowPin.new(pin_id, &'exec_out', _flow.name))

	var target_id: String = str((_use.flow_targets.get(str(_flow.id), {}) as Dictionary).get('state_id', ''))
	var target: HenSaveState = HenGeneratorAction.find_state(_save_data, StringName(target_id))

	if not target:
		return

	var node: HenFlowGraphTypes.FlowNode = HenFlowGraphTypes.FlowNode.new()

	node.id = StringName('w' + str(_use.id) + ':' + str(_flow.id))
	node.kind = &'transition'
	node.title = target.name
	node.icon = 'arrow-right-to-line'
	node.accent = HenActionVisuals.PHASE_COLORS.get('update', HenActionVisuals.FALLBACK_COLOR)
	node.phase = pin_id

	node.add_pin(HenFlowGraphTypes.FlowPin.new(HenFlowGraphTypes.ENTER_PIN, &'exec_in'))

	_graph.add_node(node)
	_graph.connect_pins(&'exec', _entry, pin_id, node, HenFlowGraphTypes.ENTER_PIN)


# the value a use hands one input, drawn as the chip an action slot draws
static func _use_input_part(_save_data: HenSaveData, _use: HenSaveState, _param: HenSaveParam) -> Dictionary:
	var bind: String = str(_use.macro_bindings.get(str(_param.id), ''))
	var part: Dictionary = {}

	if not bind.is_empty():
		part = {kind = &'variable', value = HenUtils.get_bind_label(_save_data, bind)}
	elif _param.default_value is Color:
		part = {kind = &'literal', value = HenActionsPanel.format_value(_param.default_value), swatch = _param.default_value}
	else:
		part = {kind = &'literal', value = HenActionsPanel.format_value(_param.default_value)}

	part.label = _param.name
	part.options = _param.options
	part.picker = _param.picker
	part.slot = {
		param = _param,
		type = str(_param.type),
		bind_store = _use.macro_bindings,
		bind_key = str(_param.id),
		macro_params = {}
	}
	part.editor = HenActionsPanel.editor_kind(part, _param.lvalue or _param.bind_only)

	return part


# a function body is one run from top to bottom: it has no lifecycle phases, so
# the entry carries a single port and every step hangs from it
static func build_function(_save_data: HenSaveData, _scope: HenSaveState) -> HenFlowGraphTypes.FlowGraph:
	var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphTypes.FlowGraph.new()

	if not _save_data or not _scope:
		return graph

	graph.state_id = StringName(str(_scope.id))

	var actions: Array = _save_data.get_state_actions(graph.state_id)
	var entry: HenFlowGraphTypes.FlowNode = _entry_node(_scope)

	graph.entry = entry
	graph.add_node(entry)
	entry.add_pin(HenFlowGraphTypes.FlowPin.new(&'update', &'exec_out', 'Run'))

	if not actions.is_empty():
		_chain(graph, _save_data, actions, entry, &'update', &'update', 0)
		_add_tail(graph, actions, &'update')

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

	# a definition of the script can be renamed and retyped with its actions on
	# screen, so the slots follow it here instead of waiting for a reload
	HenSaveAction.sync_action_inputs(_action, macro)

	node.id = StringName('a' + str(_action.id))
	node.kind = _kind
	node.action = _action
	node.title = HenActionsPanel.display_name(_action)
	node.icon = macro.icon if macro else ''
	node.accent = HenActionVisuals.accent_of(macro).to_html(false)
	node.phase = _phase
	node.depth = _depth
	node.enter_scope = _scope_of(_action)

	_graph.add_node(node)

	node.add_pin(HenFlowGraphTypes.FlowPin.new(HenFlowGraphTypes.ENTER_PIN, &'exec_in'))

	_add_input_pins(_graph, _save_data, _action, node, _depth)

	if macro:
		for output: HenSaveParam in macro.outputs:
			node.add_pin(HenFlowGraphTypes.FlowPin.new(output.id, &'data_out', output.name))

	# a producer is pulled in by a wire, so it carries neither the sequence nor the
	# branches: the inline copy is only ever asked for its value
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


# the definition a step stands for, so the header can offer a way into it
static func _scope_of(_action: HenSaveAction) -> Dictionary:
	if HenFunctionMacro.is_function_macro(_action.macro_id) and not HenFunctionMacro.is_return_macro(_action.macro_id):
		return {kind = HenRoute.KIND_FUNCTION, id = HenFunctionMacro.function_id_of(_action.macro_id)}

	return {}


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

		var exit_name: String = _macro_exit_name(_save_data, _action, str(flow.id))
		var target: HenSaveState = HenGeneratorAction.branch_target(_save_data, _action, str(flow.id))

		# inside a macro the branch leaves through a named way out, and where that
		# lands is answered by each use of it, never here
		if not target and exit_name.is_empty():
			continue

		var transition: HenFlowGraphTypes.FlowNode = HenFlowGraphTypes.FlowNode.new()

		transition.id = StringName('t' + str(_action.id) + ':' + str(flow.id))
		transition.kind = &'transition'
		transition.title = exit_name if target == null else target.name
		transition.icon = 'door-open' if target == null else 'arrow-right-to-line'
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


# what a branch that leaves the macro is called, empty when it goes to a state
static func _macro_exit_name(_save_data: HenSaveData, _action: HenSaveAction, _key: String) -> String:
	if not HenGeneratorAction.branch_is_macro_exit(_action, _key):
		return ''

	var exit_id: String = str((_action.branches[_key] as Dictionary).get('exit_id', ''))
	var macro: HenSaveStateMacro = HenRoute.definition_of(_save_data, HenActionsPanel.state_id_of(_save_data, _action)) as HenSaveStateMacro
	var flow: HenSaveFlowParam = macro.find_flow_input(StringName(exit_id)) if macro else null

	if flow:
		return flow.name

	for way: HenSaveFlowParam in (macro.flow_outputs if macro else [] as Array[HenSaveFlowParam]):
		if str(way.id) == exit_id:
			return way.name

	return 'branch'


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
