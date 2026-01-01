class_name HenGeneratorBase extends RefCounted

const TEXT_BASE: String = """var _STATE_CONTROLLER = HengoStateController.new()

const _EVENTS = {events}

func _init() -> void:
	_STATE_CONTROLLER.set_states({
{states_dict}
	})

func _ready() -> void:
	if not _STATE_CONTROLLER.current_state:
		_STATE_CONTROLLER.change_state("{start_state_name}")
{_ready}
func trigger_event(_event: String) -> void:
	if _EVENTS.has(_event):
		_STATE_CONTROLLER.change_state(_EVENTS[_event])

func _process(delta: float) -> void:
	_STATE_CONTROLLER.static_process(delta)
{_process}
func _physics_process(delta: float) -> void:
	_STATE_CONTROLLER.static_physics_process(delta)
{_physics_process}
{states}"""


static func get_base_script_code(_save_data: HenSaveData, _refs: HenTypeReferences) -> String:
	var code: String = ''
	var start_state: HenVirtualCNode
	var events: Array[Dictionary] = []

	# getting states
	for _vc: HenVirtualCNode in _save_data.get_base_route().virtual_cnode_list:
		var flow_connections: Array = _save_data.get_outgoing_flow_connection_from_vc(_vc)

		match _vc.sub_type:
			# getting start state cnode
			HenVirtualCNode.SubType.STATE_START:
				if not flow_connections.is_empty():
					start_state = (flow_connections.get(0) as HenVCFlowConnectionData).get_to(_save_data)
			HenVirtualCNode.SubType.STATE:
				var transitions: Array = []

				# getting transition
				for flow_connection: HenVCFlowConnectionData in flow_connections:
					var state: HenSaveState = _vc.get_res(_save_data)

					if state:
						var to: HenVirtualCNode = flow_connection.get_to(_save_data)

						if to:
							var flow_list: Dictionary = {}
							var flow_output_id_list: Array = _vc.get_flow_outputs(_save_data).map(func(x: HenVCFlow):
								flow_list[x.id] = x
								return x.id)

							if flow_output_id_list.has(flow_connection.from_id):
								transitions.append({
									name = flow_list.get(flow_connection.from_id).name,
									to_state_name = to.get_vc_name(_save_data)
								})

				var state_res: HenSaveState = _vc.get_res(_save_data)

				if state_res:
					_refs.states_data[_vc.get_vc_name(_save_data).to_snake_case()] = {
						virtual_tokens = _parse_virtual_cnode(state_res.get_route(_save_data).virtual_sub_type_vc_list, _save_data),
						transitions = transitions
					}
			HenVirtualCNode.SubType.STATE_EVENT:
				if not flow_connections.is_empty() and (flow_connections.get(0) as HenVCFlowConnectionData).get_to(_save_data):
					events.append({
						name = _vc.name,
						to_state_name = (flow_connections.get(0) as HenVCFlowConnectionData).get_to(_save_data).name
					})
			HenVirtualCNode.SubType.OVERRIDE_VIRTUAL:
				if not flow_connections.is_empty() and (flow_connections.get(0) as HenVCFlowConnectionData).get_to(_save_data):
					if not _refs.override_virtual_data.has(_vc.name):
						_refs.override_virtual_data[_vc.name] = {
							params = HenVirtualCNodeCode.get_output_token_list(_save_data, _vc),
							tokens = []
						}

				(_refs.override_virtual_data[_vc.name].tokens as Array).append_array(HenVirtualCNodeCode.get_flow_tokens(_save_data, (flow_connections.get(0) as HenVCFlowConnectionData).get_to(_save_data), 0))

	code += map_all_macros(_save_data, _refs)

	var ready_code: Array = []
	var process_code: Array = []
	var physics_process_code: Array = []

	for key: StringName in _refs.override_virtual_data.keys():
		var item = _refs.override_virtual_data.get(key)

		match key:
			&'_ready':
				for token: Dictionary in item.tokens:
					var _code: String = HenGeneratorByToken.get_code_by_token(_save_data, token, 1)
					if _code: ready_code.append(_code)
			&'_process':
				for token: Dictionary in item.tokens:
					var _code: String = HenGeneratorByToken.get_code_by_token(_save_data, token, 1)
					if _code: process_code.append(_code)
			&'_physics_process':
				for token: Dictionary in item.tokens:
					var _code: String = HenGeneratorByToken.get_code_by_token(_save_data, token, 1)
					if _code: physics_process_code.append(_code)

	return code + TEXT_BASE.format({
		events = ' { \n\t' + ',\n\t'.join(events.map(
			func(ev: Dictionary) -> String:
			return '{event_name}="{to_state_name}"'.format({
				event_name = (ev.name as String).to_snake_case(),
				to_state_name = (ev.to_state_name as String).to_snake_case()
			})
			)) + '\n}' if not events.is_empty() else '{}',
		start_state_name = (start_state as HenVirtualCNode).get_vc_name(_save_data).to_snake_case() if start_state else '',
		_ready = ' \n'.join(ready_code),
		_process = '\n'.join(process_code),
		_physics_process = '\n'.join(physics_process_code),
		states_dict = HenGeneratorState.get_states_start_code(_refs),
		states = HenGeneratorState.get_states_code(_save_data, _refs)
	})


