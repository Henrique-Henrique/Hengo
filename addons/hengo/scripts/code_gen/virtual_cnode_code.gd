class_name HenVirtualCNodeCode extends RefCounted

static func get_invalid_token() -> Dictionary:
	return {
		type = HenVirtualCNode.SubType.INVALID,
		use_self = false
	}


static func get_flow_tokens(_save_data: HenSaveData, _vc: HenVirtualCNode, _input_id: int, _token_list: Array = []) -> Array:
	var stack: Array = []
	var token_list: Array = _token_list

	stack.append({node = _vc, id = _input_id})

	while not stack.is_empty():
		var current: Dictionary = stack.pop_back()
		var vc: HenVirtualCNode = current.node
		var _id: int = current.id

		if current.has('flow_id'):
			token_list = (Engine.get_singleton(&'CodeGeneration') as HenCodeGeneration).flows_refs[current.flow_id]

		match vc.sub_type:
			HenVirtualCNode.SubType.IF:
				token_list.append(get_if_token(_save_data, vc, stack))
			HenVirtualCNode.SubType.FOR, HenVirtualCNode.SubType.FOR_ARR:
				token_list.append(get_for_token(_save_data, vc, stack))
			HenVirtualCNode.SubType.MACRO:
				token_list.append(get_macro_token(_save_data, vc, _id))
			HenVirtualCNode.SubType.MACRO_OUTPUT:
				var global: HenGlobal = Engine.get_singleton(&'Global')
				if global.USE_MACRO_REF:
					var flow: HenVCFlowConnectionData = get_macro_flow_connection(_save_data, global.MACRO_REF, _id) if not _save_data.get_outgoing_flow_connection_from_vc(global.MACRO_REF).is_empty() else null


					if flow and flow.get_to(_save_data):
						stack.append({node = flow.get_to(_save_data), id = flow.to_id})
			_:
				token_list.append(get_token(_save_data, vc))
				var flow_connections: Array = _save_data.get_outgoing_flow_connection_from_vc(vc)

				if not flow_connections.is_empty() and (flow_connections.get(0) as HenVCFlowConnectionData).get_to(_save_data):
					var first: HenVCFlowConnectionData = flow_connections.get(0)
					stack.append({node = first.get_to(_save_data), id = first.to_id})

	return _token_list


static func get_if_token(_save_data: HenSaveData, _vc: HenVirtualCNode, _stack: Array) -> Dictionary:
	var code_generation: HenCodeGeneration = Engine.get_singleton(&'CodeGeneration')

	var true_flow_id: int = code_generation.get_flow_id()
	var false_flow_id: int = code_generation.get_flow_id()
	var then_flow_id: int = code_generation.get_flow_id()

	code_generation.flows_refs[true_flow_id] = []
	code_generation.flows_refs[false_flow_id] = []
	code_generation.flows_refs[then_flow_id] = []

	for flow: HenVCFlowConnectionData in _save_data.get_outgoing_flow_connection_from_vc(_vc):
		match flow.from_id:
			0:
				_stack.append({node = flow.get_to(_save_data), id = flow.to_id, flow_id = true_flow_id})
			1:
				_stack.append({node = flow.get_to(_save_data), id = flow.to_id, flow_id = false_flow_id})
			2:
				_stack.append({node = flow.get_to(_save_data), id = flow.to_id, flow_id = then_flow_id})

	return {
		vc_id = _vc.id,
		type = HenVirtualCNode.SubType.IF,
		true_flow_id = true_flow_id,
		false_flow_id = false_flow_id,
		then_flow_id = then_flow_id,
		condition = get_input_token(_save_data, _vc, _vc.get_inputs(_save_data)[0].id),
		use_self = false
	}


