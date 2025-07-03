@tool
class_name HenCodeGeneration extends Node


static var _debug_counter: float = 1.
static var _debug_symbols: Dictionary = {}
static var flow_id: int = 0
static var flows_refs: Dictionary = {}
static var flow_errors: Array[Dictionary] = []

#
#
#
#
#
#
static func _provide_params_ref(_params: Array, _prefix: StringName) -> Array:
	if _params.size() > 0:
		var first: Dictionary = _params[0]

		if first.has('is_ref'):
			var new_prefix: StringName = parse_token_by_type(first)
			return [
				_params.slice(1),
				get_prefix_with_dot(new_prefix)
			]
	
	return [_params, get_prefix_with_dot(_prefix)]

#
#
#
#
#
#
static func get_prefix_with_dot(_prefix: StringName) -> StringName:
	if _prefix != '' and not _prefix.ends_with('.'):
		return _prefix + '.'

	return _prefix

#
#
#
#
#
#
static func _get_signal_call_name(_name: String) -> String:
	return '_on_' + _name.to_snake_case() + '_signal_'

#
#
#
#
#
#
static func get_flow_id() -> int:
	flow_id += 1
	return flow_id

#
#
#
#
#
#
static func generate_and_save(_compile_ref: HBoxContainer) -> void:
	var start: float = Time.get_ticks_usec()
	HenSaver.save(_debug_symbols, true)
	var end: float = Time.get_ticks_usec()
	print('GENERATED AND SAVED HENGO SCRIPT IN -> ', (end - start) / 1000, 'ms.')
	HenGlobal.current_script_debug_symbols = _debug_symbols


