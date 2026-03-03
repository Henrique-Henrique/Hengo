extends Node


func _init() -> void:
	# delete debugger on non debug builds
	if not OS.is_debug_build():
		queue_free()


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
