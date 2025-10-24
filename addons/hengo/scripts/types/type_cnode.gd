@tool
class_name HenTypeCnode extends RefCounted

const INVALID_TOKEN: Dictionary = {
	type = HenVirtualCNode.SubType.INVALID,
	use_self = false
}

var id: int
var name: String
var name_to_code: String
var sub_type: HenVirtualCNode.SubType
var type: HenVirtualCNode.Type
var category: StringName
var virtual_cnode_list: Array[HenTypeCnode]
var inputs: Array[HenTypeInout]
var outputs: Array[HenTypeInout]
var flow_connections: Array[HenTypeFlowConnection]
var virtual_sub_type_vc_list: Array[HenTypeCnode]
var input_connections: Array[HenTypeInputConnection]
var route_type: HenRouter.ROUTE_TYPE
var ref: WeakRef
var invalid: bool = false
var singleton_class: String


func get_flow_tokens(_input_id: int, _token_list: Array = []) -> Array:
	var stack: Array = []
	var token_list: Array = _token_list

	stack.append({node = self, id = _input_id})

	while not stack.is_empty():
		var current: Dictionary = stack.pop_back()
		var vc: HenTypeCnode = current.node
		var _id: int = current.id

		if current.has('flow_id'):
			token_list = (Engine.get_singleton(&'CodeGeneration') as HenCodeGeneration).flows_refs[current.flow_id]

		match vc.sub_type:
			HenVirtualCNode.SubType.IF:
				token_list.append(vc.get_if_token(stack))
			HenVirtualCNode.SubType.FOR, HenVirtualCNode.SubType.FOR_ARR:
				token_list.append(vc.get_for_token(stack))
			HenVirtualCNode.SubType.MACRO:
				token_list.append(vc.get_macro_token(_id, vc))
			HenVirtualCNode.SubType.MACRO_OUTPUT:
				var global: HenGlobal = Engine.get_singleton(&'Global')
				if global.USE_MACRO_REF:
					var flow: HenTypeFlowConnection = global.MACRO_REF.get_flow_connection(_id) if not global.MACRO_REF.flow_connections.is_empty() else null

					if flow and flow.get_to():
						stack.append({node = flow.get_to(), id = flow.to_id})
					
					global.USE_MACRO_REF = false
			_:
				token_list.append(vc.get_token())
				
				if not vc.flow_connections.is_empty() and vc.flow_connections[0].get_to():
					stack.append({node = vc.flow_connections[0].get_to(), id = vc.flow_connections[0].to_id})

	return _token_list


func get_flow_connection(_id: int) -> HenTypeFlowConnection:
	for flow: HenTypeFlowConnection in flow_connections:
		if flow.from_id == _id:
			return flow
	
	return null


func get_macro_token(_flow_id: int, _macro_ref: HenTypeCnode) -> Dictionary:
	if invalid:
		return INVALID_TOKEN

	var flow_tokens: Array
	var input_flow: HenTypeFlowConnection = (ref.get_ref().input_ref as HenTypeCnode).get_flow_connection(_flow_id)

	if input_flow and input_flow.to:
		var global: HenGlobal = Engine.get_singleton(&'Global')
		global.USE_MACRO_REF = true
		global.MACRO_REF = self
		global.MACRO_USE_SELF = _macro_ref.route_type != HenRouter.ROUTE_TYPE.STATE
		global.USE_MACRO_USE_SELF = true
		flow_tokens = input_flow.get_to().get_flow_tokens(input_flow.to_id)
		global.USE_MACRO_USE_SELF = false

	return {
		vc_id = id,
		type = HenVirtualCNode.SubType.MACRO,
		flow_tokens = flow_tokens,
		use_self = false
	}


func get_if_token(_stack: Array) -> Dictionary:
	var code_generation: HenCodeGeneration = Engine.get_singleton(&'CodeGeneration')

	var true_flow_id: int = code_generation.get_flow_id()
	var false_flow_id: int = code_generation.get_flow_id()
	var then_flow_id: int = code_generation.get_flow_id()

	code_generation.flows_refs[true_flow_id] = []
	code_generation.flows_refs[false_flow_id] = []
	code_generation.flows_refs[then_flow_id] = []

	for flow: HenTypeFlowConnection in flow_connections:
		match flow.from_id:
			0:
				_stack.append({node = flow.get_to(), id = flow.to_id, flow_id = true_flow_id})
			1:
				_stack.append({node = flow.get_to(), id = flow.to_id, flow_id = false_flow_id})
			2:
				_stack.append({node = flow.get_to(), id = flow.to_id, flow_id = then_flow_id})

	return {
		vc_id = id,
		type = HenVirtualCNode.SubType.IF,
		true_flow_id = true_flow_id,
		false_flow_id = false_flow_id,
		then_flow_id = then_flow_id,
		condition = get_input_token(inputs[0].id),
		use_self = false
	}