#
#
#
#
#
#
static func parse_token_by_type(_token: Dictionary, _level: int = 0, _parent_id: String = '') -> String:
	var indent: StringName = '\t'.repeat(_level)
	var prefix: StringName = '_ref.'
	var preview_id: String = ''

	if HenGlobal.GENERATE_PREVIEW_CODE:
		if _token.has('vc_id'):
			preview_id += '#ID:' + str(_token.vc_id)
		
		if _parent_id:
			preview_id += '#ID:' + _parent_id


	if _token.use_self == true or (_token.has('category') and _token.get('category') == 'native'):
		prefix = ''


	match _token.type as HenVirtualCNode.SubType:
		HenVirtualCNode.SubType.INVALID:
			return indent + 'HengoState.INVALID_PLACEHOLDER'
		HenVirtualCNode.SubType.VAR, HenVirtualCNode.SubType.DEEP_PROP:
			if _token.has('ref'):
				return indent + get_prefix_with_dot(parse_token_by_type(_token.ref)) + _token.name
			return indent + prefix + _token.name
		HenVirtualCNode.SubType.SET_VAR:
			return indent + prefix + '{name} = {value}'.format({
				name = _token.name,
				value = parse_token_by_type(_token.value)
			})
		HenVirtualCNode.SubType.SET_DEEP_PROP:
			return indent + get_prefix_with_dot(parse_token_by_type(_token.ref)) + '{name} = {value}'.format({
				name = _token.name,
				value = parse_token_by_type(_token.value)
			})
		HenVirtualCNode.SubType.SET_LOCAL_VAR:
			return indent + '{name} = {value}'.format({
				name = _token.name,
				value = parse_token_by_type(_token.value)
			})
		HenVirtualCNode.SubType.LOCAL_VAR:
			return indent + _token.name
		HenVirtualCNode.SubType.IN_PROP:
			if _token.has('use_value'):
				if _token.has('ref_value'):
					if _token.use_self: return indent
					else: return indent + _token.ref_value
				else:
					if _token.use_self: return indent + _token.value
					else: return indent + prefix + _token.value

			if _token.has('use_prefix'):
				return indent + prefix + _token.value

			if _token.has('is_prop') and _token.get('is_prop') == true:
				return indent + prefix + _token.value

			return indent + str(_token.value)
		HenVirtualCNode.SubType.VOID, HenVirtualCNode.SubType.GO_TO_VOID, HenVirtualCNode.SubType.SELF_GO_TO_VOID:
			var values: Array = _provide_params_ref(_token.params, prefix)
			var params: Array = values[0]

			prefix = values[1]

			var selfInput: String = ''

			if _token.type == HenVirtualCNode.SubType.SELF_GO_TO_VOID:
				selfInput = 'self, '

			if _token.singleton_class:
				prefix = _token.singleton_class + '.'

			return indent + prefix + '{name}({params}){id}'.format({
				id = preview_id,
				name = _token.name,
				params = selfInput + ', '.join(params.map(
					func(x: Dictionary) -> String:
						return parse_token_by_type(x)
			))
			})
		HenVirtualCNode.SubType.FUNC, HenVirtualCNode.SubType.USER_FUNC, HenVirtualCNode.SubType.FUNC_FROM:
			var values: Array = _provide_params_ref(_token.params, prefix)
			var params: Array = values[0]
			
			prefix = values[1]

			if _token.type == HenVirtualCNode.SubType.FUNC_FROM:
				if prefix == '_ref.':
					# TODO
					return indent + 'Vector2.ZERO'

			if _token.singleton_class:
				prefix = _token.singleton_class + '.'

			return indent + prefix + '{name}({params}){id}{id_preview}'.format({
				id_preview = preview_id,
				name = _token.name,
				id = '[{0}]'.format([_token.id]) if _token.id >= 0 else '',
				params = ', '.join(params.map(
					func(x: Dictionary) -> String:
						return parse_token_by_type(x)
			))
			})
		HenVirtualCNode.SubType.VIRTUAL, HenVirtualCNode.SubType.FUNC_INPUT, HenVirtualCNode.SubType.OVERRIDE_VIRTUAL:
			return _token.param
		HenVirtualCNode.SubType.IF:
			var true_flow = HenCodeGeneration.flows_refs[_token.true_flow_id]
			var false_flow = HenCodeGeneration.flows_refs[_token.false_flow_id]
			var then_flow = HenCodeGeneration.flows_refs[_token.then_flow_id]
			var code_list: Array = []
			var only_false: bool = true_flow.is_empty() and not false_flow.is_empty()
			var if_code: String = 'if {condition}:{id}\n'

			if only_false:
				if_code = 'if not({condition}):{id}\n'

			var base: String = if_code.format({
				condition = parse_token_by_type(_token.condition),
				id = preview_id
			})

			if true_flow.is_empty():
				if only_false:
					for token in false_flow:
						code_list.append(
							parse_token_by_type(token, _level + 1)
						)
				else:
					base += indent + '\tpass\n'
			else:
				for token in true_flow:
					code_list.append(
						parse_token_by_type(token, _level + 1, preview_id)
					)
				
				if not false_flow.is_empty():
					code_list.append(indent + 'else:')
					for token in false_flow:
						code_list.append(
							parse_token_by_type(token, _level + 1, preview_id)
						)

			for token in then_flow:
				code_list.append(
					parse_token_by_type(token, _level)
				)
			if code_list.is_empty():
				if not true_flow.is_empty():
					base += indent + '\tpass'
			else:
				base += '\n'.join(code_list)

			return indent + base
		HenVirtualCNode.SubType.NOT_CONNECTED:
			return 'null'
		HenVirtualCNode.SubType.CONST:
			return indent + _token.singleton_class + '.' + _token.name
		HenVirtualCNode.SubType.FOR, HenVirtualCNode.SubType.FOR_ARR:
			var base: String = ''
			var code_list: Array = []
			var body_flow = HenCodeGeneration.flows_refs[_token.body_flow_id]
			var then_flow = HenCodeGeneration.flows_refs[_token.then_flow_id]
			var loop_item: String = _token.index_name + '_' + str(_token.id)

			if _token.type == HenVirtualCNode.SubType.FOR:
				base = 'for {item_name} in range({params}):{id}\n'.format({
					item_name = loop_item,
					params = ', '.join(_token.params.map(
						func(x: Dictionary) -> String:
							return parse_token_by_type(x)
				)),
					id = preview_id
				})
			else:
				base = 'for {item_name} in {arr}:{id}\n'.format({
					item_name = loop_item,
					arr = parse_token_by_type(_token.params[0]),
					id = preview_id
				})
			
			if body_flow.is_empty():
				base += indent + '\tpass'
			else:
				for token: Dictionary in body_flow:
					code_list.append(parse_token_by_type(token, _level + 1, preview_id))
			
			for token: Dictionary in then_flow:
				code_list.append(parse_token_by_type(token, _level))

			if code_list.is_empty():
				if not body_flow.is_empty():
					base += indent + '\tpass'
			else:
				base += '\n'.join(code_list)

			return indent + base
		HenVirtualCNode.SubType.FOR_ITEM:
			return _token.name + '_' + str(_token.id)
		HenVirtualCNode.SubType.BREAK:
			# TODO check break and continue if is inside for loop
			return indent + 'break'
		HenVirtualCNode.SubType.CONTINUE:
			return indent + 'continue'
		HenVirtualCNode.SubType.IMG:
			return '{a} {op} {b}'.format({
				a = parse_token_by_type(_token.params[0]),
				op = _token.name,
				b = parse_token_by_type(_token.params[1])
			})
		HenVirtualCNode.SubType.DEBUG:
			return indent + HenGlobal.DEBUG_TOKEN + HenGlobal.DEBUG_VAR_NAME + ' += ' + str(_token.counter)
		HenVirtualCNode.SubType.DEBUG_STATE:
			return indent + HenGlobal.DEBUG_TOKEN + "EngineDebugger.send_message('hengo:debug_state', [" + str(_token.id) + "])"
		HenVirtualCNode.SubType.START_DEBUG_STATE:
			return indent + "EngineDebugger.send_message('hengo:debug_state', [" + str(_token.id) + "])"
		HenVirtualCNode.SubType.DEBUG_VALUE:
			return indent + HenGlobal.DEBUG_TOKEN + "EngineDebugger.send_message('hengo:debug_value', [" + str(_token.id) + ", var_to_str(" + parse_token_by_type(_token.value) + ")])"
		HenVirtualCNode.SubType.PASS:
			return indent + 'pass'
		HenVirtualCNode.SubType.RAW_CODE:
			return _token.code.value.trim_prefix('"').trim_suffix('"')
		HenVirtualCNode.SubType.EXPRESSION:
			var new_exp: String = _token.exp
			var reg: RegEx = RegEx.new()

			for param in _token.params.slice(1):
				reg.compile("\\b" + param.prop_name + "\\b")
				new_exp = reg.sub(new_exp, parse_token_by_type(param), true)
			
			return new_exp
		HenVirtualCNode.SubType.SIGNAL_CONNECTION:
			var values: Array = _provide_params_ref(_token.params, prefix)
			var params: Array = values[0]
			var my_prefix = values[1]

			if not params.is_empty():
				return indent + '{ref}connect("{signal_name}", {call_ref}{callable}.bind({params}))'.format({
					ref = my_prefix,
					params = ', '.join(params.map(func(x: Dictionary) -> String:
						return parse_token_by_type(x))),
					signal_name = _token.signal_name,
					call_ref = prefix,
					callable = _get_signal_call_name(_token.name)
				})

			return indent + '{ref}connect("{signal_name}", {call_ref}{callable})'.format({
				ref = my_prefix,
				signal_name = _token.signal_name,
				call_ref = prefix,
				callable = _get_signal_call_name(_token.name)
			})
		HenVirtualCNode.SubType.SIGNAL_DISCONNECTION:
			var values: Array = _provide_params_ref(_token.params, prefix)
			var params: Array = values[0]
			var my_prefix = values[1]

			return indent + '{ref}disconnect("{signal_name}", {call_ref}{callable})'.format({
				ref = my_prefix,
				signal_name = _token.signal_name,
				call_ref = prefix,
				callable = _get_signal_call_name(_token.name)
			})
		HenVirtualCNode.SubType.MACRO:
			return '\n'.join(_token.flow_tokens.map(func(x: Dictionary) -> String: return parse_token_by_type(x, _level, preview_id)))
		HenVirtualCNode.SubType.GET_FROM_PROP:
			return indent + parse_token_by_type(_token.ref) + '.' + _token.name
		_:
			return ''

