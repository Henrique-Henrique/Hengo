class_name HenGeneratorBase extends RefCounted

const TEXT_BASE: String = """var _STATE_CONTROLLER = HengoStateController.new()

const _EVENTS = {events}

func _init() -> void:
	_STATE_CONTROLLER.set_states({
{states_dict}
	})

func _ready() -> void:
	if not _STATE_CONTROLLER.current_state:
		_STATE_CONTROLLER.change_state("{start_state_name}"{start_state_data})
{_ready}
func trigger_event(_event: StringName) -> void:
	if _EVENTS.has(_event):
		_STATE_CONTROLLER.change_state(_EVENTS[_event])

func _process(delta: float) -> void:
	_STATE_CONTROLLER.static_process(delta)
{_process}
func _physics_process(delta: float) -> void:
	_STATE_CONTROLLER.static_physics_process(delta)
{_physics_process}
{custom_virtuals}{states}"""


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
	var custom_virtual_code: String = ''

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
			_:
				custom_virtual_code += _get_custom_virtual_code(key, item, _save_data)

	var start_state_data: String = ''

	# start state params generation
	if start_state:
		var res: HenSaveState = start_state.get_res(_save_data)
		for virtual_vc: HenVirtualCNode in res.get_route(_save_data).virtual_sub_type_vc_list:
			if virtual_vc.get_vc_name(_save_data) == 'enter':
				var flow_tokens: Array = HenVirtualCNodeCode.get_output_token_list(_save_data, virtual_vc)
				start_state_data = (', ' if not flow_tokens.is_empty() else '') + ', '.join(flow_tokens.map(func(x: Dictionary) -> String:
					return HenVirtualCNodeCode.get_default_value_code(_save_data, x.type, false)))
				break

	return code + TEXT_BASE.format({
		events = ' {\n\t' + ',\n\t'.join(events.map(
			func(ev: Dictionary) -> String:
			return '{event_name}="{to_state_name}"'.format({
				event_name = (ev.name as String).to_snake_case(),
				to_state_name = (ev.to_state_name as String).to_snake_case()
			})
			)) + '\n}' if not events.is_empty() else '{}',
		start_state_name = (start_state as HenVirtualCNode).get_vc_name(_save_data).to_snake_case() if start_state else '',
		start_state_data = start_state_data,
		_ready = ' \n'.join(ready_code),
		_process = '\n'.join(process_code),
		_physics_process = '\n'.join(physics_process_code),
		custom_virtuals = custom_virtual_code,
		states_dict = HenGeneratorState.get_states_start_code(_save_data),
		states = HenGeneratorState.get_states_code(_save_data)
	})


# generates code for override virtuals that are not _ready, _process, or _physics_process
static func _get_custom_virtual_code(_name: StringName, _item: Dictionary, _save_data: HenSaveData) -> String:
	var params: Array = _item.get('params', [])
	var params_str: String = ', '.join(params.map(func(p: Dictionary) -> String:
		return '{name}: {type}'.format({name = p.name, type = p.type})
	))
	
	var body_code: Array = []
	for token: Dictionary in _item.tokens:
		var _code: String = HenGeneratorByToken.get_code_by_token(_save_data, token, 1)
		if _code:
			body_code.append(_code)
	
	var body: String = '\n'.join(body_code) if not body_code.is_empty() else '\tpass'
	
	return 'func {name}({params}) -> void:\n{body}\n'.format({
		name = _name,
		params = params_str,
		body = body
	})


static func parse_virtual_cnode(_cnode_list: Array, _save_data: HenSaveData) -> Dictionary:
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
			match macro_ref.sub_type:
				HenVirtualCNode.SubType.MACRO:
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

				HenVirtualCNode.SubType.SCRIPT_MACRO:
					var res: HenSaveMacro = macro_ref.get_res(_save_data)
					if res and FileAccess.file_exists(res.script_path):
						var script: GDScript = load(res.script_path)
						if script:
							var instance: HenScriptMacroBase = script.new()
							if instance:
								var overrides: Array[Dictionary] = instance.get_function_overrides()
								for override: Dictionary in overrides:
									var func_name: String = override.get('name', '')
									if func_name.is_empty(): continue
									
									if not _refs.override_virtual_data.has(func_name):
										_refs.override_virtual_data[func_name] = {
											params = override.get('params', []),
											tokens = []
										}
									
									var body: Variant = override.get('body', 'pass')
									
									if body is Callable:
										var method_name: String = (body as Callable).get_method()
										var object: Object = (body as Callable).get_object()
										var script_source: String = ''
										
										if object and object.get_script():
											script_source = object.get_script().source_code
										
										var parsed: Dictionary = HenVirtualCNodeCode.parse_script_function(script_source, method_name)
										if parsed.has('body'):
											body = parsed.body
										else:
											body = '# error: could not find body for callable ' + method_name
									
									var body_str: String = str(body)
									var use_self: bool = macro_ref.route_type != HenRouter.ROUTE_TYPE.STATE
									
									body_str = HenVirtualCNodeCode.process_script_macro_body(body_str, use_self, macro_ref.id)
									
									# add raw_code token
									(_refs.override_virtual_data[func_name].tokens as Array).append({
										vc_id = macro_ref.id,
										type = HenVirtualCNode.SubType.RAW_CODE,
										code = {value = body_str},
										use_self = false
									})

	return code