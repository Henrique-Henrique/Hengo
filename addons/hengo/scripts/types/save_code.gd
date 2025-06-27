@tool
class_name HenSaveCodeType

const INVALID_TOKEN: Dictionary = {
	type = HenVirtualCNode.SubType.INVALID,
	use_self = false
}


class Variable:
	var name: String
	var type: StringName
	var export_var: bool


class Func:
	var id: int
	var name: String
	var inputs: Array[Param]
	var outputs: Array[Param]
	var virtual_cnode_list: Array[CNode]
	var local_vars: Array[Variable]
	var input_ref: CNode
	var output_ref: CNode


class SignalData:
	var id: int
	var name: String
	var signal_name: String
	var signal_name_to_code: String
	var type: StringName
	var virtual_cnode_list: Array[CNode]
	var params: Array[Param]
	var bind_params: Array[Param]
	var local_vars: Array[Variable]
	var signal_enter: CNode


class Macro:
	var id: int
	var name: String
	var input_ref: CNode
	var flow_inputs: Array[Flow]
	var flow_outputs: Array[Flow]
	var virtual_cnode_list: Array[CNode]
	var local_vars: Array[Variable]
	var macro_ref_list: Array[CNode]


class Flow:
	var id: int
	var name: String

class Param:
	var id: int
	var name: String
	var type: StringName

class Inout:
	var id: int
	var type: StringName
	var category: StringName
	var code_value: String
	var name: String
	var is_ref: bool
	var sub_type: StringName
	var value: Variant
	var data: Variant
	var is_prop: bool
	var is_static: bool


class FlowConnection:
	var id: int
	var from_id: int
	var to_id: int
	var from: CNode
	var to: CNode
	var to_vc_id: int


class InputConnection:
	var from: CNode
	var to: CNode
	var from_id: int
	var to_id: int
	var from_vc_id: int


class References:
	var flow_connections: Array[FlowConnection]
	var input_connections: Array[InputConnection]
	var states: Array[CNode]
	var base_route_cnode_list: Array[CNode]
	var cnode_ref: Dictionary = {}
	var states_data: Dictionary = {}
	var variables: Array[Variable]
	var functions: Array[Func]
	var signals: Array[SignalData]
	var macros: Array[Macro]
	var side_bar_item_ref: Dictionary = {}


#
#
#
#