#
#
#
#
#
#
static func get_code(_data: HenScriptData, _build_preview: bool = false) -> String:
	var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()
	var code: String = ''

	HenGlobal.GENERATE_PREVIEW_CODE = _build_preview
	HenCodeGeneration.flow_errors.clear()


	# generating macro references
	for macro_data: Dictionary in _data.side_bar_list.macro_list:
		var macro: HenSaveCodeType.Macro = HenSaveCodeType.Macro.new()

		macro.id = macro_data.id
		macro.name = macro_data.name

		refs.side_bar_item_ref[macro.id] = macro

		for input: Dictionary in macro_data.inputs:
			var flow: HenSaveCodeType.Flow = HenSaveCodeType.Flow.new()
			flow.id = input.id
			flow.name = input.name
			macro.flow_inputs.append(flow)

		for output: Dictionary in macro_data.outputs:
			var flow: HenSaveCodeType.Flow = HenSaveCodeType.Flow.new()
			flow.id = output.id
			flow.name = output.name
			macro.flow_outputs.append(flow)

		if macro_data.has(&'local_vars'):
			for local_var: Dictionary in macro_data.local_vars:
				macro.local_vars.append(_get_variable_from_dict(local_var))

		if macro_data.has(&'virtual_cnode_list'):
			for cnode: Dictionary in macro_data.virtual_cnode_list:
				macro.virtual_cnode_list.append(_get_cnode_from_dict(cnode, refs, macro))

		refs.macros.append(macro)

	# generating variables references
	for variable_data: Dictionary in _data.side_bar_list.var_list:
		if variable_data.has('invalid') and not variable_data.invalid:
			continue

		var variable: HenVarData = HenVarData.new()
		
		variable.id = variable_data.id
		variable.name = variable_data.name
		variable.type = variable_data.type
		variable.export = variable_data.export

		refs.side_bar_item_ref[variable.id] = variable
		refs.variables.append(_get_variable_from_dict(variable_data))

	# generating function references
	for func_data: Dictionary in _data.side_bar_list.func_list:
		_parse_function_dict(func_data, refs)

	# generating macro references
	for signal_data: Dictionary in _data.side_bar_list.signal_list:
		_parse_signal_dict(signal_data, refs)


	# generating cnode references
	for cnode: Dictionary in _data.virtual_cnode_list:
		var cn: HenSaveCodeType.CNode = _get_cnode_from_dict(cnode, refs)

		refs.base_route_cnode_list.append(cn)

		if cnode.has(&'virtual_cnode_list'):
			for cnode_chd: Dictionary in cnode.virtual_cnode_list:
				cn.virtual_cnode_list.append(_get_cnode_from_dict(cnode_chd, refs, cn))


	_parse_connections(refs)

	code += _get_start(_data)
	code += _parse_variables(refs)
	code += _parse_functions(refs)
	code += _parse_signals(refs)
	code += _set_base_cnodes(refs)

	return code

#
#
#
#
#
#
static func _parse_function_dict(_func_data: Dictionary, _refs: HenSaveCodeType.References) -> HenSaveCodeType.Func:
	var function: HenSaveCodeType.Func = HenSaveCodeType.Func.new()

	function.id = _func_data.id
	function.name = _func_data.name

	_refs.side_bar_item_ref[function.id] = function

	for input: Dictionary in _func_data.inputs:
		function.inputs.append(_get_param_from_dict(input))

	for output: Dictionary in _func_data.outputs:
		function.outputs.append(_get_param_from_dict(output))

	if _func_data.has(&'local_vars'):
		for local_var: Dictionary in _func_data.local_vars:
			function.local_vars.append(_get_variable_from_dict(local_var))

	if _func_data.has(&'virtual_cnode_list'):
		for cnode: Dictionary in _func_data.virtual_cnode_list:
			function.virtual_cnode_list.append(_get_cnode_from_dict(cnode, _refs, function))
	
	_refs.functions.append(function)

	return function

