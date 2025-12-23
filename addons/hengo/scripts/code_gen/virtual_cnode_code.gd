class_name HenVirtualCNodeCode extends RefCounted

const INVALID_TOKEN: Dictionary = {
	type = HenVirtualCNode.SubType.INVALID,
	use_self = false
}


static func get_flow_tokens(_vc: HenVirtualCNode, _input_id: int, _token_list: Array = []) -> Array:
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
				token_list.append(get_if_token(vc, stack))
			HenVirtualCNode.SubType.FOR, HenVirtualCNode.SubType.FOR_ARR:
				token_list.append(get_for_token(vc, stack))
			HenVirtualCNode.SubType.MACRO:
				token_list.append(get_macro_token(vc, _id))
			HenVirtualCNode.SubType.MACRO_OUTPUT:
				var global: HenGlobal = Engine.get_singleton(&'Global')
				if global.USE_MACRO_REF:
					var flow: HenVCFlowConnectionData = get_flow_connection(global.MACRO_REF, _id) if not global.SAVE_DATA.get_outgoing_flow_connection_from_vc(global.MACRO_REF).is_empty() else null

					if flow and flow.get_to():
						stack.append({node = flow.get_to(), id = flow.to_id})
					
					global.USE_MACRO_REF = false
			_:
				var global: HenGlobal = Engine.get_singleton(&'Global')
				token_list.append(get_token(vc))
				var flow_connections: Array = global.SAVE_DATA.get_outgoing_flow_connection_from_vc(vc)

				if not flow_connections.is_empty() and (flow_connections[0] as HenVCFlowConnectionData).get_to():
					var first: HenVCFlowConnectionData = flow_connections[0]
					stack.append({node = first.get_to(), id = first.to_id})

	return _token_list


static func get_if_token(_vc: HenVirtualCNode, _stack: Array) -> Dictionary:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var code_generation: HenCodeGeneration = Engine.get_singleton(&'CodeGeneration')

	var true_flow_id: int = code_generation.get_flow_id()
	var false_flow_id: int = code_generation.get_flow_id()
	var then_flow_id: int = code_generation.get_flow_id()

	code_generation.flows_refs[true_flow_id] = []
	code_generation.flows_refs[false_flow_id] = []
	code_generation.flows_refs[then_flow_id] = []

	for flow: HenVCFlowConnectionData in global.SAVE_DATA.get_outgoing_flow_connection_from_vc(_vc):
		match flow.from_id:
			0:
				_stack.append({node = flow.get_to(), id = flow.to_id, flow_id = true_flow_id})
			1:
				_stack.append({node = flow.get_to(), id = flow.to_id, flow_id = false_flow_id})
			2:
				_stack.append({node = flow.get_to(), id = flow.to_id, flow_id = then_flow_id})

	return {
		vc_id = _vc.id,
		type = HenVirtualCNode.SubType.IF,
		true_flow_id = true_flow_id,
		false_flow_id = false_flow_id,
		then_flow_id = then_flow_id,
		condition = get_input_token(_vc, _vc.inputs[0].id),
		use_self = false
	}


static func get_for_token(_vc: HenVirtualCNode, _stack: Array) -> Dictionary:
	var code_generation: HenCodeGeneration = Engine.get_singleton(&'CodeGeneration')
	var global: HenGlobal = Engine.get_singleton(&'Global')

	var body_flow_id: int = code_generation.get_flow_id()
	var then_flow_id: int = code_generation.get_flow_id()

	code_generation.flows_refs[body_flow_id] = []
	code_generation.flows_refs[then_flow_id] = []

	for flow: HenVCFlowConnectionData in global.SAVE_DATA.get_outgoing_flow_connection_from_vc(_vc):
		match flow.from_id:
			0:
				_stack.append({node = flow.get_to(), id = flow.to_id, flow_id = body_flow_id})
			1:
				_stack.append({node = flow.get_to(), id = flow.to_id, flow_id = then_flow_id})

	return {
		id = _vc.id,
		vc_id = _vc.id,
		type = _vc.sub_type,
		body_flow_id = body_flow_id,
		then_flow_id = then_flow_id,
		params = get_input_token_list(_vc),
		index_name = _vc.outputs[0].name.to_snake_case(),
		use_self = false
	}


static func get_flow_connection(_vc: HenVirtualCNode, _id: int) -> HenVCFlowConnectionData:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	for flow: HenVCFlowConnectionData in global.SAVE_DATA.get_outgoing_flow_connection_from_vc(_vc):
		if flow.from_id == _id:
			return flow
	
	return null


