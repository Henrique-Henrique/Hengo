@tool
extends EditorDebuggerPlugin

const PREFIX = 'hengo'

func _has_capture(prefix: String) -> bool:
	return prefix == PREFIX

func _capture(_message: String, _data: Array, _session_id: int) -> bool:
	match _message:
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
			
			return true
		'hengo:value':
			var id: int = _data[0]
			var value = _data[1]
			
			var vc: HenVirtualCNode = _get_vc_by_id(id)

			if vc and vc.cnode_instance:
				vc.cnode_instance.show_debug_value(value)

			return true

	return false


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

	# Listens to the session started and stopped signals.
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

	print('Hengo Debugger Started!')


func _on_stopped() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	global.HENGO_DEBUGGER_PLUGIN = null

	print('Hengo Debugger Stopped!')