#
#
#
#
#
#
static func _parse_signal_dict(_signal_data: Dictionary, _refs: HenSaveCodeType.References) -> HenSaveCodeType.SignalData:
	var signal_item: HenSaveCodeType.SignalData = HenSaveCodeType.SignalData.new()

	signal_item.id = _signal_data.id
	signal_item.name = _signal_data.name
	signal_item.type = _signal_data.type
	signal_item.signal_name = _signal_data.signal_name
	signal_item.signal_name_to_code = _signal_data.signal_name_to_code

	_refs.side_bar_item_ref[signal_item.id] = signal_item

	for param: Dictionary in _signal_data.params:
		signal_item.params.append(_get_param_from_dict(param))

	for param: Dictionary in _signal_data.bind_params:
		signal_item.bind_params.append(_get_param_from_dict(param))

	if _signal_data.has(&'local_vars'):
		for local_var: Dictionary in _signal_data.local_vars:
			signal_item.local_vars.append(_get_variable_from_dict(local_var))

	if _signal_data.has(&'virtual_cnode_list'):
		for cnode: Dictionary in _signal_data.virtual_cnode_list:
			signal_item.virtual_cnode_list.append(_get_cnode_from_dict(cnode, _refs, signal_item))

	_refs.signals.append(signal_item)

	return signal_item

#
#
#
#
#
#
static func _parse_connections(_refs: HenSaveCodeType.References) -> void:
	# generatin flow connection references
	for connection: HenSaveCodeType.FlowConnection in _refs.flow_connections:
		var cnode: HenSaveCodeType.CNode = _refs.cnode_ref[connection.to_vc_id]
		connection.to = cnode
		connection.from.flow_connections.append(connection)

	# generating input connection references
	for connection: HenSaveCodeType.InputConnection in _refs.input_connections:
		connection.from = _refs.cnode_ref[connection.from_vc_id]
		connection.to.input_connections.append(connection)

#
#
#
#
#
#
static func _get_variable_from_dict(_data: Dictionary) -> HenSaveCodeType.Variable:
	var variable: HenSaveCodeType.Variable = HenSaveCodeType.Variable.new()
		
	variable.name = _data.name
	variable.type = _data.type
	variable.export_var = _data.export

	return variable

#
#
#
#
#
#
static func _get_param_from_dict(_data: Dictionary) -> HenSaveCodeType.Param:
	var param: HenSaveCodeType.Param = HenSaveCodeType.Param.new()

	param.name = _data.name
	param.type = _data.type

	return param

#
#
#
#
#
#
static func _get_cnode_from_dict(_cnode: Dictionary, _refs: HenSaveCodeType.References, _parent_ref = null) -> HenSaveCodeType.CNode:
	var cn: HenSaveCodeType.CNode = HenSaveCodeType.CNode.new()

	cn.id = _cnode.id
	cn.name = _cnode.name
	cn.sub_type = _cnode.sub_type
	cn.type = _cnode.type

	_refs.cnode_ref[cn.id] = cn
	
	if _cnode.has(&'singleton_class'):
		cn.singleton_class = _cnode.singleton_class

	if _cnode.has(&'invalid'):
		cn.invalid = _cnode.invalid

	if _cnode.has(&'ref_id'):
		if not cn.invalid:
			cn.ref = _refs.side_bar_item_ref[_cnode.ref_id]

	if _cnode.has(&'category'):
		cn.category = _cnode.category
	
	if _cnode.has(&'name_to_code'):
		cn.name_to_code = _cnode.name_to_code
	
	if _cnode.has('flow_connections'):
		for connection: Dictionary in _cnode.flow_connections:
			var fc: HenSaveCodeType.FlowConnection = HenSaveCodeType.FlowConnection.new()

			fc.from = cn

			fc.id = connection.id
			fc.from_id = connection.from_id
			fc.to_id = connection.to_id
			fc.to_vc_id = connection.to_vc_id


			_refs.flow_connections.append(fc)

	if _cnode.has('input_connections'):
		for connection: Dictionary in _cnode.input_connections:
			var input_connection: HenSaveCodeType.InputConnection = HenSaveCodeType.InputConnection.new()

			input_connection.from_id = connection.from_id
			input_connection.to_id = connection.to_id
			input_connection.to = cn
			input_connection.from_vc_id = connection.from_vc_id

			_refs.input_connections.append(input_connection)

	if _cnode.has('inputs'):
		for input_data: Dictionary in _cnode.inputs:
			cn.inputs.append(_get_inout_from_dict(input_data))

	if _cnode.has('outputs'):
		for input_data: Dictionary in _cnode.outputs:
			cn.outputs.append(_get_inout_from_dict(input_data))

	# setting route types
	if _parent_ref:
		if _parent_ref is HenSaveCodeType.CNode and _parent_ref.type == HenVirtualCNode.Type.STATE:
			cn.route_type = HenRouter.ROUTE_TYPE.STATE
		elif _parent_ref is HenSaveCodeType.Func:
			cn.route_type = HenRouter.ROUTE_TYPE.FUNC

			match cn.sub_type:
				HenVirtualCNode.SubType.FUNC_INPUT:
					_parent_ref.input_ref = cn
				HenVirtualCNode.SubType.FUNC_OUTPUT:
					_parent_ref.output_ref = cn
		elif _parent_ref is HenSaveCodeType.SignalData:
			cn.route_type = HenRouter.ROUTE_TYPE.SIGNAL

			if cn.sub_type == HenVirtualCNode.SubType.SIGNAL_ENTER:
				_parent_ref.signal_enter = cn
		elif _parent_ref is HenSaveCodeType.Macro:
			cn.route_type = HenRouter.ROUTE_TYPE.MACRO

			if cn.sub_type == HenVirtualCNode.SubType.MACRO_INPUT:
				_parent_ref.input_ref = cn


	match cn.type:
		HenVirtualCNode.Type.STATE:
			cn.route_type = HenRouter.ROUTE_TYPE.BASE
			_refs.states.append(cn)
		HenVirtualCNode.Type.MACRO:
			if not cn.invalid:
				(cn.ref as HenSaveCodeType.Macro).macro_ref_list.append(cn)
	
	match cn.sub_type:
		HenVirtualCNode.SubType.VIRTUAL:
			if _parent_ref:
				_parent_ref.virtual_sub_type_vc_list.append(cn)

	return cn