static func get_for_token(_save_data: HenSaveData, _vc: HenVirtualCNode, _stack: Array) -> Dictionary:
	var code_generation: HenCodeGeneration = Engine.get_singleton(&'CodeGeneration')
	var body_flow_id: int = code_generation.get_flow_id()
	var then_flow_id: int = code_generation.get_flow_id()

	code_generation.flows_refs[body_flow_id] = []
	code_generation.flows_refs[then_flow_id] = []

	for flow: HenVCFlowConnectionData in _save_data.get_outgoing_flow_connection_from_vc(_vc):
		match flow.from_id:
			0:
				_stack.append({node = flow.get_to(_save_data), id = flow.to_id, flow_id = body_flow_id})
			1:
				_stack.append({node = flow.get_to(_save_data), id = flow.to_id, flow_id = then_flow_id})

	return {
		id = _vc.id,
		vc_id = _vc.id,
		type = _vc.sub_type,
		body_flow_id = body_flow_id,
		then_flow_id = then_flow_id,
		params = get_input_token_list(_save_data, _vc),
		index_name = _vc.get_outputs(_save_data)[0].name.to_snake_case(),
		use_self = false
	}


static func get_macro_flow_connection(_save_data: HenSaveData, _vc: HenVirtualCNode, _id: int) -> HenVCFlowConnectionData:
	for flow: HenVCFlowConnectionData in _save_data.get_outgoing_flow_connection_from_vc(_vc):
		if flow.from_id == _id:
			return flow
	
	return null


static func get_macro_token(_save_data: HenSaveData, _vc: HenVirtualCNode, _flow_id: int) -> Dictionary:
	if _vc.invalid:
		return get_invalid_token()

	var flow_tokens: Array
	var input_ref: HenVirtualCNode = search_macro_input(_save_data, _vc.get_res(_save_data))

	if not input_ref:
		print('Macro input reference not found.')
		return get_invalid_token()
	
	var input_flow: HenVCFlowConnectionData = get_macro_flow_connection(_save_data, input_ref, _flow_id)
	var input_flow_to: HenVirtualCNode = input_flow.get_to(_save_data) if input_flow else null

	if input_flow_to:
		var global: HenGlobal = Engine.get_singleton(&'Global')
		var prev_use_macro_ref: bool = global.USE_MACRO_REF
		var prev_macro_ref: HenVirtualCNode = global.MACRO_REF
		var prev_macro_use_self: bool = global.MACRO_USE_SELF
		var prev_use_macro_use_self: bool = global.USE_MACRO_USE_SELF

		global.USE_MACRO_REF = true
		global.MACRO_REF = _vc
		global.MACRO_USE_SELF = _vc.route_type != HenRouter.ROUTE_TYPE.STATE
		global.USE_MACRO_USE_SELF = true
		
		flow_tokens = get_flow_tokens(_save_data, input_flow_to, input_flow.to_id)
		
		global.USE_MACRO_REF = prev_use_macro_ref
		global.MACRO_REF = prev_macro_ref
		global.MACRO_USE_SELF = prev_macro_use_self
		global.USE_MACRO_USE_SELF = prev_use_macro_use_self

	return {
		vc_id = _vc.id,
		type = HenVirtualCNode.SubType.MACRO,
		flow_tokens = flow_tokens,
		use_self = false
	}


static func search_macro_input(_save_data: HenSaveData, _macro: HenSaveMacro) -> HenVirtualCNode:
	if not _macro:
		return null

	for vc: HenVirtualCNode in _macro.get_route(_save_data).virtual_cnode_list:
		if vc.sub_type == HenVirtualCNode.SubType.MACRO_INPUT:
			return vc

	return null


static func get_output_token_list(_save_data: HenSaveData, _vc: HenVirtualCNode) -> Array:
	return _vc.get_outputs(_save_data).map(
		func(x: HenVCInOutData) -> Dictionary:
			return {name = x.name, type = x.type}
	)


static func get_input_token_list(_save_data: HenSaveData, _vc: HenVirtualCNode, _get_name: bool = false) -> Array:
	var input_tokens: Array = []

	for input: HenVCInOutData in _vc.get_inputs(_save_data):
		input_tokens.append(get_input_token(_save_data, _vc, input.id))

	return input_tokens