func get_for_token(_stack: Array) -> Dictionary:
	var code_generation: HenCodeGeneration = Engine.get_singleton(&'CodeGeneration')

	var body_flow_id: int = code_generation.get_flow_id()
	var then_flow_id: int = code_generation.get_flow_id()

	code_generation.flows_refs[body_flow_id] = []
	code_generation.flows_refs[then_flow_id] = []

	for flow: HenTypeFlowConnection in flow_connections:
		match flow.from_id:
			0:
				_stack.append({node = flow.get_to(), id = flow.to_id, flow_id = body_flow_id})
			1:
				_stack.append({node = flow.get_to(), id = flow.to_id, flow_id = then_flow_id})

	return {
		id = id,
		vc_id = id,
		type = sub_type,
		body_flow_id = body_flow_id,
		then_flow_id = then_flow_id,
		params = get_input_token_list(),
		index_name = outputs[0].name.to_snake_case(),
		use_self = false
	}


func get_input(_id: int) -> HenTypeInout:
	for input: HenTypeInout in inputs:
		if input.id == _id:
			return input
	return null


func get_output(_id: int) -> HenTypeInout:
	for output: HenTypeInout in outputs:
		if output.id == _id:
			return output
	return null

func input_has_connection(_id: int) -> bool:
	for input_connection: HenTypeInputConnection in input_connections:
		if input_connection.to_id == _id:
			return true

	return false

func get_output_index(_id: int) -> int:
	var idx: int = 0

	for output: HenTypeInout in outputs:
		if output.id == _id:
			return idx

		idx += 1

	return 0

func get_input_token(_id: int) -> Dictionary:
	var connection: HenTypeInputConnection
	var input: HenTypeInout = get_input(_id)
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if not input:
		(Engine.get_singleton(&'SignalBus') as HenSignalBus).set_terminal_text.emit.call_deferred(HenUtils.get_error_text("Not found input token to generate: id -> " + str(_id)))
		return {}

	for input_connection: HenTypeInputConnection in input_connections:
		if input_connection.to_id == _id:
			connection = input_connection
			break

	if connection and connection.from:
		match connection.get_from().sub_type:
			HenVirtualCNode.SubType.MACRO_INPUT:
				if global.USE_MACRO_REF:
					var data: Dictionary = global.MACRO_REF.get_input_token(connection.from_id)
					return data
			HenVirtualCNode.SubType.MACRO:
				global.USE_MACRO_USE_SELF = true
				global.MACRO_USE_SELF = route_type != HenRouter.ROUTE_TYPE.STATE
				var data: Dictionary = (connection.get_from().ref.get_ref() as HenTypeMacro).output_ref.get_input_token(connection.to_id)
				global.USE_MACRO_USE_SELF = false
				return data
			_:
				var data: Dictionary = connection.get_from().get_token(connection.get_from().get_output_index(connection.from_id))
				
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
			use_self = (route_type != HenRouter.ROUTE_TYPE.STATE) if not global.USE_MACRO_USE_SELF else global.MACRO_USE_SELF,
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

		return data

	return {type = HenVirtualCNode.SubType.NOT_CONNECTED, input_type = input.type, use_self = true, prop_name = input.name}


func get_input_token_list(_get_name: bool = false) -> Array:
	var input_tokens: Array = []

	for input: HenTypeInout in inputs:
		input_tokens.append(get_input_token(input.id))

	return input_tokens


func get_output_token_list() -> Array:
	return outputs.map(
		func(x: HenTypeInout) -> Dictionary:
			return {name = x.name, type = x.type}
	)


