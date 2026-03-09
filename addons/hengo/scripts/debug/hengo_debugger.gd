extends Node

var target_instance_id: int = -1


func _init() -> void:
	# delete debugger on non debug builds
	if not OS.is_debug_build():
		queue_free()
	
	if EngineDebugger.is_active():
		EngineDebugger.register_message_capture('hengo', _on_message_capture)


func _on_message_capture(message: String, data: Array) -> bool:
	if message == 'set_target':
		var target = data[0]
		if target is String or target is NodePath:
			var node = get_node_or_null(target)
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


func trace_flow(node_id: int, port: StringName = &"0", data: Dictionary = {}) -> void:
	if not OS.is_debug_build():
		return
	if not EngineDebugger.is_active():
		return

	EngineDebugger.send_message('hengo:flow', [node_id, port, data])


func trace_value(node_id: int, value: Variant) -> void:
	if not OS.is_debug_build():
		return
	if not EngineDebugger.is_active():
		return

	EngineDebugger.send_message('hengo:value', [node_id, value])


func trace_state(state_name: StringName) -> void:
	if not OS.is_debug_build():
		return
	if not EngineDebugger.is_active():
		return

	EngineDebugger.send_message('hengo:state', [state_name])
