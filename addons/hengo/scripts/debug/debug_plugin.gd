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


func _capture(_message: String, _data: Array, _session_id: int) -> bool:
	match _message:
		'hengo:state':
			var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
			if signal_bus:
				signal_bus.debug_state_changed.emit(StringName(_data[0]), String(_data[1]) if _data.size() > 1 else '')
			return true
		'hengo:flow':
			var id: int = _data[0]
			var port: StringName = _data[1]
			
			var vc: HenVirtualCNode = _get_vc_by_id(id)

			if vc:
				if vc.cnode_instance:
					vc.cnode_instance.show_debug_execution()
				
				var line: HenFlowConnectionLine = _get_flow_line(vc, port)
				if line:
					line.show_debug()
			
			var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
			if signal_bus:
				signal_bus.debug_flow_transition.emit(id, port)
			
			return true
		'hengo:state_flow':
			var id: int = _data[0]
			var port: StringName = _data[1]
			var script_id: String = String(_data[2]) if _data.size() > 2 else ''

			var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
			if signal_bus:
				signal_bus.debug_state_flow.emit(id, port, script_id)

			return true
		'hengo:value':
			var id: int = _data[0]
			var value = _data[1]
			
			var vc: HenVirtualCNode = _get_vc_by_id(id)

			if vc and vc.cnode_instance:
				vc.cnode_instance.show_debug_value(value)

			return true
		'hengo:nodes_list':
			var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
			if signal_bus:
				signal_bus.debug_nodes_listed.emit(String(_data[0]), _data[1])
			return true

	return false


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


func _get_vc_by_id(_id: int) -> HenVirtualCNode:
	var router: HenRouter = Engine.get_singleton("Router")
	if not router.current_route: return null
	
	for vc: HenVirtualCNode in router.current_route.virtual_cnode_list:
		if int(vc.id) == _id:
			return vc
	return null


func _get_flow_line(vc: HenVirtualCNode, port: StringName) -> HenFlowConnectionLine:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var flow_outputs: Array = vc.get_flow_outputs(global.SAVE_DATA)
	var target_idx: int = -1
	
	for i in range(flow_outputs.size()):
		var flow: HenVCFlow = flow_outputs[i]
		if flow.id == port:
			target_idx = i
			break
	
	if target_idx == -1: return null
	
	for line: HenFlowConnectionLine in global.flow_connection_line_pool:
		if line.is_visible_in_tree():
			var from_vc: HenVirtualCNode = line.from.get_ref()
			if from_vc == vc and line.from_idx == target_idx:
				return line
	return null


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