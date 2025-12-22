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


static func get_base_script_code(_save_data: HenSaveData, _refs) -> String:
	var code: String = ''
	var start_state: HenVirtualCNode
	var override_virtual_data: Dictionary = {}
	var events: Array[Dictionary] = []
	var global: HenGlobal = Engine.get_singleton(&'Global')


	# getting states
	for _vc: HenVirtualCNode in _save_data.base_route.virtual_cnode_list:
		var flow_connections: Array = _save_data.get_flow_connection_from_vc(_vc)
		
		match _vc.identity.sub_type:
			# getting start state cnode
			HenVirtualCNode.SubType.STATE_START:
				if not flow_connections.is_empty():
					start_state = (flow_connections[0] as HenVCFlowConnectionData).get_to()
			HenVirtualCNode.SubType.STATE:
				var transitions: Array = []

				# getting transition
				for flow_connection: HenVCFlowConnectionData in flow_connections:
					if flow_connection.to:
						transitions.append({
							name = 'flow_connection.name',
							to_state_name = flow_connection.get_to().identity.name
						})

				_refs.states_data[_vc.identity.name.to_snake_case()] = {
					virtual_tokens = _parse_virtual_cnode(_vc.route_info.route.virtual_sub_type_vc_list),
					transitions = transitions
				}
			HenVirtualCNode.SubType.STATE_EVENT:
				if not flow_connections.is_empty() and flow_connections[0].to:
					events.append({
						name = _vc.identity.name,
						to_state_name = (flow_connections[0] as HenVCFlowConnectionData).get_to().identity.name
					})
			HenVirtualCNode.SubType.OVERRIDE_VIRTUAL:
				if not flow_connections.is_empty() and flow_connections[0].to:
					if not override_virtual_data.has(_vc.identity.name):
						override_virtual_data[_vc.identity.name] = {
							params = HenVirtualCNodeCode.get_output_token_list(_vc),
							tokens = []
						}

				(override_virtual_data[_vc.identity.name].tokens as Array).append_array(HenVirtualCNodeCode.get_flow_tokens((flow_connections[0] as HenVCFlowConnectionData).get_to(), 0))


	# search for override virtual inside macros
	for macro: HenSaveMacro in _save_data.macros:
		# TODO: this needs to map all macros??
		map_vc(macro.route.virtual_cnode_list, _refs)

		# macro variables
		for macro_var: HenSaveParam in macro.local_vars:
			for macro_ref: HenVirtualCNode in _refs.macro_vc_list:
				code += HenGeneratorVariable.get_var_code_from_param(macro_var, '{name}_{id}'.format({name = macro_var.name.to_snake_case(), id = macro_ref.identity.id}), str(macro_ref.identity.id))

		# macro override virtuals
		for v_cnode: HenVirtualCNode in macro.route.virtual_cnode_list:
			if v_cnode.identity.sub_type == HenVirtualCNode.SubType.OVERRIDE_VIRTUAL:
				for macro_ref: HenVirtualCNode in _refs.macro_vc_list:
					global.USE_MACRO_REF = true
					global.MACRO_REF = macro_ref
					global.MACRO_USE_SELF = macro_ref.identity.route_type != HenRouter.ROUTE_TYPE.STATE
					global.USE_MACRO_USE_SELF = true

					var flow_connections: Array = _save_data.get_flow_connection_from_vc(v_cnode)
					
					if flow_connections[0].to:
						if not override_virtual_data.has(v_cnode.identity.name):
							override_virtual_data[v_cnode.identity.name] = {
								params = HenVirtualCNodeCode.get_output_token_list(v_cnode),
								tokens = []
							}

						for token: Dictionary in HenVirtualCNodeCode.get_flow_tokens((flow_connections[0] as HenVCFlowConnectionData).get_to(), 0):
							token.vc_id = macro_ref.identity.id
							(override_virtual_data[v_cnode.identity.name].tokens as Array).append(token)

					global.USE_MACRO_REF = false


	var ready_code: Array = []
	var process_code: Array = []
	var physics_process_code: Array = []

	for key: StringName in override_virtual_data.keys():
		var item = override_virtual_data.get(key)

		match key:
			&'_ready':
				for token: Dictionary in item.tokens:
					var _code: String = HenGeneratorByToken.get_code_by_token(token, 1)
					if _code: ready_code.append(_code)
			&'_process':
				for token: Dictionary in item.tokens:
					var _code: String = HenGeneratorByToken.get_code_by_token(token, 1)
					if _code: process_code.append(_code)
			&'_physics_process':
				for token: Dictionary in item.tokens:
					var _code: String = HenGeneratorByToken.get_code_by_token(token, 1)
					if _code: physics_process_code.append(_code)

	return code + TEXT_BASE.format({
		events = ' { \n\t' + ',\n\t'.join(events.map(
			func(ev: Dictionary) -> String:
			return '{event_name}="{to_state_name}"'.format({
				event_name = (ev.name as String).to_snake_case(),
				to_state_name = (ev.to_state_name as String).to_snake_case()
			})
			)) + '\n}' if not events.is_empty() else '{}',
		start_state_name = (start_state as HenVirtualCNode).identity.name.to_snake_case() if start_state else '',
		_ready = ' \n'.join(ready_code),
		_process = '\n'.join(process_code),
		_physics_process = '\n'.join(physics_process_code),
		states_dict = HenGeneratorState.get_states_start_code(_refs),
		states = HenGeneratorState.get_states_code(_refs)
	})


static func _parse_virtual_cnode(_cnode_list: Array[HenVirtualCNode]) -> Dictionary:
	var data: Dictionary = {}
	var global: HenGlobal = Engine.get_singleton(&'Global')

	for vc: HenVirtualCNode in _cnode_list:
		var flow_connections: Array = global.SAVE_DATA.get_flow_connection_from_vc(vc)
		if flow_connections.is_empty():
			continue
		
		var cnode_name: String = vc.identity.name
		var from_flow: HenVCFlowConnectionData = flow_connections[0]

		if from_flow.to:
			pass
			var token_list = HenVirtualCNodeCode.get_flow_tokens(from_flow.get_to(), from_flow.to_id)

			data[cnode_name] = {
				tokens = token_list,
				params = HenVirtualCNodeCode.get_output_token_list(vc)
			}
		else:
			if cnode_name == 'enter':
				data[cnode_name] = {
					tokens = [ {type = HenVirtualCNode.SubType.PASS, use_self = false}],
					params = []
				}

	return data


static func map_vc(_cnode_list: Array[HenVirtualCNode], _refs: HenTypeReferences) -> void:
	_refs.state_vc_list.clear()
	_refs.macro_vc_list.clear()

	for vc: HenVirtualCNode in _cnode_list:
		match vc.identity.type:
			HenVirtualCNode.Type.STATE:
				if not vc.state.invalid:
					_refs.state_vc_list.append(vc)
			HenVirtualCNode.Type.MACRO:
				if not vc.state.invalid:
					_refs.macro_vc_list.append(vc)