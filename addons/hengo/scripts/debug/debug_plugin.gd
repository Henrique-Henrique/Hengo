@tool
extends EditorDebuggerPlugin

const PREFIX = 'hengo'

# per-script chosen instance (script_id -> instance_id); drives state focus for
# every script, and flow focus for whichever script is active
var _targets_by_script: Dictionary = {}


func _init() -> void:
	EditorInterface.get_inspector().edited_object_changed.connect(_on_edited_object_changed)


func _on_edited_object_changed() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global or not global.SAVE_DATA:
		return
		
	var obj: Object = EditorInterface.get_inspector().get_edited_object()
	if obj and obj.get_class() == 'EditorDebuggerRemoteObjects':
		if obj.get('Constants/HENGO_DEBUG_SCRIPT_ID') == global.SAVE_DATA.identity.id:
			var active_sessions: Array = get_sessions()
			for session: EditorDebuggerSession in active_sessions:
				if session.is_active():
					var node_path = obj.get('Node/path')
					session.send_message('hengo:set_target', [node_path])
			return

	var fallback_sessions: Array = get_sessions()
	for session: EditorDebuggerSession in fallback_sessions:
		if session.is_active():
			session.send_message('hengo:set_target', [-1])


func _has_capture(prefix: String) -> bool:
	return prefix == PREFIX


# the game capture group strips 'hengo:' from the message, the editor side does not
func _capture(message: String, data: Array, _session_id: int) -> bool:
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')

	match message.trim_prefix(PREFIX + ':'):
		'nodes_list':
			if signal_bus and data.size() > 1:
				signal_bus.debug_nodes_listed.emit(String(data[0]), data[1] as Array)
		'state':
			if signal_bus and not data.is_empty():
				signal_bus.debug_state_changed.emit(StringName(data[0]), String(data[1]) if data.size() > 1 else '')
		'action':
			if signal_bus and not data.is_empty():
				signal_bus.debug_action_flow.emit(StringName(data[0]), String(data[1]) if data.size() > 1 else '')
		'state_transition':
			if signal_bus and data.size() > 2:
				signal_bus.debug_state_transition.emit(String(data[0]), String(data[1]), String(data[2]))
		# cnode-era traces without a listener, swallowed so an old build does not warn
		'flow', 'state_flow', 'value':
			pass
		_:
			return false

	return true


# asks every active session for the live nodes of EVERY open script
func send_list_nodes() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global:
		return

	for save_data: HenSaveData in global.OPEN_SCRIPTS:
		if not save_data or not save_data.identity:
			continue
		var script_id: String = String(save_data.identity.id)
		for session: EditorDebuggerSession in get_sessions():
			if session.is_active():
				session.send_message('hengo:list_nodes', [script_id])


# flow focus: a single instance (the active script's chosen one)
func set_target(_instance_id: int) -> void:
	for session: EditorDebuggerSession in get_sessions():
		if session.is_active():
			session.send_message('hengo:set_target', [_instance_id])


# state focus: chosen instance for a given script (its machine highlights it)
func set_state_target(_script_id: String, _instance_id: int) -> void:
	_targets_by_script[_script_id] = _instance_id
	_send_state_targets()


func _send_state_targets() -> void:
	for session: EditorDebuggerSession in get_sessions():
		if session.is_active():
			session.send_message('hengo:set_state_targets', [_targets_by_script])


# flow focus follows the active script's chosen instance (called on script switch)
func on_active_script_changed(_script_id: String) -> void:
	set_target(int(_targets_by_script.get(_script_id, -1)))


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


func _setup_session(_session_id: int) -> void:
	var session: EditorDebuggerSession = get_session(_session_id)

	session.started.connect(_on_started)
	session.stopped.connect(_on_stopped)


func _on_started() -> void:
	(Engine.get_singleton(&'Global') as HenGlobal).HENGO_DEBUGGER_PLUGIN = self

	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	if signal_bus:
		signal_bus.debug_session_started.emit()

	send_list_nodes()


func _on_stopped() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	global.HENGO_DEBUGGER_PLUGIN = null

	_targets_by_script.clear()

	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	if signal_bus:
		signal_bus.debug_state_changed.emit(&'', '')
		signal_bus.debug_session_stopped.emit()