#
#
#
#
#
#
static func _get_inout_from_dict(_inout: Dictionary) -> HenSaveCodeType.Inout:
	var input: HenSaveCodeType.Inout = HenSaveCodeType.Inout.new()

	input.id = _inout.id
	input.name = _inout.name
	input.type = _inout.type

	if _inout.has('sub_type'): input.sub_type = _inout.sub_type
	if _inout.has('category'): input.category = _inout.category
	if _inout.has('is_ref'): input.is_ref = _inout.is_ref
	if _inout.has('code_value'): input.code_value = _inout.code_value
	if _inout.has('value'): input.value = _inout.value
	if _inout.has('data'): input.data = _inout.data
	if _inout.has('is_prop'): input.is_prop = _inout.is_prop
	if _inout.has('is_static'): input.is_static = _inout.is_static

	return input

# GENERATE
# GENERATE
# GENERATE
# GENERATE
# GENERATE
# GENERATE
# GENERATE
# GENERATE
# GENERATE
# GENERATE
# GENERATE
# GENERATE

#
#
#
#
#
#
static func _get_start(_data: HenScriptData) -> String:
	# reseting macro use self condition
	HenGlobal.USE_MACRO_USE_SELF = false
	HenGlobal.USE_MACRO_REF = false

	return '# ***************************************************************
# *                 CREATED BY HENGO VISUAL SCRIPT              *
# *    This file is automatically generated and maintained by   *
# *               the Hengo Visual Script tool.                 *
# *       Edit only if you are confident in your changes.       *
# ***************************************************************\n\nextends {0}\n\n'.format([_data.type])

#
#
#
#
#
#
static func _parse_variables(_refs: HenSaveCodeType.References) -> String:
	var var_code: String =''

	for var_data: HenSaveCodeType.Variable in _refs.variables:
		var_code += _generate_var_code(var_data)

	return var_code + ' \n' if var_code else ''

#
#
#
#
#
#
static func _generate_var_code(_var_data: HenSaveCodeType.Variable, _custom_name: String = '', _preview_id: String = '') -> String:
	var var_code: String = ''
	var type_value: String = 'null'

	if HenEnums.VARIANT_TYPES.has(_var_data.type):
		if _var_data.type == 'Variant':
			type_value = 'null'
		else:
			type_value = _var_data.type + '()'
	elif ClassDB.can_instantiate(_var_data.type):
		type_value = _var_data.type + '.new()'

	var_code += '{export_var}var {name} = {value}{id}\n'.format({
		name = _var_data.name.to_snake_case() if not _custom_name else _custom_name,
		value = type_value,
		export_var = '@export ' if _var_data.export_var else '',
		id = '#ID:' + _preview_id if _preview_id else ''
	})

	return var_code