static func search_macro_output(_save_data: HenSaveData, _macro: HenSaveMacro) -> HenVirtualCNode:
	if not _macro:
		return null

	for vc: HenVirtualCNode in _macro.get_route(_save_data).virtual_cnode_list:
		if vc.sub_type == HenVirtualCNode.SubType.MACRO_OUTPUT:
			return vc
	return null


static func get_input_token(_save_data: HenSaveData, _vc: HenVirtualCNode, _id: int) -> Dictionary:
	var connection: HenVCConnectionData
	var input: HenVCInOutData = _vc.get_input(_id, _save_data)
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if not input:
		(Engine.get_singleton(&'ToastContainer') as HenToast).notify.call_deferred("Not found input token to generate: id -> " + str(_id), HenToast.MessageType.ERROR)
		return {}

	for input_connection: HenVCConnectionData in _save_data.get_to_connection_from_vc(_vc):
		if input_connection.to_id == _id:
			var output_id_list: Array = input_connection.get_from(_save_data).get_outputs(_save_data).map(func(x): return x.id)
			var input_id_list: Array = input_connection.get_to(_save_data).get_inputs(_save_data).map(func(x): return x.id)

			if not output_id_list.has(input_connection.from_id) or not input_id_list.has(input_connection.to_id):
				continue

			connection = input_connection
			break

	var use_self: bool = (_vc.route_type != HenRouter.ROUTE_TYPE.STATE) if not global.USE_MACRO_USE_SELF else global.MACRO_USE_SELF

	if connection and connection.get_from(_save_data):
		match connection.get_from(_save_data).sub_type:
			HenVirtualCNode.SubType.MACRO_INPUT:
				if global.USE_MACRO_REF:
					var data: Dictionary = get_input_token(_save_data, global.MACRO_REF, connection.from_id)
					return data
			HenVirtualCNode.SubType.MACRO:
				global.USE_MACRO_USE_SELF = true
				global.MACRO_USE_SELF = _vc.route_type != HenRouter.ROUTE_TYPE.STATE
				var vc: HenVirtualCNode = connection.get_from(_save_data)
				
				var macro_res: HenSaveMacro = vc.get_res(_save_data)

				if not macro_res:
					return get_invalid_token()

				var macro_route: HenRouteData = macro_res.get_route(_save_data)

				if not macro_route:
					return get_invalid_token()

				var macro_output: HenVirtualCNode = search_macro_output(_save_data, macro_res)
				var data: Dictionary = get_input_token(_save_data, macro_output, connection.from_id)
				global.USE_MACRO_USE_SELF = false
				return data
			_:
				var data: Dictionary = get_token(_save_data, connection.get_from(_save_data), get_output_index(_save_data, connection.get_from(_save_data), connection.from_id))
				
				if not data.type == HenVirtualCNode.SubType.INVALID:
					data.prop_name = input.name

				if global.USE_MACRO_REF:
					if data.has('value'):
						data.value += '_' + str(global.MACRO_REF.id)

				if input.is_ref:
					data.is_ref = input.is_ref
				
				return data
	elif input.code_value:
		var data: Dictionary = {
			type = HenVirtualCNode.SubType.IN_PROP,
			prop_name = input.name,
			value = input.code_value,
			use_self = use_self,
		}

		if global.USE_MACRO_REF:
			if input.category == 'class_props':
				data.value += '_' + str(global.MACRO_REF.id)

		if input.is_ref:
			data.is_ref = input.is_ref
			data.ref_value = input.code_value

		if input.category:
			match input.category:
				'default_value':
					if not input.is_ref:
						data.use_self = true

					data.use_value = true
				'class_props':
					data.use_value = true

		if data.get('is_ref', false) and not data.get('use_self', false):
			if HenUtils.is_type_relation_valid(
					_save_data.identity.type,
					input.type,
				):
					data.ref_value = '_ref'

		return data

	var not_connected: Dictionary = {
		type = HenVirtualCNode.SubType.NOT_CONNECTED,
		input_type = input.type,
		use_self = use_self,
		prop_name = input.name
	}

	if input.is_ref:
		not_connected.set('is_ref', true)

	return not_connected


