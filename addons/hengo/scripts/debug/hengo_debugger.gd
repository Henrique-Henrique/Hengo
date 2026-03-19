class_name HengoDebugger extends Node

static var target_instance_id: int = -1


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
	return false


static func trace_flow(node_id: int, port: StringName = &'0', data: Dictionary = {}) -> void:
	if not OS.is_debug_build():
		return
	if not EngineDebugger.is_active():
		return

	EngineDebugger.send_message('hengo:flow', [node_id, port, data])


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
