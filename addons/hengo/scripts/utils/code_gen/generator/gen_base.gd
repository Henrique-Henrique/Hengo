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


static func get_base_script_code(_refs: HenTypeReferences) -> String:
	var code: String = ''
	var start_state: HenTypeCnode
	var override_virtual_data: Dictionary = {}
	var events: Array[Dictionary] = []
	var global: HenGlobal = Engine.get_singleton(&'Global')

	# getting states
	for cnode: HenTypeCnode in _refs.base_route_cnode_list:
		match cnode.sub_type:
			# getting start state cnode
			HenVirtualCNode.SubType.STATE_START:
				if not cnode.flow_connections.is_empty():
					start_state = cnode.flow_connections[0].get_to()
			HenVirtualCNode.SubType.STATE:
				var transitions: Array = []

				# getting transition
				for flow_connection: HenTypeFlowConnection in cnode.flow_connections:
					if flow_connection.to:
						transitions.append({
							name = 'flow_connection.name',
							to_state_name = flow_connection.get_to().name
						})

				_refs.states_data[cnode.name.to_snake_case()] = {
					virtual_tokens = _parse_virtual_cnode(cnode.virtual_sub_type_vc_list),
					transitions = transitions
				}
			HenVirtualCNode.SubType.STATE_EVENT:
				if not cnode.flow_connections.is_empty() and cnode.flow_connections[0].to:
					events.append({
						name = cnode.name,
						to_state_name = cnode.flow_connections[0].get_to().name
					})
			HenVirtualCNode.SubType.OVERRIDE_VIRTUAL:
				if not cnode.flow_connections.is_empty() and cnode.flow_connections[0].to:
					if not override_virtual_data.has(cnode.name):
						override_virtual_data[cnode.name] = {
							params = cnode.get_output_token_list(),
							tokens = []
						}

				override_virtual_data[cnode.name].tokens.append_array(cnode.flow_connections[0].get_to().get_flow_tokens(0))


	# search for override virtual inside macros
	for macro: HenTypeMacro in _refs.macros:
		# macro variables
		for macro_var: HenTypeVariable in macro.local_vars:
			for macro_ref: HenTypeCnode in macro.macro_ref_list:
				code += HenGeneratorVariable.get_var_code(macro_var, '{name}_{id}'.format({name = macro_var.name.to_snake_case(), id = macro_ref.id}), str(macro_ref.id))

		# macro override virtuals
		for v_cnode: HenTypeCnode in macro.virtual_cnode_list:
			if v_cnode.sub_type == HenVirtualCNode.SubType.OVERRIDE_VIRTUAL:
				for macro_ref: HenTypeCnode in macro.macro_ref_list:
					global.USE_MACRO_REF = true
					global.MACRO_REF = macro_ref
					global.MACRO_USE_SELF = macro_ref.route_type != HenRouter.ROUTE_TYPE.STATE
					global.USE_MACRO_USE_SELF = true

					if v_cnode.flow_connections[0].to:
						if not override_virtual_data.has(v_cnode.name):
							override_virtual_data[v_cnode.name] = {
								params = v_cnode.get_output_token_list(),
								tokens = []
							}

						for token: Dictionary in v_cnode.flow_connections[0].get_to().get_flow_tokens(0):
							token.vc_id = macro_ref.id
							override_virtual_data[v_cnode.name].tokens.append(token)

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
				event_name = ev.name.to_snake_case(),
				to_state_name = ev.to_state_name.to_snake_case()
			})
			)) + '\n}' if not events.is_empty() else '{}',
		start_state_name = start_state.name.to_snake_case() if start_state else '',
		_ready = ' \n'.join(ready_code),
		_process = '\n'.join(process_code),
		_physics_process = '\n'.join(physics_process_code),
		states_dict = HenGeneratorState.get_states_start_code(_refs),
		states = HenGeneratorState.get_states_code(_refs)
	})


#
#
#
#
#
#
static func _parse_virtual_cnode(_cnode_list: Array[HenTypeCnode]) -> Dictionary:
	var data: Dictionary = {}


	for cnode: HenTypeCnode in _cnode_list:
		if cnode.flow_connections.is_empty():
			continue
		
		var cnode_name: String = cnode.name
		var from_flow: HenTypeFlowConnection = cnode.flow_connections[0]

		if from_flow.to:
			var token_list = from_flow.get_to().get_flow_tokens(from_flow.to_id)

			data[cnode_name] = {
				tokens = token_list,
				params = cnode.get_output_token_list()
			}
		else:
			if cnode_name == 'enter':
				data[cnode_name] = {
					tokens = [ {type = HenVirtualCNode.SubType.PASS, use_self = false}],
					params = []
				}

	return data