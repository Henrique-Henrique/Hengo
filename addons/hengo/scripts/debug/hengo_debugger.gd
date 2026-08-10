class_name HengoDebugger extends Node

# flow/value focus: a single instance (the active script's chosen one)
static var target_instance_id: int = -1

# state focus: one instance per script (script_id -> instance_id), so every open
# script's state machine can highlight at once
static var state_targets: Dictionary = {}

# shorter than the highlights it feeds (200ms on a row, 800ms on an edge), so a
# running trace never goes dark between sends
const TRACE_INTERVAL_MS: int = 120

# trace key -> last send, msec
static var _traced_at: Dictionary = {}


static func _on_message_capture(message: String, data: Array) -> bool:
	if message == 'set_target':
		var target = data[0]
		if target is String or target is NodePath:
			var tree: SceneTree = Engine.get_main_loop() as SceneTree
			if tree:
				var node = tree.root.get_node_or_null(target)
				if node:
					target_instance_id = node.get_instance_id()
				else:
					target_instance_id = -1
		elif target is int or target is float:
			target_instance_id = int(target)
		else:
			target_instance_id = -1
		return true
	if message == 'set_state_targets':
		state_targets = data[0] if data[0] is Dictionary else {}
		_emit_current_states()
		return true
	if message == 'list_nodes':
		EngineDebugger.send_message('hengo:nodes_list', [String(data[0]), _collect_nodes_for_script(String(data[0]))])
		return true
	return false


# asks each targeted instance to re-emit its current state, so newly-chosen
# targets light up immediately instead of waiting for the next transition
static func _emit_current_states() -> void:
	for sid in state_targets:
		var inst: Object = instance_from_id(int(state_targets[sid]))
		if is_instance_valid(inst):
			var ctrl = inst.get('_STATE_CONTROLLER')
			if ctrl:
				ctrl.debug_emit_current()


# reads the HENGO_DEBUG_SCRIPT_ID const off a node's script (empty if absent)
static func resolve_script_id(node: Object) -> String:
	if not node:
		return ''
	var scr: Script = node.get_script()
	if scr is GDScript:
		return String((scr as GDScript).get_script_constant_map().get('HENGO_DEBUG_SCRIPT_ID', ''))
	return ''


# walks the live scene tree collecting nodes whose script declares HENGO_DEBUG_SCRIPT_ID == script_id
static func _collect_nodes_for_script(script_id: String) -> Array:
	var result: Array = []
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if not tree or not tree.root:
		return result

	var stack: Array = [tree.root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.push_back(child)

		var scr: Script = node.get_script()
		if scr is GDScript:
			var sid = (scr as GDScript).get_script_constant_map().get('HENGO_DEBUG_SCRIPT_ID', null)
			if sid != null and String(sid) == script_id:
				result.append({
					name = String(node.name),
					path = String(tree.root.get_path_to(node)),
					id = node.get_instance_id(),
				})
	return result


static func trace_flow(node_id: int, port: StringName = &'0', data: Dictionary = {}) -> void:
	if not OS.is_debug_build():
		return
	if not EngineDebugger.is_active():
		return
	if not _should_trace('f%d:%s' % [node_id, port]):
		return

	EngineDebugger.send_message('hengo:flow', [node_id, port, data])


# state transitions report per-script (gated by state_targets), so every open
# machine can flash edges at once regardless of the single flow focus
static func trace_state_flow(node_id: int, port: StringName, script_id: String) -> void:
	if not OS.is_debug_build():
		return
	if not EngineDebugger.is_active():
		return
	if not _should_trace('s%s:%d:%s' % [script_id, node_id, port]):
		return

	EngineDebugger.send_message('hengo:state_flow', [node_id, port, script_id])


static func trace_value(node_id: int, value: Variant) -> void:
	if not OS.is_debug_build():
		return
	if not EngineDebugger.is_active():
		return

	EngineDebugger.send_message('hengo:value', [node_id, value])


static func trace_state(state_name: StringName) -> void:
	if not OS.is_debug_build():
		return
	if not EngineDebugger.is_active():
		return

	EngineDebugger.send_message('hengo:state', [state_name])


# script_id defaults so a build generated before it existed still parses.
# an update action calls this every frame, and one message per action per frame
# overruns network/limits/debugger/max_queued_messages, which drops the rest of
# the trace: re-arming the highlight faster than it fades buys nothing
static func trace_action(action_id: StringName, script_id: String = '') -> void:
	if not OS.is_debug_build():
		return
	if not EngineDebugger.is_active():
		return

	if not _should_trace('a%s:%s' % [script_id, action_id]):
		return

	EngineDebugger.send_message('hengo:action', [action_id, script_id])


# true at most once per interval per key; the highlight it feeds outlives that,
# so nothing goes dark and the debugger queue stops overflowing
static func _should_trace(key: String) -> bool:
	var now: int = Time.get_ticks_msec()

	if now - int(_traced_at.get(key, -TRACE_INTERVAL_MS)) < TRACE_INTERVAL_MS:
		return false

	_traced_at[key] = now

	return true


# a branch action took a transition, so the state viewer can flash its edge (the
# cnode path does this via trace_state_flow; actions carry source+event directly)
static func trace_state_transition(source: String, event: String, script_id: String) -> void:
	if not OS.is_debug_build():
		return
	if not EngineDebugger.is_active():
		return

	EngineDebugger.send_message('hengo:state_transition', [source, event, script_id])