static func get_output_index(_save_data: HenSaveData, _vc: HenVirtualCNode, _id: int) -> int:
	var idx: int = 0

	for output: HenVCInOutData in _vc.get_outputs(_save_data):
		if output.id == _id:
			return idx

		idx += 1

	return 0


static func get_token(_save_data: HenSaveData, _vc: HenVirtualCNode, _id: int = 0) -> Dictionary:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	var token: Dictionary = {
		vc_id = _vc.id,
		type = _vc.sub_type,
		use_self = (_vc.route_type != HenRouter.ROUTE_TYPE.STATE) if not global.USE_MACRO_USE_SELF else global.MACRO_USE_SELF,
	}


	if _vc.category:
		token.category = _vc.category

	if _vc.invalid:
		return get_invalid_token()

	match _vc.sub_type:
		HenVirtualCNode.SubType.VOID, HenVirtualCNode.SubType.GO_TO_VOID, HenVirtualCNode.SubType.SELF_GO_TO_VOID:
			token.merge({
				name = _vc.name.to_snake_case() if not _vc.name_to_code else _vc.name_to_code.to_snake_case(),
				params = get_input_token_list(_save_data, _vc),
				singleton_class = _vc.singleton_class
			})
		HenVirtualCNode.SubType.FUNC, HenVirtualCNode.SubType.USER_FUNC, HenVirtualCNode.SubType.FUNC_FROM, HenVirtualCNode.SubType.MAKE_TRANSITION:
			var params: Array

			match _vc.sub_type:
				HenVirtualCNode.SubType.FUNC_FROM:
					var inputs: Array = _vc.get_inputs(_save_data)
					
					if not inputs.is_empty() and not _vc.input_has_connection(inputs[0].id, _save_data):
						(Engine.get_singleton(&'CodeGeneration') as HenCodeGeneration).flow_errors.append({})
						return get_invalid_token()
					
					params = get_input_token_list(_save_data, _vc)
				HenVirtualCNode.SubType.MAKE_TRANSITION:
					var inputs: Array[HenVCInOutData] = _vc.get_inputs(_save_data)
					if inputs.is_empty(): return get_invalid_token()
					
					var first_input: HenVCInOutData = inputs[0]
					var state: HenSaveState = first_input.get_res(_save_data)

					if not state: return get_invalid_token()
					
					var flow: HenSaveParam

					for param: HenSaveParam in state.flow_outputs:
						if param.id == first_input.res_data.get('flow_id'):
							flow = param
							break

					if not flow:
						return get_invalid_token()

					params = [
						{
							type = HenVirtualCNode.SubType.IN_PROP,
							prop_name = 'name',
							value = "&\"{0}\"".format([flow.name.to_snake_case()]),
							use_self = false
						}
					]
				_:
					params = get_input_token_list(_save_data, _vc)

			token.merge({
				name = _vc.get_vc_name(_save_data).to_snake_case() if not _vc.name_to_code else _vc.name_to_code.to_snake_case(),
				params = params,
				id = _id if _vc.get_outputs(_save_data).size() > 1 else -1,
				singleton_class = _vc.singleton_class
			})
		HenVirtualCNode.SubType.VAR, HenVirtualCNode.SubType.LOCAL_VAR:
			var name: String = _vc.get_outputs(_save_data)[0].name.to_snake_case()

			if _vc.sub_type == HenVirtualCNode.SubType.LOCAL_VAR:
				if global.USE_MACRO_REF:
					name += '_' + str(global.MACRO_REF.id)

			token.merge({
				name = name,
				use_self = true if _vc.sub_type == HenVirtualCNode.SubType.LOCAL_VAR else token.use_self
			})
		HenVirtualCNode.SubType.VAR_FROM:
			var inputs: Array = _vc.get_inputs(_save_data)
			
			if not inputs.is_empty() and not _vc.input_has_connection(inputs[0].id, _save_data):
				(Engine.get_singleton(&'CodeGeneration') as HenCodeGeneration).flow_errors.append({})
				return get_invalid_token()
			
			token.merge({
				ref = get_input_token(_save_data, _vc, 0),
				name = _vc.get_outputs(_save_data)[0].name.to_snake_case(),
			})
		HenVirtualCNode.SubType.SET_VAR_FROM:
			var inputs: Array = _vc.get_inputs(_save_data)
			
			if not inputs.is_empty() and not _vc.input_has_connection(inputs[0].id, _save_data):
				(Engine.get_singleton(&'CodeGeneration') as HenCodeGeneration).flow_errors.append({})
				return get_invalid_token()
			
			token.merge({
				name = _vc.get_vc_name(_save_data).to_snake_case(),
				ref = get_input_token(_save_data, _vc, 0),
				value = get_input_token(_save_data, _vc, 1)
			})
		HenVirtualCNode.SubType.SET_VAR, HenVirtualCNode.SubType.SET_LOCAL_VAR:
			var name: String = _vc.get_inputs(_save_data)[0].name.to_snake_case()

			if _vc.sub_type == HenVirtualCNode.SubType.SET_LOCAL_VAR:
				if global.USE_MACRO_REF:
					name += '_' + str(global.MACRO_REF.id)

			token.merge({
				name = name,
				value = get_input_token_list(_save_data, _vc)[0],
				use_self = true if _vc.sub_type == HenVirtualCNode.SubType.SET_LOCAL_VAR else token.use_self
			})
		HenVirtualCNode.SubType.VIRTUAL, HenVirtualCNode.SubType.FUNC_INPUT, HenVirtualCNode.SubType.OVERRIDE_VIRTUAL, HenVirtualCNode.SubType.SIGNAL_ENTER:
			token.merge({
				param = _vc.get_outputs(_save_data)[_id].name.to_snake_case(),
			})
		HenVirtualCNode.SubType.FOR, HenVirtualCNode.SubType.FOR_ARR:
			return {
				id = _vc.id,
				type = HenVirtualCNode.SubType.FOR_ITEM,
				name = _vc.get_outputs(_save_data)[0].name.to_snake_case(),
				use_self = true
			}
		HenVirtualCNode.SubType.IMG:
			token.merge({
				name = _vc.name.to_snake_case(),
				params = get_input_token_list(_save_data, _vc)
			})
		HenVirtualCNode.SubType.RAW_CODE:
			token.merge({
				code = get_input_token_list(_save_data, _vc)[0],
			})
		HenVirtualCNode.SubType.CONST:
			token.merge({
				singleton_class = _vc.name,
				name = _vc.name_to_code
			})
		HenVirtualCNode.SubType.EXPRESSION:
			# check inputs
			for input: HenVCInOutData in _vc.get_inputs(_save_data).slice(1):
				if not _vc.input_has_connection(input.id, _save_data):
					(Engine.get_singleton(&'CodeGeneration') as HenCodeGeneration).flow_errors.append({})

			token.merge({
				params = get_input_token_list(_save_data, _vc, true),
				exp = _vc.get_inputs(_save_data)[0].value
			})
		HenVirtualCNode.SubType.SIGNAL_CONNECTION:
			var res = _vc.get_res(_save_data)

			if not res:
				return get_invalid_token()

			token.merge({
				params = get_input_token_list(_save_data, _vc, true),
				signal_name = (res as HenSaveSignalCallback).signal_name_to_code,
				name = (res as HenSaveSignalCallback).name
			})
		HenVirtualCNode.SubType.SIGNAL_DISCONNECTION:
			var res = _vc.get_res(_save_data)

			if not res:
				return get_invalid_token()

			token.merge({
				params = get_input_token_list(_save_data, _vc, true),
				signal_name = (res as HenSaveSignalCallback).signal_name_to_code,
				name = (res as HenSaveSignalCallback).name.to_snake_case()
			})
		HenVirtualCNode.SubType.STATE_TRANSITION:
			var res: HenSaveState = _vc.get_res(_save_data)

			if not res:
				return get_invalid_token()
			
			token.merge({
				is_sub_state = res.is_sub_state,
				name = res.name.to_snake_case(),
				params = get_input_token_list(_save_data, _vc, true),
			})
		HenVirtualCNode.SubType.GET_PROP:
			token.merge({
				ref = get_input_token(_save_data, _vc, _vc.get_inputs(_save_data)[0].id),
				name = _vc.get_outputs(_save_data)[0].name.to_snake_case(),
			})
		HenVirtualCNode.SubType.SET_PROP:
			var value_input: HenVCInOutData = _vc.get_inputs(_save_data)[1]
			
			token.merge({
				ref = get_input_token(_save_data, _vc, _vc.get_inputs(_save_data)[0].id),
				value = get_input_token(_save_data, _vc, value_input.id),
				name = value_input.name.to_snake_case(),
			})
		HenVirtualCNode.SubType.INPUT_EVENT_CHECK:
			var inputs: Array[HenVCInOutData] = _vc.get_inputs(_save_data)
			
			if inputs.is_empty() or not _vc.input_has_connection(inputs[0].id, _save_data):
				return get_invalid_token()
			
			var value_code: String = inputs[1].code_value if inputs.size() > 1 else ''
			
			token.merge({
				event_param = get_input_token(_save_data, _vc, inputs[0].id),
				event_type = _vc.input_code_value_map.get('event_type', ''),
				check_pressed = _vc.input_code_value_map.get('check_pressed', true),
				property = _vc.input_code_value_map.get('property', ''),
				value = value_code
			})
		HenVirtualCNode.SubType.INPUT_ACTION_CHECK:
			var inputs: Array[HenVCInOutData] = _vc.get_inputs(_save_data)
			
			if inputs.is_empty() or not _vc.input_has_connection(inputs[0].id, _save_data):
				return get_invalid_token()
			
			var action_code: String = inputs[1].code_value if inputs.size() > 1 else ''
			
			token.merge({
				event_param = get_input_token(_save_data, _vc, inputs[0].id),
				method = _vc.input_code_value_map.get('method', 'is_action_pressed'),
				action = action_code
			})
		HenVirtualCNode.SubType.INPUT_POLLING:
			var inputs: Array[HenVCInOutData] = _vc.get_inputs(_save_data)
			var action_code: String = inputs[0].code_value if not inputs.is_empty() else ''
			
			token.merge({
				method = _vc.input_code_value_map.get('method', 'is_action_pressed'),
				action = action_code
			})

	return token


static func get_virtual_cnode_code(_save_data: HenSaveData, _vc: HenVirtualCNode, _flow_id: int) -> String:
	var code: String = ''

	for token in HenVirtualCNodeCode.get_flow_tokens(_save_data, _vc, _flow_id):
		code += HenGeneratorByToken.get_code_by_token(_save_data, token)

	return code


static func get_default_value_code(_save_data: HenSaveData, _type: String, _use_self: bool) -> String:
	match _type:
		'String', 'NodePath', 'StringName':
			return '""'
		'int':
			return '0'
		'float':
			return '0.'
		'Vector2':
			return 'Vector2(0, 0)'
		'bool':
			return 'false'
		'Variant':
			return 'null'
		_:
			if HenEnums.VARIANT_TYPES.has(_type):
				return _type + '()'
			elif ClassDB.can_instantiate(_type):
				if HenUtils.is_type_relation_valid(
					_save_data.identity.type,
					_type,
				):
					return '_ref' if not _use_self else 'self'
				
				return _type + '.new()'
	
	return 'null'
