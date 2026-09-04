@tool
class_name HenFlowGraphTypes
extends RefCounted

# the graph a state's action list draws as. nothing here is stored: it is derived
# from the actions every time, the same way the state viewer derives its edges

# the synthetic port every action carries: codegen runs the next action after this
# one no matter which declared branch was taken, so the sequence is its own port
const THEN_PIN: StringName = &'then'
# a port of a use that stands for a way out of its macro, told apart from the
# places the use fills with steps
const WAY_OUT_PIN: String = 'way:'
const ENTER_PIN: StringName = &'in'
const BODY_PIN: StringName = &'body'


class FlowPin extends RefCounted:
	var id: StringName
	# exec_in, exec_out, data_in or data_out
	var kind: StringName
	var label: String
	# the value_parts entry a data_in draws as a chip; empty when a wire feeds it
	var part: Dictionary = {}
	# how many steps read this data_out through a wire, which is what the badge counts
	var wires: int = 0
	# true on a data_in a wire feeds, which is what makes it a drop target
	var wired: bool = false
	# filled by the renderer, read by the wire router
	var rect: Rect2


	func _init(_id: StringName, _kind: StringName, _label: String = '') -> void:
		id = _id
		kind = _kind
		label = _label


class FlowNode extends RefCounted:
	var id: StringName
	# state_entry, action, producer or transition
	var kind: StringName
	var title: String
	var icon: String
	var accent: String
	# null on a state_entry, a transition and an add tail
	var action: HenSaveAction
	# stands for a step of an action list, which an inline producer never does
	var step: bool = false
	# on a body add tail, the loop action a new step is nested into
	var body_parent: HenSaveAction
	# on a branch add tail, which branch of body_parent the step lands on
	var body_branch: StringName = &''
	# on a wire_ref, the step and the slot the wire feeds, which unwiring clears
	var wire_owner: HenSaveAction
	var wire_input: StringName = &''
	# on a wire_ref, the step the value comes from, which clicking it goes to
	var wire_source: HenSaveAction
	# { kind, id } of the definition this step stands for, empty when it is a plain
	# action: it is what the enter button on the header opens
	var enter_scope: Dictionary = {}
	# the phase chain this node belongs to
	var phase: StringName = &''
	# why the codegen would drop this action, empty when it is fine
	var error: String = ''
	# the loop depth the emit path runs this action at, which the error check needs
	var depth: int = 0
	var pins: Array[FlowPin] = []
	# a loop macro's nested chain, laid out inside this node
	var body: Array[FlowNode] = []
	# height the branch row takes at the bottom, so the body is not laid over it
	var flow_row_h: float = 0.0
	var position: Vector2
	var size: Vector2


	func add_pin(_pin: FlowPin) -> FlowPin:
		pins.append(_pin)

		return _pin


	func pin(_id: StringName) -> FlowPin:
		for p: FlowPin in pins:
			if p.id == _id:
				return p

		return null


	func pins_of(_kind: StringName) -> Array[FlowPin]:
		var out: Array[FlowPin] = []

		for p: FlowPin in pins:
			if p.kind == _kind:
				out.append(p)

		return out


class FlowEdge extends RefCounted:
	# exec or data
	var kind: StringName
	var from_node: FlowNode
	var from_pin: StringName
	var to_node: FlowNode
	var to_pin: StringName


	func _init(_kind: StringName, _from: FlowNode, _from_pin: StringName, _to: FlowNode, _to_pin: StringName) -> void:
		kind = _kind
		from_node = _from
		from_pin = _from_pin
		to_node = _to
		to_pin = _to_pin


class FlowGraph extends RefCounted:
	var state_id: StringName
	var entry: FlowNode
	var nodes: Array[FlowNode] = []
	var edges: Array[FlowEdge] = []
	# the free lanes the formatter left between the columns of a wrapped run:
	# {x, exit_y, entry_y}. a wire jumping columns has nowhere else to go
	var lanes: Array[Dictionary] = []
	# the free strip under each step of a run. a step is wider than its action, so
	# turning right under the action still cuts whatever hangs beside it
	var bands: PackedFloat32Array = PackedFloat32Array()


	# moving the nodes without the lanes leaves every route aimed at where the
	# graph used to be, so the whole layout travels together or not at all
	func translate(_offset: Vector2) -> void:
		for node: FlowNode in nodes:
			node.position += _offset

		for lane: Dictionary in lanes:
			lane.x += _offset.x
			lane.exit_y += _offset.y
			lane.entry_y += _offset.y

		for i: int in range(bands.size()):
			bands[i] += _offset.y


	func add_node(_node: FlowNode) -> FlowNode:
		nodes.append(_node)

		return _node


	func connect_pins(_kind: StringName, _from: FlowNode, _from_pin: StringName, _to: FlowNode, _to_pin: StringName) -> void:
		edges.append(FlowEdge.new(_kind, _from, _from_pin, _to, _to_pin))


	func nodes_of(_kind: StringName) -> Array[FlowNode]:
		var out: Array[FlowNode] = []

		for node: FlowNode in nodes:
			if node.kind == _kind:
				out.append(node)

		return out


	func edges_of(_kind: StringName) -> Array[FlowEdge]:
		var out: Array[FlowEdge] = []

		for edge: FlowEdge in edges:
			if edge.kind == _kind:
				out.append(edge)

		return out