#
#
#
#
#
#
static func _set_base_cnodes(_refs: HenSaveCodeType.References) -> String:
	var code: String = ''
	var start_state: HenSaveCodeType.CNode
	var override_virtual_data: Dictionary = {}
	var events: Array[Dictionary] = []

	# getting states
	for cnode: HenSaveCodeType.CNode in _refs.base_route_cnode_list:
		match cnode.sub_type:
			# getting start state cnode
			HenVirtualCNode.SubType.STATE_START:
				if not cnode.flow_connections.is_empty():
					start_state = cnode.flow_connections[0].to
			HenVirtualCNode.SubType.STATE:
				var transitions: Array = []

				# getting transition
				for flow_connection: HenSaveCodeType.FlowConnection in cnode.flow_connections:
					if flow_connection.to:
						transitions.append({
							name = 'flow_connection.name',
							to_state_name = flow_connection.to.name
						})

				_refs.states_data[cnode.name.to_snake_case()] = {
					virtual_tokens = _parse_virtual_cnode(cnode.virtual_sub_type_vc_list),
					transitions = transitions
				}
			HenVirtualCNode.SubType.STATE_EVENT:
				if not cnode.flow_connections.is_empty() and cnode.flow_connections[0].to:
					events.append({
						name = cnode.name,
						to_state_name = cnode.flow_connections[0].to.name
					})
			HenVirtualCNode.SubType.OVERRIDE_VIRTUAL:
				if not cnode.flow_connections.is_empty() and cnode.flow_connections[0].to:
					if not override_virtual_data.has(cnode.name):
						override_virtual_data[cnode.name] = {
							params = cnode.get_output_token_list(),
							tokens = []
						}

					override_virtual_data[cnode.name].tokens.append_array(cnode.flow_connections[0].to.get_flow_token_list(0))


	# search for override virtual inside macros
	for macro: HenSaveCodeType.Macro in _refs.macros:
		# macro variables
		for macro_var: HenSaveCodeType.Variable in macro.local_vars:
			for macro_ref: HenSaveCodeType.CNode in macro.macro_ref_list:
				code += _generate_var_code(macro_var, '{name}_{id}'.format({name = macro_var.name.to_snake_case(), id = macro_ref.id}), str(macro_ref.id))

		# macro override virtuals
		for v_cnode: HenSaveCodeType.CNode in macro.virtual_cnode_list:
			if v_cnode.sub_type == HenVirtualCNode.SubType.OVERRIDE_VIRTUAL:
				for macro_ref: HenSaveCodeType.CNode in macro.macro_ref_list:
					HenGlobal.USE_MACRO_REF = true
					HenGlobal.MACRO_REF = macro_ref
					HenGlobal.MACRO_USE_SELF = macro_ref.route_type != HenRouter.ROUTE_TYPE.STATE
					HenGlobal.USE_MACRO_USE_SELF = true

					if v_cnode.flow_connections[0].to:
						if not override_virtual_data.has(v_cnode.name):
							override_virtual_data[v_cnode.name] = {
								params = v_cnode.get_output_token_list(),
								tokens = []
							}

						for token: Dictionary in v_cnode.flow_connections[0].to.get_flow_tokens(0):
							token.vc_id = macro_ref.id
							override_virtual_data[v_cnode.name].tokens.append(token)

					HenGlobal.USE_MACRO_REF = false


	var ready_code: Array = []
	var process_code: Array = []
	var physics_process_code: Array = []

	for key: StringName in override_virtual_data.keys():
		var item = override_virtual_data.get(key)

		match key:
			&'_ready':
				for token: Dictionary in item.tokens:
					var _code: String = parse_token_by_type(token, 1)
					if _code: ready_code.append(_code)
			&'_process':
				for token: Dictionary in item.tokens:
					var _code: String = parse_token_by_type(token, 1)
					if _code: process_code.append(_code)
			&'_physics_process':
				for token: Dictionary in item.tokens:
					var _code: String = parse_token_by_type(token, 1)
					if _code: physics_process_code.append(_code)


	return code + """var _STATE_CONTROLLER = HengoStateController.new()

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
{states}""".format({
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
		states_dict = _parse_states_dict(_refs),
		states = _parse_states(_refs)
	})

#
#
#
#
#
#
static func _parse_states_dict(_refs: HenSaveCodeType.References) -> String:
	var code: String = ''

	# parsing dictionaries
	if not _refs.states_data.is_empty():
		code += ',\n'.join(_refs.states_data.keys().map(
				func(state_name: String) -> String:
					return '\t\t{key}={c_name}.new(self{transitions})'.format({
						key = state_name,
						c_name = state_name.to_pascal_case(),
						transitions = ', {\n\t\t\t' + ',\n\t\t\t'.join(_refs.states_data[state_name].transitions.map(
						func(trans: Dictionary) -> String:
						return '{state_name}="{to_state_name}"'.format({
							state_name = trans.name.to_snake_case(),
							to_state_name = trans.to_state_name.to_snake_case()
						})
						)) + '\n\t\t}' if _refs.states_data[state_name].transitions.size() > 0 else ''
					})
		))
	
	return code

#
#
#
#
#
#
static func _parse_states(_refs: HenSaveCodeType.References) -> String:
	var code: String = ''

	# generating classes implementation
	for state_name in _refs.states_data.keys():
		var item = _refs.states_data[state_name]

		var base = 'class {name} extends HengoState:\n'.format({
			name = state_name.to_pascal_case()
		})

		if item.virtual_tokens.is_empty():
			base += '\tpass'
			code += base
			continue

		var idx: int = 0

		for virtual_name in item.virtual_tokens.keys():
			var func_tokens = item.virtual_tokens[virtual_name].tokens
			var func_params = item.virtual_tokens[virtual_name].params

			if func_tokens.is_empty():
				continue

			var func_base: String = '{new_line}\tfunc {name}({params}) -> void:\n'.format({
				name = virtual_name,
				new_line = '\n\n' if idx > 0 else '',
				params = ', '.join(func_params.map(
					func(x: Dictionary) -> String:
						return x.name
				
			))
			})

			var func_codes: Array = []

			for token in func_tokens:
				func_codes.append(
					parse_token_by_type(token, 2)
				)
		
			func_base += '\n'.join(func_codes)
			base += func_base
			idx += 1

		code += base

	return code

#
#
#
#
#
#
static func _parse_functions(_refs: HenSaveCodeType.References) -> String:
	var func_code: String = ''

	for func_data: HenSaveCodeType.Func in _refs.functions:
		# generating function
		func_code += 'func {name}({params}):\n'.format({
			name = func_data.name.to_snake_case(),
			params = ', '.join(func_data.inputs.map(
				func(x: HenSaveCodeType.Param) -> String:
					return x.name.to_snake_case()
		))
		})
		
		# local variable
		func_code += '\n'.join(func_data.local_vars.map(func(x: HenSaveCodeType.Variable):
			return '\t' + _generate_var_code(x)))

		# func output (return)
		var output_code: Array = []
		
		for token: Dictionary in func_data.output_ref.get_input_token_list():
			output_code.append(parse_token_by_type(token))

		if not func_data.input_ref.flow_connections.is_empty() and func_data.input_ref.flow_connections[0].to:
			var func_tokens: Array = func_data.input_ref.flow_connections[0].to.get_flow_tokens(
				func_data.input_ref.flow_connections[0].to_id
			)
			var func_block: Array = []

			for token in func_tokens:
				func_block.append(parse_token_by_type(token, 1))

			func_code += '\n'.join(func_block)
		else:
			func_code += '\tpass\n\n' if func_data.local_vars.is_empty() and output_code.is_empty() else ''
		
	# 	#TODO output when not connected return empty field, make a default values for all types
		if output_code.size() == 1:
			func_code += '\treturn {output}\n\n'.format({
				output = ', '.join(output_code)
			})
		elif not output_code.is_empty():
			func_code += '\treturn [{outputs}]\n\n'.format({
				outputs = ', '.join(output_code)
			})
		
		func_code += '\n'
		# end func output
	
	return func_code