func get_token(_id: int = 0) -> Dictionary:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var token: Dictionary = {
		vc_id = id,
		type = sub_type,
		use_self = (route_type != HenRouter.ROUTE_TYPE.STATE) if not global.USE_MACRO_USE_SELF else global.MACRO_USE_SELF,
	}

	if category:
		token.category = category

	if invalid:
		return INVALID_TOKEN

	match sub_type:
		HenVirtualCNode.SubType.VOID, HenVirtualCNode.SubType.GO_TO_VOID, HenVirtualCNode.SubType.SELF_GO_TO_VOID:
			token.merge({
				name = name.to_snake_case() if not name_to_code else name_to_code.to_snake_case(),
				params = get_input_token_list(),
				singleton_class = singleton_class
			})
		HenVirtualCNode.SubType.FUNC, HenVirtualCNode.SubType.USER_FUNC, HenVirtualCNode.SubType.FUNC_FROM:
			if sub_type == HenVirtualCNode.SubType.FUNC_FROM:
				if not input_has_connection(inputs[0].id):
					(Engine.get_singleton(&'CodeGeneration') as HenCodeGeneration).flow_errors.append({})
					return INVALID_TOKEN

			token.merge({
				name = name.to_snake_case() if not name_to_code else name_to_code.to_snake_case(),
				params = get_input_token_list(),
				id = _id if outputs.size() > 1 else -1,
				singleton_class = singleton_class
			})
		HenVirtualCNode.SubType.VAR, HenVirtualCNode.SubType.LOCAL_VAR:
			token.merge({
				name = outputs[0].name.to_snake_case(),
			})
		HenVirtualCNode.SubType.DEEP_PROP:
			if inputs.is_empty():
				token.merge({
					name = name_to_code.to_snake_case()
				})
			else:
				token.merge({
					ref = get_input_token(0),
					name = name_to_code.to_snake_case()
				})
		HenVirtualCNode.SubType.SET_DEEP_PROP:
			token.merge({
				name = name_to_code.to_snake_case(),
				ref = get_input_token(0),
				value = get_input_token(1)
			})
		HenVirtualCNode.SubType.SET_VAR, HenVirtualCNode.SubType.SET_LOCAL_VAR:
			token.merge({
				name = inputs[0].name.to_snake_case(),
				value = get_input_token_list()[0],
			})
		HenVirtualCNode.SubType.VIRTUAL, HenVirtualCNode.SubType.FUNC_INPUT, HenVirtualCNode.SubType.OVERRIDE_VIRTUAL, HenVirtualCNode.SubType.SIGNAL_ENTER:
			token.merge({
				param = outputs[_id].name.to_snake_case(),
			})
		HenVirtualCNode.SubType.FOR, HenVirtualCNode.SubType.FOR_ARR:
			return {
				id = id,
				type = HenVirtualCNode.SubType.FOR_ITEM,
				name = outputs[0].name.to_snake_case(),
				use_self = true
			}
		HenVirtualCNode.SubType.IMG:
			token.merge({
				name = name.to_snake_case(),
				params = get_input_token_list()
			})
		HenVirtualCNode.SubType.RAW_CODE:
			token.merge({
				code = get_input_token_list()[0],
			})
		HenVirtualCNode.SubType.CONST:
			token.merge({
				singleton_class = name,
				name = name_to_code
			})
		HenVirtualCNode.SubType.EXPRESSION:
			# check inputs
			for input: HenTypeInout in inputs.slice(1):
				if not input_has_connection(input.id):
					(Engine.get_singleton(&'CodeGeneration') as HenCodeGeneration).flow_errors.append({})

			token.merge({
				params = get_input_token_list(true),
				exp = inputs[0].value
			})
		HenVirtualCNode.SubType.SIGNAL_CONNECTION:
			token.merge({
				params = get_input_token_list(true),
				signal_name = (ref.get_ref() as HenTypeSignalCallbackData).signal_name_to_code,
				name = (ref.get_ref() as HenTypeSignalCallbackData).name
			})
		HenVirtualCNode.SubType.SIGNAL_DISCONNECTION:
			token.merge({
				params = get_input_token_list(true),
				signal_name = (ref.get_ref() as HenTypeSignalCallbackData).signal_name_to_code,
				name = (ref.get_ref() as HenTypeSignalCallbackData).name.to_snake_case()
			})
		HenVirtualCNode.SubType.GET_FROM_PROP:
			if not input_has_connection(inputs[0].id):
				(Engine.get_singleton(&'CodeGeneration') as HenCodeGeneration).flow_errors.append({})
				return INVALID_TOKEN
			
			token.merge({
				ref = get_input_token(inputs[0].id),
				name = outputs[0].name.to_snake_case(),
			})

	return token
