extends Node

var old_source_code: String
var old_script_name: StringName

func _init() -> void:
	# deleting debugger on non debug builds
	if not OS.is_debug_build():
		queue_free()

	EngineDebugger.send_message('hengo:debugger_loaded', [])
	EngineDebugger.register_message_capture('hengo', _on_change_script)


func _on_change_script(_message: String, _data: Array = []) -> bool:
	match _message:
		'start_script':
			var script_name: StringName = _data[0]

			if script_name:
				var script: GDScript = load(script_name as String)

				old_script_name = script_name
				old_source_code = script.source_code

				script.source_code = script.source_code.replace(_data[1] as String, '')
				script.reload(true)
		'reload_script':
			var script_name: StringName = _data[0]

			if script_name:
				# old
				var old_script: GDScript = load(old_script_name as String)
				old_script.source_code = old_source_code
				old_script.reload(true)

				# new
				var script: GDScript = load(script_name as String)

				old_script_name = script_name
				old_source_code = script.source_code
				
				script.source_code = script.source_code.replace(_data[1] as String, '')

				script.reload(true)

	return true