#
#
#
#
#
#
static func _parse_signals(_refs: HenSaveCodeType.References) -> String:
	var signal_code: String = ''

	for signal_item: HenSaveCodeType.SignalData in _refs.signals:
		var signal_name = _get_signal_call_name(signal_item.name)

		signal_code += 'func {name}({params}):\n'.format({
			name = signal_name,
			params = ', '.join(signal_item.params.map( # parsing raw inputs from signal
			func(x: HenSaveCodeType.Param) -> String:
				return x.name.to_snake_case()
		# parsing custom inputs
		) + signal_item.bind_params.map(
				func(x: HenSaveCodeType.Param) -> String:
					return x.name.to_snake_case()
		))
		})

		# local variable
		signal_code += '\n'.join(signal_item.local_vars.map(func(x: HenSaveCodeType.Variable):
			return '\t' + _generate_var_code(x)))

		if not signal_item.signal_enter.flow_connections.is_empty() and signal_item.signal_enter.flow_connections[0].to:
			var signal_tokens: Array = signal_item.signal_enter.flow_connections[0].to.get_flow_tokens(
				signal_item.signal_enter.flow_connections[0].to_id
			)
			var signal_block: Array = []

			for token in signal_tokens:
				signal_block.append(parse_token_by_type(token, 1))
			
			signal_code += '\n'.join(signal_block)
		else:
			signal_code += '\tpass\n\n'
	
	return signal_code

#
#
#
#
#
#
static func _parse_virtual_cnode(_cnode_list: Array[HenSaveCodeType.CNode]) -> Dictionary:
	var data: Dictionary = {}

	for cnode: HenSaveCodeType.CNode in _cnode_list:
		if cnode.flow_connections.is_empty():
			continue
		
		var cnode_name: String = cnode.name
		var from_flow: HenSaveCodeType.FlowConnection = cnode.flow_connections[0]

		if from_flow.to:
			var token_list = from_flow.to.get_flow_tokens(from_flow.to_id)

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

#
#
#
#
#
#
class RegenerateRefs:
	var reload: bool = false: set = can_reload
	var cnode_list: Dictionary = {}
	var disconnect_list: Array = []
	var counter: int

	func get_new_node_counter() -> int:
		counter += 1
		return counter

	func can_reload(_can: bool) -> void:
		if reload == true:
			return
		
		reload = _can

#
#
#
#
#
#
static func regenerate() -> Array:
	var saves: Array = []

	# generation dependencies
	if HenGlobal.FROM_REFERENCES.references.get(HenGlobal.script_config.id) is Array:
		for id: int in HenGlobal.FROM_REFERENCES.references.get(HenGlobal.script_config.id):
			var refs: RegenerateRefs = RegenerateRefs.new()
			var path: StringName = HenLoader.get_data_path(id)

			if not FileAccess.file_exists(path):
				push_warning('Error: resource not found to re-generate: ', str(id))
				continue
			
			var res: HenScriptData = ResourceLoader.load('res://hengo/save/' + str(id) + '.res')

			refs.counter = res.node_counter

			_parse_vc_list(res.virtual_cnode_list, refs)

			if refs.reload:
				# cleaning connections that dont using
				for cnode: Dictionary in refs.cnode_list.values():
					var remove_connections: Array = []

					if not cnode.input_connections.is_empty():
						for connection: Dictionary in cnode.input_connections:
							for ref: Dictionary in refs.disconnect_list:
								if ref.id == connection.from_vc_id and ref.output_id == connection.from_id:
									remove_connections.append(connection)
									break

					for connection: Dictionary in remove_connections:
						cnode.input_connections.erase(connection)

				res.node_counter = refs.counter

				saves.append(HenSaver.SaveDependency.new(
					res,
					HenSaver.generate(res, res.resource_path, ResourceUID.get_id_path(id))
				))

	
	return saves

#
#
#
#
#
#
static func _parse_vc_list(_cnode_list: Array, _refs: RegenerateRefs) -> void:
	for cnode: Dictionary in _cnode_list:
		_refs.cnode_list[cnode.id] = cnode

		if not cnode.has('from_id'):
			if cnode.has(&'virtual_cnode_list'):
				_parse_vc_list(cnode.virtual_cnode_list, _refs)
			continue

		match cnode.sub_type:
			HenVirtualCNode.SubType.GET_FROM_PROP:
				_check_changes_var(cnode, _refs)
			HenVirtualCNode.SubType.FUNC_FROM:
				_check_changes_func(cnode, _refs)

		if cnode.has(&'virtual_cnode_list'):
			_parse_vc_list(cnode.virtual_cnode_list, _refs)