static func get_macro_token(_vc: HenVirtualCNode, _flow_id: int) -> Dictionary:
	if _vc.invalid:
		return INVALID_TOKEN

	var flow_tokens: Array
	# var input_flow: HenTypeFlowConnection = (ref.get_ref().input_ref as HenTypeCnode).get_flow_connection(_flow_id)
	var input_ref: HenVirtualCNode = search_macro_input(_vc.res)

	if not input_ref:
		print('Macro input reference not found.')
		return INVALID_TOKEN
	
	var input_flow: HenVCFlowConnectionData = get_flow_connection(input_ref, _flow_id)

	if input_flow.get_to():
		var global: HenGlobal = Engine.get_singleton(&'Global')
		global.USE_MACRO_REF = true
		global.MACRO_REF = _vc
		global.MACRO_USE_SELF = _vc.route_type != HenRouter.ROUTE_TYPE.STATE
		global.USE_MACRO_USE_SELF = true
		flow_tokens = get_flow_tokens(input_flow.get_to(), input_flow.to_id)
		global.USE_MACRO_USE_SELF = false

	return {
		vc_id = _vc.id,
		type = HenVirtualCNode.SubType.MACRO,
		flow_tokens = flow_tokens,
		use_self = false
	}


static func search_macro_input(_func: HenSaveMacro) -> HenVirtualCNode:
	for vc: HenVirtualCNode in _func.route.virtual_cnode_list:
		if vc.sub_type == HenVirtualCNode.SubType.MACRO_INPUT:
			return vc
	return null


static func get_output_token_list(_vc: HenVirtualCNode) -> Array:
	return _vc.outputs.map(
		func(x: HenVCInOutData) -> Dictionary:
			return {name = x.name, type = x.type}
	)


static func get_input_token_list(_vc: HenVirtualCNode, _get_name: bool = false) -> Array:
	var input_tokens: Array = []

	for input: HenVCInOutData in _vc.inputs:
		input_tokens.append(get_input_token(_vc, input.id))

	return input_tokens


static func get_input_token(_vc: HenVirtualCNode, _id: int) -> Dictionary:
	var connection: HenVCConnectionData
	var input: HenVCInOutData = _vc.get_input(_id)
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if not input:
		(Engine.get_singleton(&'ToastContainer') as HenToast).notify.call_deferred("Not found input token to generate: id -> " + str(_id), HenToast.MessageType.ERROR)
		return {}

	for input_connection: HenVCConnectionData in global.SAVE_DATA.get_to_connection_from_vc(_vc):
		if input_connection.to_id == _id:
			var output_id_list: Array = input_connection.get_from().outputs.map(func(x): return x.id)
			var input_id_list: Array = input_connection.get_to().inputs.map(func(x): return x.id)

			if not output_id_list.has(input_connection.from_id) or not input_id_list.has(input_connection.to_id):
				continue

			connection = input_connection
			break

	if connection and connection.get_from():
		match connection.get_from().sub_type:
			HenVirtualCNode.SubType.MACRO_INPUT:
				if global.USE_MACRO_REF:
					var data: Dictionary = get_input_token(global.MACRO_REF, connection.from_id)
					return data
			HenVirtualCNode.SubType.MACRO:
				global.USE_MACRO_USE_SELF = true
				global.MACRO_USE_SELF = _vc.route_type != HenRouter.ROUTE_TYPE.STATE
				var data: Dictionary = {}

				if connection.get_from().res:
					data = get_input_token(connection.get_from().res, connection.to_id)
				
				# var data: Dictionary = (connection.get_from().ref.get_ref() as HenTypeMacro).output_ref.get_input_token(connection.to_id)
				global.USE_MACRO_USE_SELF = false
				return data
			_:
				var data: Dictionary = get_token(connection.get_from(), get_output_index(connection.get_from(), connection.from_id))
				
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
			use_self = (_vc.route_type != HenRouter.ROUTE_TYPE.STATE) if not global.USE_MACRO_USE_SELF else global.MACRO_USE_SELF,
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
				'state_transition':
					data.value = '&"{0}"'.format([(data.value as String).to_snake_case()])

		if data.get('is_ref', false) and not data.get('use_self', false):
			if HenUtils.is_type_relation_valid(
					global.SAVE_DATA.identity.type,
					input.type,
				):
					data.ref_value = '_ref'

		return data

	var not_connected: Dictionary = {type = HenVirtualCNode.SubType.NOT_CONNECTED, input_type = input.type, use_self = true, prop_name = input.name}

	if input.is_ref:
		not_connected.set('is_ref', true)

	return not_connected


static func get_output_index(_vc: HenVirtualCNode, _id: int) -> int:
	var idx: int = 0

	for output: HenVCInOutData in _vc.outputs:
		if output.id == _id:
			return idx

		idx += 1

	return 0


