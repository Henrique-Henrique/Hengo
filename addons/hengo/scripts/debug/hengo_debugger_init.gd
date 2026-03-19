extends Node

func _init() -> void:
	# delete debugger on non debug builds
	if not OS.is_debug_build():
		queue_free()
	
	if EngineDebugger.is_active():
		EngineDebugger.register_message_capture('hengo', HengoDebugger._on_message_capture)