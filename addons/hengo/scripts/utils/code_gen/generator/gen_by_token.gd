class_name HenGeneratorByToken extends RefCounted


static func _provide_params_ref(_params: Array, _prefix: StringName) -> Array:
	if _params.size() > 0:
		var first: Dictionary = _params[0]

		if first.has('is_ref'):
			var new_prefix: StringName = get_code_by_token(first)

			return [
				_params.slice(1),
				get_prefix_with_dot(new_prefix)
			]
	
	return [_params, get_prefix_with_dot(_prefix)]


static func get_prefix_with_dot(_prefix: StringName) -> StringName:
	if _prefix != '' and not _prefix.ends_with('.'):
		return _prefix + '.'

	return _prefix


static func get_code_by_token(_token: Dictionary, _level: int = 0, _parent_id: String = '') -> String:
	var indent: StringName = '\t'.repeat(_level)
	var prefix: StringName = '_ref.'
	var preview_id: String = ''

	if (Engine.get_singleton(&'Global') as HenGlobal).GENERATE_PREVIEW_CODE:
		if _token.has('vc_id'):
			preview_id += '#ID:' + str(_token.vc_id)
		
		if _parent_id:
			preview_id += '#ID:' + _parent_id

	if _token.get('use_self', false) == true or (_token.has('category') and _token.get('category') == 'native'):
		prefix = ''


	match _token.type as HenVirtualCNode.SubType:
		HenVirtualCNode.SubType.INVALID:
			return indent + 'HengoState.INVALID_PLACEHOLDER'
		HenVirtualCNode.SubType.VAR, HenVirtualCNode.SubType.VAR_FROM:
			if _token.has('ref'):
				return indent + get_prefix_with_dot(get_code_by_token(_token.ref)) + _token.name
			return indent + prefix + _token.name
		HenVirtualCNode.SubType.SET_VAR:
			return indent + prefix + '{name} = {value}'.format({
				name = _token.name,
				value = get_code_by_token(_token.value)
			})
		HenVirtualCNode.SubType.SET_VAR_FROM:
			return indent + get_code_by_token(_token.ref) + '{name} = {value}'.format({
				name = _token.name,
				value = get_code_by_token(_token.value)
			})
		HenVirtualCNode.SubType.SET_LOCAL_VAR:
			return indent + '{name} = {value}'.format({
				name = _token.name,
				value = get_code_by_token(_token.value)
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
						return get_code_by_token(x)
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
						return get_code_by_token(x)
			))
			})
		HenVirtualCNode.SubType.VIRTUAL, HenVirtualCNode.SubType.FUNC_INPUT, HenVirtualCNode.SubType.OVERRIDE_VIRTUAL, HenVirtualCNode.SubType.SIGNAL_ENTER:
			return _token.param
		HenVirtualCNode.SubType.IF:
			var code_generation: HenCodeGeneration = Engine.get_singleton(&'CodeGeneration')
			var true_flow = code_generation.flows_refs[_token.true_flow_id]
			var false_flow = code_generation.flows_refs[_token.false_flow_id]
			var then_flow = code_generation.flows_refs[_token.then_flow_id]
			var code_list: Array = []
			var only_false: bool = true_flow.is_empty() and not false_flow.is_empty()
			var if_code: String = 'if {condition}:{id}\n'

			if only_false:
				if_code = 'if not({condition}):{id}\n'

			var base: String = if_code.format({
				condition = get_code_by_token(_token.condition),
				id = preview_id
			})

			if true_flow.is_empty():
				if only_false:
					for token in false_flow:
						code_list.append(
							get_code_by_token(token, _level + 1)
						)
				else:
					base += indent + '\tpass\n'
			else:
				for token in true_flow:
					code_list.append(
						get_code_by_token(token, _level + 1, preview_id)
					)
				
				if not false_flow.is_empty():
					code_list.append(indent + 'else:')
					for token in false_flow:
						code_list.append(
							get_code_by_token(token, _level + 1, preview_id)
						)

			for token in then_flow:
				code_list.append(
					get_code_by_token(token, _level)
				)
			if code_list.is_empty():
				if not true_flow.is_empty():
					base += indent + '\tpass'
			else:
				base += '\n'.join(code_list)

			return indent + base
		HenVirtualCNode.SubType.NOT_CONNECTED:
			return HenVirtualCNodeCode.get_default_value_code(_token.input_type)
		HenVirtualCNode.SubType.CONST:
			return indent + _token.singleton_class + '.' + _token.name
		HenVirtualCNode.SubType.FOR, HenVirtualCNode.SubType.FOR_ARR:
			var base: String = ''
			var code_list: Array = []
			var code_generation: HenCodeGeneration = Engine.get_singleton(&'CodeGeneration')
			var body_flow = code_generation.flows_refs[_token.body_flow_id]
			var then_flow = code_generation.flows_refs[_token.then_flow_id]
			var loop_item: String = _token.index_name + '_' + str(_token.id)

			if _token.type == HenVirtualCNode.SubType.FOR:
				base = 'for {item_name} in range({params}):{id}\n'.format({
					item_name = loop_item,
					params = ', '.join(_token.params.map(
						func(x: Dictionary) -> String:
							return get_code_by_token(x)
				)),
					id = preview_id
				})
			else:
				base = 'for {item_name} in {arr}:{id}\n'.format({
					item_name = loop_item,
					arr = get_code_by_token(_token.params[0]),
					id = preview_id
				})
			
			if body_flow.is_empty():
				base += indent + '\tpass'
			else:
				for token: Dictionary in body_flow:
					code_list.append(get_code_by_token(token, _level + 1, preview_id))
			
			for token: Dictionary in then_flow:
				code_list.append(get_code_by_token(token, _level))

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
				a = get_code_by_token(_token.params[0]),
				op = _token.name,
				b = get_code_by_token(_token.params[1])
			})
		HenVirtualCNode.SubType.PASS:
			return indent + 'pass'
		HenVirtualCNode.SubType.RAW_CODE:
			return _token.code.value.trim_prefix('"').trim_suffix('"')
		HenVirtualCNode.SubType.EXPRESSION:
			var new_exp: String = _token.exp
			var reg: RegEx = RegEx.new()

			for param in _token.params.slice(1):
				reg.compile("\\b" + param.prop_name + "\\b")
				new_exp = reg.sub(new_exp, get_code_by_token(param), true)
			
			return new_exp
		HenVirtualCNode.SubType.SIGNAL_CONNECTION:
			var values: Array = _provide_params_ref(_token.params, prefix)
			var params: Array = values[0]
			var my_prefix = values[1]

			if not params.is_empty():
				return indent + '{ref}connect("{signal_name}", {call_ref}{callable}.bind({params}))'.format({
					ref = my_prefix,
					params = ', '.join(params.map(func(x: Dictionary) -> String:
						return get_code_by_token(x))),
					signal_name = _token.signal_name,
					call_ref = prefix,
					callable = HenGeneratorSignalCallback.get_signal_call_name(_token.name)
				})

			return indent + '{ref}connect("{signal_name}", {call_ref}{callable})'.format({
				ref = my_prefix,
				signal_name = _token.signal_name,
				call_ref = prefix,
				callable = HenGeneratorSignalCallback.get_signal_call_name(_token.name)
			})
		HenVirtualCNode.SubType.SIGNAL_DISCONNECTION:
			var values: Array = _provide_params_ref(_token.params, prefix)
			var params: Array = values[0]
			var my_prefix = values[1]

			return indent + '{ref}disconnect("{signal_name}", {call_ref}{callable})'.format({
				ref = my_prefix,
				signal_name = _token.signal_name,
				call_ref = prefix,
				callable = HenGeneratorSignalCallback.get_signal_call_name(_token.name)
			})
		HenVirtualCNode.SubType.MACRO:
			return '\n'.join(_token.flow_tokens.map(func(x: Dictionary) -> String: return get_code_by_token(x, _level, preview_id)))
		HenVirtualCNode.SubType.GET_FROM_PROP:
			return indent + get_code_by_token(_token.ref) + '.' + _token.name
		_:
			return ''