static func get_token(_vc: HenVirtualCNode, _id: int = 0) -> Dictionary:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	var token: Dictionary = {
		vc_id = _vc.id,
		type = _vc.sub_type,
		use_self = (_vc.route_type != HenRouter.ROUTE_TYPE.STATE) if not global.USE_MACRO_USE_SELF else global.MACRO_USE_SELF,
	}

	if _vc.category:
		token.category = _vc.category

	if _vc.invalid:
		return INVALID_TOKEN

	match _vc.sub_type:
		HenVirtualCNode.SubType.VOID, HenVirtualCNode.SubType.GO_TO_VOID, HenVirtualCNode.SubType.SELF_GO_TO_VOID:
			token.merge({
				name = _vc.name.to_snake_case() if not _vc.name_to_code else _vc.name_to_code.to_snake_case(),
				params = get_input_token_list(_vc),
				singleton_class = _vc.singleton_class
			})
		HenVirtualCNode.SubType.FUNC, HenVirtualCNode.SubType.USER_FUNC, HenVirtualCNode.SubType.FUNC_FROM:
			if _vc.sub_type == HenVirtualCNode.SubType.FUNC_FROM:
				if not _vc.input_has_connection(_vc.inputs[0].id):
					(Engine.get_singleton(&'CodeGeneration') as HenCodeGeneration).flow_errors.append({})
					return INVALID_TOKEN

			token.merge({
				name = _vc.name.to_snake_case() if not _vc.name_to_code else _vc.name_to_code.to_snake_case(),
				params = get_input_token_list(_vc),
				id = _id if _vc.outputs.size() > 1 else -1,
				singleton_class = _vc.singleton_class
			})
		HenVirtualCNode.SubType.VAR, HenVirtualCNode.SubType.LOCAL_VAR:
			token.merge({
				name = _vc.outputs[0].name.to_snake_case(),
			})
		HenVirtualCNode.SubType.VAR_FROM:
			token.merge({
				ref = get_input_token(_vc, 0),
				name = _vc.outputs[0].name.to_snake_case(),
			})
		HenVirtualCNode.SubType.SET_VAR_FROM:
			token.merge({
				name = _vc.name_to_code.to_snake_case(),
				ref = get_input_token(_vc, 0),
				value = get_input_token(_vc, 1)
			})
		HenVirtualCNode.SubType.SET_VAR, HenVirtualCNode.SubType.SET_LOCAL_VAR:
			token.merge({
				name = _vc.inputs[0].name.to_snake_case(),
				value = get_input_token_list(_vc)[0],
			})
		HenVirtualCNode.SubType.VIRTUAL, HenVirtualCNode.SubType.FUNC_INPUT, HenVirtualCNode.SubType.OVERRIDE_VIRTUAL, HenVirtualCNode.SubType.SIGNAL_ENTER:
			token.merge({
				param = _vc.outputs[_id].name.to_snake_case(),
			})
		HenVirtualCNode.SubType.FOR, HenVirtualCNode.SubType.FOR_ARR:
			return {
				id = _vc.id,
				type = HenVirtualCNode.SubType.FOR_ITEM,
				name = _vc.outputs[0].name.to_snake_case(),
				use_self = true
			}
		HenVirtualCNode.SubType.IMG:
			token.merge({
				name = _vc.name.to_snake_case(),
				params = get_input_token_list(_vc)
			})
		HenVirtualCNode.SubType.RAW_CODE:
			token.merge({
				code = get_input_token_list(_vc)[0],
			})
		HenVirtualCNode.SubType.CONST:
			token.merge({
				singleton_class = _vc.name,
				name = _vc.name_to_code
			})
		HenVirtualCNode.SubType.EXPRESSION:
			# check inputs
			for input: HenVCInOutData in _vc.inputs.slice(1):
				if not _vc.input_has_connection(input.id):
					(Engine.get_singleton(&'CodeGeneration') as HenCodeGeneration).flow_errors.append({})

			token.merge({
				params = get_input_token_list(_vc, true),
				exp = _vc.inputs[0].value
			})
		HenVirtualCNode.SubType.SIGNAL_CONNECTION:
			token.merge({
				params = get_input_token_list(_vc, true),
				signal_name = (_vc.res as HenSaveSignalCallback).signal_name_to_code,
				name = (_vc.res as HenSaveSignalCallback).name
			})
		HenVirtualCNode.SubType.SIGNAL_DISCONNECTION:
			token.merge({
				params = get_input_token_list(_vc, true),
				signal_name = (_vc.res as HenSaveSignalCallback).signal_name_to_code,
				name = (_vc.res as HenSaveSignalCallback).name.to_snake_case()
			})
		HenVirtualCNode.SubType.GET_FROM_PROP:
			if not _vc.input_has_connection(_vc.inputs[0].id):
				(Engine.get_singleton(&'CodeGeneration') as HenCodeGeneration).flow_errors.append({})
				return INVALID_TOKEN
			
			token.merge({
				ref = get_input_token(_vc, 0),
				name = _vc.outputs[0].name.to_snake_case(),
			})

	return token


static func get_virtual_cnode_code(_vc: HenVirtualCNode) -> String:
	var code: String = ''

	for token in HenVirtualCNodeCode.get_flow_tokens(_vc, 0):
		code += HenGeneratorByToken.get_code_by_token(token)

	return code


static func get_default_value_code(_type: String) -> String:
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
				return _type + '.new()'
	
	return 'null'