#
#
#
#
#
#
static func _check_changes_var(_dict: Dictionary, _refs: RegenerateRefs) -> void:
	var output: Dictionary = _dict.outputs[0]
	
	var var_data: HenVarData

	for _var_data: HenVarData in HenGlobal.SIDE_BAR_LIST.var_list:
		if _var_data.id == _dict.from_side_bar_id:
			var_data = _var_data
			break

	if var_data:
		if var_data.name != output.name or var_data.type != output.type:
			output.name = var_data.name

			if output.type != var_data.type:
				output.type = var_data.type

				_refs.disconnect_list.append({
					id = _dict.id,
					output_id = output.id,
				})

			_refs.reload = true
	else:
		if not _dict.has('invalid') or _dict.has('invalid') and not _dict.invalid:
			_dict.invalid = true
			_refs.reload = true

#
#
#
#
#
#
static func _check_changes_func(_dict: Dictionary, _refs: RegenerateRefs) -> void:
	var func_data: HenFuncData

	for _func_data: HenFuncData in HenGlobal.SIDE_BAR_LIST.func_list:
		if _func_data.id == _dict.from_side_bar_id:
			func_data = _func_data
			break
	
	if func_data:
		var real_output_size: int = func_data.outputs.size()
		var real_input_size: int = func_data.inputs.size()
		var output_size: int = _dict.outputs.size() if _dict.has('outputs') else 0
		var input_size: int = _dict.inputs.size() - 1 if _dict.has('inputs') else 0

		_check_func_inouts(true, func_data, _dict, input_size, real_input_size, _refs)
		_check_func_inouts(false, func_data, _dict, output_size, real_output_size, _refs)

	else:
		if not _dict.has('invalid') or _dict.has('invalid') and not _dict.invalid:
			_dict.invalid = true
			_refs.reload = true

#
#
#
#
#
#
static func _reset_inout_dict_value(_dict: Dictionary) -> void:
	match _dict.type:
		'String', 'NodePath', 'StringName':
			_dict.code_value = '""'
		'int':
			_dict.code_value = '0'
		'float':
			_dict.code_value = '0.'
		'Vector2':
			_dict.code_value = 'Vector2(0, 0)'
		'bool':
			_dict.code_value = 'false'
		'Variant':
			_dict.code_value = 'null'
		_:
			if HenEnums.VARIANT_TYPES.has(_dict.type):
				_dict.code_value = _dict.type + '()'
			elif ClassDB.can_instantiate(_dict.type):
				_dict.code_value = _dict.type + '.new()'

	match _dict.type:
		'String', 'NodePath', 'StringName':
			_dict.value = ''
		_:
			_dict.value = _dict.code_value
	
#
#
#
#
#
#
static func _check_func_inouts(
	_is_inputs: bool,
	_func_data: HenFuncData,
	_dict: Dictionary,
	_output_size: int,
	_real_output_size: int,
	_refs: RegenerateRefs
) -> void:
	var func_arr: Array = _func_data.outputs if not _is_inputs else _func_data.inputs
	var arr: Array

	if _is_inputs:
		if _dict.has('inputs'):
			arr = _dict.inputs
		elif _real_output_size > 0:
			_dict.inputs = []
			arr = _dict.inputs
		else:
			return
	else:
		if _dict.has('outputs'):
			arr = _dict.outputs
		elif _real_output_size > 0:
			_dict.outputs = []
			arr = _dict.outputs
		else:
			return


	var old_map: Dictionary = {}
	
	for inout: Dictionary in arr:
		if inout.has('is_ref'):
			continue
		
		old_map[inout.from_id] = {
			id = inout.id,
			type = inout.type
		}
	

	if arr.is_empty():
		for new_inout: HenParamData in func_arr:
			arr.append({
				id = _refs.get_new_node_counter(),
				name = new_inout.name,
				type = new_inout.type,
				from_id = new_inout.id
			})
		
			# _refs.reload = true
	else:
		var idx: int = 0
		var remove: Array = []
		var inout_size: int = arr.size() if not _is_inputs else arr.size() - 1

		# add the news inouts
		if func_arr.size() > inout_size:
			for i in range(func_arr.size() - inout_size):
				var data: Dictionary = func_arr[inout_size + i].get_save_with_from_id()
				data.id = _refs.get_new_node_counter()
				arr.append(data)
			
			# _refs.reload = true

		# change current inouts
		for new_inout: Dictionary in arr:
			if new_inout.has('is_ref'):
				continue

			if idx >= func_arr.size():
				remove.append(new_inout)
				_refs.disconnect_list.append({
					id = _dict.id,
					output_id = new_inout.id
				})
				# _refs.reload = true
				continue

			var inout_ref: HenParamData = func_arr[idx]
			new_inout.merge(inout_ref.get_save_without_id(), true)
			
			if old_map.has(new_inout.from_id):
				var old: Dictionary = old_map[new_inout.from_id]
				new_inout.id = old.id

				# check input connections
				if old.type != new_inout.type:
					if _is_inputs and _dict.has('input_connections'):
						for connection: Dictionary in _dict.input_connections:
							_refs.disconnect_list.append({
								id = connection.from_vc_id,
								output_id = connection.from_id
							})
					else:
						_refs.disconnect_list.append({
							id = _dict.id,
							output_id = old.id
						})
					
					if _is_inputs: _reset_inout_dict_value(new_inout)
					
			new_inout.from_id = inout_ref.id
			idx += 1
		
		for inout: Dictionary in remove:
			arr.erase(inout)
