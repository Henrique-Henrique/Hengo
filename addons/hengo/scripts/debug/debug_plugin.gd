@tool
extends EditorDebuggerPlugin

const PREFIX = 'hengo'

func _has_capture(prefix) -> bool:
	return prefix == PREFIX

func _capture(message, data, session_id) -> bool:
	match message:
		'hengo:cnode':
			for num: int in get_debug_ids(data[0]):
				var id_str: String = str(num)

				if HenGlobal.current_script_debug_symbols.has(id_str):
					var symbol_data: Array = HenGlobal.current_script_debug_symbols[id_str]
					var hash_number: int = symbol_data[0]
					var flow: String = symbol_data[1]

					if not HenGlobal.node_references.has(hash_number):
						continue

					var node_data: Dictionary = HenGlobal.node_references[hash_number]
					var flow_name: String = flow if flow else 'cnode'

					if node_data.has('base_conn'):
						for connection_line in node_data['base_conn']:
							connection_line.show_debug()

					if node_data.has(flow_name):
						var result: Array = node_data[flow_name]

						# all flow conn
						for flow_line in result[0]:
							flow_line.show_debug()
						
						# all connections
						for connection_line in result[1]:
							connection_line.show_debug()

			return true
		'hengo:debugger_loaded':
			# get_session(session_id).send_message('hengo:start_script', [HenGlobal.current_script_path, HenGlobal.DEBUG_TOKEN])
			return true
		'hengo:debug_value':
			var id_str: String = str(data[0])

			if HenGlobal.current_script_debug_symbols.has(id_str):
				var symbol_data: Array = HenGlobal.current_script_debug_symbols[id_str]
				var hash_number: int = symbol_data[0]

				if not HenGlobal.node_references.has(hash_number):
					return true
				
				var node_data: Dictionary = HenGlobal.node_references[hash_number]
				var cnode = node_data['cnode'][2]
				
				cnode.show_debug_value(str_to_var(data[1]))

			return true
		'hengo:debug_state':
			var id_str: String = str(data[0])

			if HenGlobal.current_script_debug_symbols.has(id_str):
				var symbol_data: Array = HenGlobal.current_script_debug_symbols[id_str]
				var hash_number: int = symbol_data[0]

				if not HenGlobal.state_references.has(hash_number):
					return true

				HenGlobal.state_references[hash_number].show_debug()
			
			return true

	return false


func reload_script() -> void:
	load_references()

	for session in get_sessions():
		session.send_message('hengo:reload_script', [HenGlobal.current_script_path, HenGlobal.DEBUG_TOKEN])


func get_debug_ids(_num: int) -> Array:
	var powers: Array = []
	var power: int = 1

	while (_num > 0):
		if _num & 1:
			powers.append(power)

		power *= 2
		_num >>= 1

	powers.reverse()
	
	return powers


func _setup_session(session_id):
	var session = get_session(session_id)

	# Listens to the session started and stopped signals.
	session.started.connect(_on_started)
	session.stopped.connect(_on_stopped)


func load_references() -> void:
	pass


func _on_started() -> void:
	load_references()
	HenGlobal.HENGO_DEBUGGER_PLUGIN = self

	print('Hengo Debugger Started!')


func _on_stopped() -> void:
	HenGlobal.node_references = {}
	HenGlobal.HENGO_DEBUGGER_PLUGIN = null

	print('Hengo Debugger Stopped!')