static func _parse_virtual_cnode(_cnode_list: Array, _save_data: HenSaveData) -> Dictionary:
	var data: Dictionary = {}

	for vc: HenVirtualCNode in _cnode_list:
		var flow_connections: Array = _save_data.get_flow_connection_from_vc(vc)
		if flow_connections.is_empty():
			continue
		
		var cnode_name: String = vc.name
		var from_flow: HenVCFlowConnectionData = flow_connections.get(0)
		var from_flow_to: HenVirtualCNode = from_flow.get_to(_save_data)

		if from_flow_to:
			var token_list = HenVirtualCNodeCode.get_flow_tokens(_save_data, from_flow_to, from_flow.to_id)

			data[cnode_name] = {
				tokens = token_list,
				params = HenVirtualCNodeCode.get_output_token_list(_save_data, vc)
			}
		else:
			if cnode_name == 'enter':
				data[cnode_name] = {
					tokens = [ {type = HenVirtualCNode.SubType.PASS, use_self = false}],
					params = []
				}

	return data


static func map_all_macros(_save_data: HenSaveData, _refs: HenTypeReferences) -> String:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var code: String = ''

	for route: HenRouteData in _save_data.routes.values():
		for macro_ref: HenVirtualCNode in route.virtual_cnode_list:
			if macro_ref.type == HenVirtualCNode.Type.MACRO:
				var macro: HenSaveMacro = macro_ref.get_res(_save_data)

				if macro:
					for macro_var: HenSaveParam in macro.local_vars:
						code += HenGeneratorVariable.get_var_code_from_param(macro_var, '{name}_{id}'.format({name = macro_var.name.to_snake_case(), id = macro_ref.id}))

					for v_cnode: HenVirtualCNode in macro.get_route(_save_data).virtual_cnode_list:
						if v_cnode.sub_type == HenVirtualCNode.SubType.OVERRIDE_VIRTUAL:
							global.USE_MACRO_REF = true
							global.MACRO_REF = macro_ref
							global.MACRO_USE_SELF = macro_ref.route_type != HenRouter.ROUTE_TYPE.STATE
							global.USE_MACRO_USE_SELF = true

							var flow_connections: Array = _save_data.get_flow_connection_from_vc(v_cnode)
							
							if (flow_connections.get(0) as HenVCFlowConnectionData).get_to(_save_data):
								if not _refs.override_virtual_data.has(v_cnode.name):
									_refs.override_virtual_data[v_cnode.name] = {
										params = HenVirtualCNodeCode.get_output_token_list(_save_data, v_cnode),
										tokens = []
									}

								for token: Dictionary in HenVirtualCNodeCode.get_flow_tokens(_save_data, (flow_connections.get(0) as HenVCFlowConnectionData).get_to(_save_data), 0):
									token.vc_id = macro_ref.id
									(_refs.override_virtual_data[v_cnode.name].tokens as Array).append(token)

							global.USE_MACRO_REF = false

	return code