class CNode:
	var id: int
	var name: String
	var name_to_code: String
	var sub_type: HenVirtualCNode.SubType
	var type: HenVirtualCNode.Type
	var category: StringName
	var virtual_cnode_list: Array[CNode]
	var inputs: Array[Inout]
	var outputs: Array[Inout]
	var flow_connections: Array[FlowConnection]
	var virtual_sub_type_vc_list: Array[CNode]
	var input_connections: Array[InputConnection]
	var route_type: HenRouter.ROUTE_TYPE
	var ref: Variant
	var invalid: bool = false
	var singleton_class: String

	func get_flow_tokens(_input_id: int, _token_list: Array = []) -> Array:
		var stack: Array = []
		var token_list: Array = _token_list

		stack.append({node = self, id = _input_id})

		while not stack.is_empty():
			var current: Dictionary = stack.pop_back()
			var vc: CNode = current.node
			var _id: int = current.id

			if current.has('flow_id'):
				token_list = HenCodeGeneration.flows_refs[current.flow_id]

			match vc.sub_type:
				HenVirtualCNode.SubType.IF:
					token_list.append(vc.get_if_token(stack))
				HenVirtualCNode.SubType.FOR, HenVirtualCNode.SubType.FOR_ARR:
					token_list.append(vc.get_for_token(stack))
				HenVirtualCNode.SubType.MACRO:
					token_list.append(vc.get_macro_token(_id, vc))
				HenVirtualCNode.SubType.MACRO_OUTPUT:
					if HenGlobal.USE_MACRO_REF:
						var flow: FlowConnection = HenGlobal.MACRO_REF.get_flow(_id) if not HenGlobal.MACRO_REF.flow_connections.is_empty() else null

						if flow and flow.to:
							stack.append({node = flow.to, id = flow.to_id})
						
						HenGlobal.USE_MACRO_REF = false
				_:
					token_list.append(vc.get_token())
					
					if not vc.flow_connections.is_empty() and vc.flow_connections[0].to:
						stack.append({node = vc.flow_connections[0].to, id = vc.flow_connections[0].to_id})

		return _token_list

	func get_flow(_id: int) -> FlowConnection:
		for flow: FlowConnection in flow_connections:
			if flow.id == _id:
				return flow
		
		return null


	func get_macro_token(_flow_id: int, _macro_ref: CNode) -> Dictionary:
		if invalid:
			return INVALID_TOKEN

		var flow_tokens: Array
		var input_flow: FlowConnection = ref.input_ref.get_flow(_flow_id)

		if input_flow and input_flow.to:
			HenGlobal.USE_MACRO_REF = true
			HenGlobal.MACRO_REF = self
			HenGlobal.MACRO_USE_SELF = _macro_ref.route_type != HenRouter.ROUTE_TYPE.STATE
			HenGlobal.USE_MACRO_USE_SELF = true
			flow_tokens = input_flow.to.get_flow_tokens(input_flow.to_id)
			HenGlobal.USE_MACRO_USE_SELF = false

		return {
			vc_id = id,
			type = HenVirtualCNode.SubType.MACRO,
			flow_tokens = flow_tokens,
			use_self = false
		}


	func get_if_token(_stack: Array) -> Dictionary:
		var true_flow_id: int = HenCodeGeneration.get_flow_id()
		var false_flow_id: int = HenCodeGeneration.get_flow_id()
		var then_flow_id: int = HenCodeGeneration.get_flow_id()

		HenCodeGeneration.flows_refs[true_flow_id] = []
		HenCodeGeneration.flows_refs[false_flow_id] = []
		HenCodeGeneration.flows_refs[then_flow_id] = []

		for flow: FlowConnection in flow_connections:
			match flow.id:
				0:
					_stack.append({node = flow.to, id = flow.to_id, flow_id = true_flow_id})
				1:
					_stack.append({node = flow.to, id = flow.to_id, flow_id = false_flow_id})
				2:
					_stack.append({node = flow.to, id = flow.to_id, flow_id = then_flow_id})

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
		var body_flow_id: int = HenCodeGeneration.get_flow_id()
		var then_flow_id: int = HenCodeGeneration.get_flow_id()

		HenCodeGeneration.flows_refs[body_flow_id] = []
		HenCodeGeneration.flows_refs[then_flow_id] = []

		for flow: FlowConnection in flow_connections:
			match flow.id:
				0:
					_stack.append({node = flow.to, id = flow.to_id, flow_id = body_flow_id})
				1:
					_stack.append({node = flow.to, id = flow.to_id, flow_id = then_flow_id})

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


	func get_input(_id: int) -> Inout:
		for input: Inout in inputs:
			if input.id == _id:
				return input
		return null


	func get_output(_id: int) -> Inout:
		for output: Inout in outputs:
			if output.id == _id:
				return output
		return null

	func input_has_connection(_id: int) -> bool:
		for input_connection: InputConnection in input_connections:
			if input_connection.to_id == _id:
				return true

		return false

	func get_output_index(_id: int) -> int:
		var idx: int = 0

		for output: Inout in outputs:
			if output.id == _id:
				return idx

			idx += 1

		return 0

	func get_input_token(_id: int) -> Dictionary:
		var connection: InputConnection
		var input: Inout = get_input(_id)

		if not input:
			push_error('Not found input token to generate: id -> ', _id)
			return {}

		for input_connection: InputConnection in input_connections:
			if input_connection.to_id == _id:
				connection = input_connection
				break

		if connection and connection.from:
			match connection.from.sub_type:
				HenVirtualCNode.SubType.MACRO_INPUT:
					if HenGlobal.USE_MACRO_REF:
						var data: Dictionary = HenGlobal.MACRO_REF.get_input_token(connection.from_id)
						return data
				HenVirtualCNode.SubType.MACRO:
					HenGlobal.USE_MACRO_USE_SELF = true
					HenGlobal.MACRO_USE_SELF = route_type != HenRouter.ROUTE_TYPE.STATE
					var data: Dictionary = (connection.from.ref as HenMacroData).output_ref.get_input_token(connection.to_id)
					HenGlobal.USE_MACRO_USE_SELF = false
					return data
				_:
					var data: Dictionary = connection.from.get_token(connection.from.get_output_index(connection.from_id))
					
					if not data.type == HenVirtualCNode.SubType.INVALID:
						data.prop_name = input.name

					if HenGlobal.USE_MACRO_REF:
						if data.has('value'):
							data.value += '_' + str(HenGlobal.MACRO_REF.id)

					if input.is_ref:
						data.is_ref = input.is_ref
					
					return data
		elif input.code_value:
			var data: Dictionary = {
				type = HenVirtualCNode.SubType.IN_PROP,
				prop_name = input.name,
				value = input.code_value,
				use_self = (route_type != HenRouter.ROUTE_TYPE.STATE) if not HenGlobal.USE_MACRO_USE_SELF else HenGlobal.MACRO_USE_SELF,
			}

			if HenGlobal.USE_MACRO_REF:
				if input.category == 'class_props':
					data.value += '_' + str(HenGlobal.MACRO_REF.id)

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
						data.value = '&"{0}"'.format([data.value.to_snake_case()])

			return data

		return {type = HenVirtualCNode.SubType.NOT_CONNECTED, input_type = input.type, use_self = true, prop_name = input.name}


	func get_input_token_list(_get_name: bool = false) -> Array:
		var input_tokens: Array = []

		for input: Inout in inputs:
			input_tokens.append(get_input_token(input.id))

		return input_tokens


	func get_output_token_list() -> Array:
		return outputs.map(
			func(x: Inout) -> Dictionary:
				return {name = x.name, type = x.type}
		)


	func get_token(_id: int = 0) -> Dictionary:
		var token: Dictionary = {
			vc_id = id,
			type = sub_type,
			use_self = (route_type != HenRouter.ROUTE_TYPE.STATE) if not HenGlobal.USE_MACRO_USE_SELF else HenGlobal.MACRO_USE_SELF,
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
			HenVirtualCNode.SubType.VIRTUAL, HenVirtualCNode.SubType.FUNC_INPUT, HenVirtualCNode.SubType.OVERRIDE_VIRTUAL:
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
				for input: Inout in inputs.slice(1):
					if not input_has_connection(input.id):
						HenCodeGeneration.flow_errors.append({})

				token.merge({
					params = get_input_token_list(true),
					exp = inputs[0].value
				})
			HenVirtualCNode.SubType.SIGNAL_CONNECTION:
				token.merge({
					params = get_input_token_list(true),
					signal_name = (ref as SignalData).signal_name_to_code,
					name = (ref as SignalData).name
				})
			HenVirtualCNode.SubType.SIGNAL_DISCONNECTION:
				token.merge({
					params = get_input_token_list(true),
					signal_name = (ref as SignalData).signal_name_to_code,
					name = (ref as SignalData).name.to_snake_case()
				})
			HenVirtualCNode.SubType.GET_FROM_PROP:
				if not input_has_connection(inputs[0].id):
					HenCodeGeneration.flow_errors.append({})
					return INVALID_TOKEN
				
				token.merge({
					ref = get_input_token(inputs[0].id),
					name = outputs[0].name.to_snake_case(),
				})

		return token
