@tool
class_name HenCodeGeneration extends Node

# references
static var _name_list: Array = []
static var _name_counter: int = 0
static var _name_ref: Dictionary = {}
# debug
static var _debug_counter: float = 1.
static var _debug_symbols: Dictionary = {}


static func generate_and_save(_compile_ref: HBoxContainer) -> void:
	var start: float = Time.get_ticks_usec()
	HenSaveLoad.save(generate(), _debug_symbols)
	var end: float = Time.get_ticks_usec()
	
	print('GENERATED AND SAVED HENGO SCRIPT IN -> ', (end - start) / 1000, 'ms.')
	print('debug  => ', _debug_symbols)

	HenGlobal.current_script_debug_symbols = _debug_symbols


static func generate() -> String:
	# reseting internal variables
	_name_list = []
	_name_counter = 0
	_name_ref = {}
	_debug_counter = 1.
	_debug_symbols = {}

	var code: String = 'extends {0}\n\n'.format([HenGlobal.script_config.type])

	# variables
	var var_code: String = '# Variables #\n'


	for variable in HenGlobal.PROPS_CONTAINER.get_values().variables:
		var var_name: String = variable.name
		var var_type: String = variable.type
		var var_export: bool = variable. export

		var type_value: String = 'null'

		if HenEnums.VARIANT_TYPES.has(var_type):
			if var_type == 'Variant':
				type_value = 'null'
			else:
				type_value = var_type + '()'
		elif ClassDB.can_instantiate(var_type):
			type_value = var_type + '.new()'

		var_code += '{export_var}var {name} = {value}\n'.format({
			name = var_name.to_snake_case(),
			value = type_value,
			export_var = '@export ' if var_export else ''
		})

	code += var_code
	# end variables

	#region Parsing generals
	var input_data: Dictionary = {}

	for general in HenGlobal.GENERAL_CONTAINER.get_children():
		match general.type:
			'input':
				var tokens: Dictionary = parse_tokens(general.virtual_cnode_list)

				if not tokens.is_empty():
					input_data[general.get_general_name()] = tokens.values()[0]


	var states_data: Dictionary = {}
	#endregion

	# base template
	#TODO not all nodes has _process or _physics_process, make more dynamic
	var base_template = """\nvar _STATE_CONTROLLER = HengoStateController.new()

func _init() -> void:
	_STATE_CONTROLLER.set_states({
{states_dict}
	})


func go_to_event(_obj_ref: Node, _state_name: StringName) -> void:
	_obj_ref._STATE_CONTROLLER.change_state(_state_name)


func _ready() -> void:
	if not _STATE_CONTROLLER.current_state:
		{start_state_debug}
		_STATE_CONTROLLER.change_state("{start_state_name}")


func _process(delta: float) -> void:
	_STATE_CONTROLLER.static_process(delta)
{_process}


func _physics_process(delta: float) -> void:
	_STATE_CONTROLLER.static_physics_process(delta)
{_physics_process}

{_input}

{_shortcut_input}

{_unhandled_input}

{_unhandled_key_input}""".format({
		start_state_name = HenGlobal.start_state.get_state_name().to_snake_case(),
		start_state_debug = parse_token_by_type({type = HenCnode.SUB_TYPE.START_DEBUG_STATE, id = get_state_debug_counter(HenGlobal.start_state)}),
		_input = 'func _input(event: InputEvent) -> void:\n' + '\n'.join(input_data['Input'].tokens.map(func(x: Dictionary): return parse_token_by_type(x, 1))) if input_data.has('Input') else '',
		_shortcut_input = 'func _shortcut_input(event: InputEvent) -> void:\n' + '\n'.join(input_data['Shortcut Input'].tokens.map(func(x: Dictionary): return parse_token_by_type(x, 1))) if input_data.has('Shortcut Input') else '',
		_unhandled_input = 'func _unhandled_input(event: InputEvent) -> void:\n' + '\n'.join(input_data['Unhandled Input'].tokens.map(func(x: Dictionary): return parse_token_by_type(x, 1))) if input_data.has('Unhandled Input') else '',
		_unhandled_key_input = 'func _unhandled_key_input(event: InputEvent) -> void:\n' + '\n'.join(input_data['Unhandled Key Input'].tokens.map(func(x: Dictionary): return parse_token_by_type(x, 1))) if input_data.has('Unhandled Key Input') else '',
		_process = '\n'.join(input_data['Process'].tokens.map(func(x: Dictionary): return parse_token_by_type(x, 1))) if input_data.has('Process') else '',
		_physics_process = '\n'.join(input_data['Physics Process'].tokens.map(func(x: Dictionary): return parse_token_by_type(x, 1))) if input_data.has('Physics Process') else '',
	})

	# functions
	var func_code: String = '# Functions\n'

	for func_item in HenGlobal.ROUTE_REFERENCE_CONTAINER.get_children().filter(func(x) -> bool: return x.type == HenRouteReference.TYPE.FUNC):
		var func_name: String = func_item.props[0].value

		func_code += 'func {name}({params}):\n'.format({
			name = func_name.to_snake_case(),
			params = ', '.join(func_item.props[1].value.map(
				func(x: Dictionary) -> String:
					return x.name
		))
		})

		# debug
		func_code += '\t' + get_debug_var_start()
		
		# local variable
		var local_var_list: Array = []

		if not local_var_list.is_empty():
			func_code += '\n'.join(local_var_list) + '\n\n'
		
		# end local variable

		# func output (return)
		var output_code: Array = []
		
		for token in get_cnode_inputs(func_item.output_cnode):
			output_code.append(parse_token_by_type(token))

		var func_flow_to: Dictionary = func_item.virtual_cnode_list[0].flow_to

		if func_flow_to.has('cnode'):
			var func_tokens: Array = flow_tree_explorer(func_item.virtual_cnode_list[0].flow_to.cnode)
			var func_block: Array = []

			for token in func_tokens:
				func_block.append(parse_token_by_type(token, 1))

			# debug
			func_block.append(parse_token_by_type(
				get_debug_token(func_item.virtual_cnode_list[0]),
				1
			))

			func_code += '\n'.join(func_block) + '\n'
			func_code += '\t' + get_debug_push_str() + '\n'
		else:
			func_code += '\tpass\n\n' if local_var_list.is_empty() and output_code.is_empty() else ''
		
		#TODO output when not connected return empty field, make a default values for all types
		if output_code.size() == 1:
			func_code += '\treturn {output}\n\n'.format({
				output = ', '.join(output_code)
			})
		elif not output_code.is_empty():
			func_code += '\treturn [{outputs}]\n\n'.format({
				outputs = ', '.join(output_code)
			})
		# end func output
	
	base_template += func_code
	# end functions


	# parsing all states
	for state in HenGlobal.STATE_CONTAINER.get_children():
		var state_code_tokens = parse_tokens(state.virtual_cnode_list)
		var state_name = state.get_state_name().to_snake_case()
		var transitions: Array = []

		# transitions
		for trans in state.get_node('%TransitionContainer').get_children():
			if trans.line:
				transitions.append({
					name = trans.get_transition_name(),
					to_state_name = trans.line.to_state.get_state_name().to_snake_case()
				})

		states_data[state_name] = {
			virtual_tokens = state_code_tokens,
			transitions = transitions
		}

	# parsing base template
	# adding states and transitions
	base_template = base_template.format({
		states_dict = ',\n'.join(states_data.keys().map(
			func(state_name: String) -> String:
				return '\t\t{key}={c_name}.new(self{transitions})'.format({
					key = state_name,
					c_name = state_name.to_pascal_case(),
					transitions = ', {\n\t\t\t' + ',\n\t\t\t'.join(states_data[state_name].transitions.map(
					func(trans: Dictionary) -> String:
					return '{state_name}="{to_state_name}"'.format({
						state_name = trans.name.to_snake_case(),
						to_state_name = trans.to_state_name
					})
					)) + '\n\t\t}' if states_data[state_name].transitions.size() > 0 else ''
				})
	)),
		first_state = states_data.keys()[0]
	})

	code += base_template

	# generating classes implementation
	for state_name in states_data.keys():
		var item = states_data[state_name]

		var base = 'class {name} extends HengoState:\n'.format({
			name = state_name.to_pascal_case()
		})

		if item.virtual_tokens.is_empty():
			base += '\tpass\n\n'
			code += base
			continue

		for virtual_name in item.virtual_tokens.keys():
			var func_tokens = item.virtual_tokens[virtual_name].tokens
			var func_params = item.virtual_tokens[virtual_name].params

			if func_tokens.is_empty():
				continue

			var func_base: String = '\tfunc {name}({params}) -> void:\n'.format({
				name = virtual_name,
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
			
			func_base += '\n'.join(func_codes) + '\n\n'
			base += func_base

		code += base + '\n\n'

	return code

static func parse_tokens(_virtual_cnode_list: Array) -> Dictionary:
	var data: Dictionary = {}

	for virtual_cnode in _virtual_cnode_list:
		var cnode_name: String = virtual_cnode.get_cnode_name()

		if virtual_cnode.flow_to.has('cnode'):
			var token_list = [get_debug_flow_start_token(virtual_cnode)] + flow_tree_explorer(virtual_cnode.flow_to.cnode)
			token_list.append(get_debug_token(virtual_cnode))
			token_list.append(get_push_debug_token(virtual_cnode))

			if cnode_name == 'enter':
				token_list.append({type = HenCnode.SUB_TYPE.DEBUG_STATE, id = get_state_debug_counter(virtual_cnode.route_ref.state_ref)})
			
			data[cnode_name] = {
				tokens = token_list,
				params = get_cnode_outputs(virtual_cnode)
			}
		else:
			if cnode_name == 'enter':
				data[cnode_name] = {
					tokens = [ {type = HenCnode.SUB_TYPE.DEBUG_STATE, id = get_state_debug_counter(virtual_cnode.route_ref.state_ref)}, {type = HenCnode.SUB_TYPE.PASS}],
					params = []
				}

	return data

static func flow_tree_explorer(_node: HenCnode, _token_list: Array = []) -> Array:
	match _node.type:
		HenCnode.TYPE.IF:
			_token_list.append(get_if_token(_node))
		HenCnode.SUB_TYPE.FOR, HenCnode.SUB_TYPE.FOR_ARR:
			_token_list.append(get_for_token(_node))
		_:
			_token_list.append(parse_cnode_values(_node))

			if not _node.flow_to.is_empty():
				flow_tree_explorer(_node.flow_to.cnode, _token_list)

	return _token_list

# getting cnode outputs
static func get_cnode_outputs(_node: HenCnode) -> Array:
	var outputs = []

	for output in _node.get_node('%OutputContainer').get_children():
		outputs.append({
			name = output.get_node('%Name').text,
			type = output.connection_type
		})
	
	return outputs

# getting cnode inputs values
static func get_cnode_inputs(_node: HenCnode, _get_name: bool = false) -> Array:
	var input_container = _node.get_node('%InputContainer')
	var inputs = []

	for input in input_container.get_children():
		inputs.append(get_input_value(input, _get_name))
	
	return inputs


static func get_input_value(_input, _get_name: bool = false) -> Dictionary:
	if _input.in_connected_from and not _input.from_connection_lines[0].deleted:
		var data: Dictionary = parse_cnode_values(_input.in_connected_from, _input.out_from_in_out.get_index())

		if _input.is_ref:
			data['ref'] = true

		if _get_name:
			data['prop_name'] = _input.get_in_out_name()

		return data
	else:
		# if not has connection, check if has prop input (like string, int, etc)
		var cname_input = _input.get_node('%CNameInput')
		if cname_input.get_child_count() > 2:
			var prop = cname_input.get_child(2)
			var prop_data: Dictionary = {
				type = HenCnode.SUB_TYPE.IN_PROP,
				value = ''
			}

			if _input.is_ref:
				prop_data['ref'] = true

			if _get_name:
				prop_data['prop_name'] = _input.get_in_out_name()

			if prop is Label:
				if prop.text == 'self':
					prop_data.value = '_ref'
				else:
					prop_data.value = prop.text
			else:
				prop_data.value = str(prop.get_generated_code())

			if prop is HenDropdown:
				match prop.type:
					'all_props':
						prop_data['is_prop'] = true
						prop_data['use_self'] = false
					'callable':
						prop_data['use_prefix'] = true
			else:
				if _input.root.route_ref.type != HenRouter.ROUTE_TYPE.STATE \
				or not _input.is_ref:
					prop_data.use_self = true


			return prop_data
		else:
			# if input don't have a connection
			return {sub_type = HenCnode.SUB_TYPE.NOT_CONNECTED, type = _input.connection_type}

# parsing cnode code base on type
static func parse_cnode_values(_node: HenCnode, _id: int = 0) -> Dictionary:
	var use_self: bool = _node.route_ref.type != HenRouter.ROUTE_TYPE.STATE

	var token: Dictionary = {
		type = _node.sub_type,
		use_self = use_self,
	}

	if _node.category:
		token.category = _node.category

	match _node.sub_type:
		HenCnode.SUB_TYPE.VOID, HenCnode.SUB_TYPE.GO_TO_VOID, HenCnode.SUB_TYPE.SELF_GO_TO_VOID:
			token.merge({
				name = _node.get_cnode_name().to_snake_case(),
				params = get_cnode_inputs(_node)
			})
		HenCnode.SUB_TYPE.FUNC, HenCnode.SUB_TYPE.USER_FUNC:
			token.merge({
				name = _node.get_cnode_name().to_snake_case(),
				params = get_cnode_inputs(_node),
				id = _id if _node.get_node('%OutputContainer').get_child_count() > 1 else -1,
			})
		HenCnode.SUB_TYPE.VAR, HenCnode.SUB_TYPE.LOCAL_VAR:
			token.merge({
				name = _node.get_node('%OutputContainer').get_child(0).get_in_out_name().to_snake_case(),
			})
		HenCnode.SUB_TYPE.DEBUG_VALUE:
			token.merge({
				value = get_cnode_inputs(_node)[0],
				id = get_debug_counter(_node)
			})
		HenCnode.SUB_TYPE.SET_VAR, HenCnode.SUB_TYPE.SET_LOCAL_VAR:
			token.merge({
				name = _node.get_node('%InputContainer').get_child(0).get_in_out_name().to_snake_case(),
				value = get_cnode_inputs(_node)[0],
			})
		HenCnode.SUB_TYPE.VIRTUAL, HenCnode.SUB_TYPE.FUNC_INPUT, 'signal_virtual':
			token.merge({
				param = _node.get_node('%OutputContainer').get_child(_id).get_node('%Name').text,
				id = _id
			})
		'signal_connection', 'signal_disconnection', 'signal_emit':
			token.merge({
				route = _node.route_ref,
				params = get_cnode_inputs(_node),
				item_ref = _node.data.item_ref,
				object_name = _node.data.object_name,
				signal_name = _node.data.signal_name
			})
		HenCnode.SUB_TYPE.FOR, HenCnode.SUB_TYPE.FOR_ARR:
			return {
				type = 'for_item',
				hash = _node.get_instance_id()
			}
		HenCnode.SUB_TYPE.CAST:
			return {
				type = _node.sub_type,
				to = _node.get_node('%OutputContainer').get_child(0).connection_type,
				from = get_input_value(_node.get_node('%InputContainer').get_child(0))
			}
		HenCnode.SUB_TYPE.IMG:
			token.merge({
				name = (_node.get_node('%Title').text as String).to_snake_case(),
				params = get_cnode_inputs(_node)
			})
		HenCnode.SUB_TYPE.RAW_CODE:
			token.merge({
				code = get_cnode_inputs(_node)[0],
			})
		HenCnode.SUB_TYPE.CONST:
			token.merge({
				name = _node.get_cnode_name(),
				value = _node.get_node('%OutputContainer').get_child(0).get_node('%CNameOutput').get_child(0).get_value()
			})
		HenCnode.SUB_TYPE.SINGLETON:
			token.merge({
				name = _node.get_cnode_name(),
				params = get_cnode_inputs(_node),
				id = _id if _node.get_node('%OutputContainer').get_child_count() > 1 else -1,
			})
		HenCnode.SUB_TYPE.GET_PROP:
			token.merge({
				from = get_cnode_inputs(_node),
				name = _node.get_node('%OutputContainer').get_child(0).get_in_out_name() if _id <= 0 else _node.get_node('%OutputContainer').get_child(0).get_in_out_name() + '.' + _node.get_node('%OutputContainer').get_child(_id).get_in_out_name(),
			})
		HenCnode.SUB_TYPE.SET_PROP:
			token.merge({
				params = get_cnode_inputs(_node, true),
				name = _node.get_node('%InputContainer').get_child(1).get_in_out_name()
			})
		HenCnode.SUB_TYPE.EXPRESSION:
			token.merge({
				params = get_cnode_inputs(_node, true),
				exp = _node.get_node('%Container').get_child(1).get_child(0).raw_text
			})

	return token

#
#
# parse to code
static func parse_token_by_type(_token: Dictionary, _level: int = 0) -> String:
	var indent: StringName = '\t'.repeat(_level)
	var prefix: StringName = '_ref.'

	if _token.has('use_self'):
		if _token.use_self == true:
			prefix = 'self.'

	if _token.has('category'):
		match _token.get('category'):
			'native':
				prefix = ''

	match _token.type:
		HenCnode.SUB_TYPE.VAR:
			return indent + prefix + _token.name
		HenCnode.SUB_TYPE.SET_VAR:
			return indent + prefix + '{name} = {value}'.format({
				name = _token.name,
				value = parse_token_by_type(_token.value)
			})
		HenCnode.SUB_TYPE.SET_LOCAL_VAR:
			return indent + '{name} = {value}'.format({
				name = _token.name,
				value = parse_token_by_type(_token.value)
			})
		HenCnode.SUB_TYPE.LOCAL_VAR:
			return indent + _token.name
		HenCnode.SUB_TYPE.IN_PROP:
			if _token.has('use_prefix'):
				return indent + prefix + _token.value

			if _token.has('is_prop') and _token.get('is_prop') == true:
				return indent + prefix + _token.value
			
			if _token.has('use_self'):
				if _token.has('ref'):
					if _token.ref:
						return indent + 'self'

			return indent + _token.value
		HenCnode.SUB_TYPE.VOID, HenCnode.SUB_TYPE.GO_TO_VOID, HenCnode.SUB_TYPE.SELF_GO_TO_VOID:
			var values: Array = _provide_params_ref(_token.params, prefix)
			var params: Array = values[0]

			prefix = values[1]

			var selfInput: String = ''

			if _token.type == HenCnode.SUB_TYPE.SELF_GO_TO_VOID:
				selfInput = 'self, '

			return indent + prefix + '{name}({params})'.format({
				name = _token.name,
				params = selfInput + ', '.join(params.map(
					func(x: Dictionary) -> String:
						return parse_token_by_type(x)
			))
			})
		HenCnode.SUB_TYPE.FUNC, HenCnode.SUB_TYPE.USER_FUNC, HenCnode.SUB_TYPE.SINGLETON:
			var values: Array = _provide_params_ref(_token.params, prefix)
			var params: Array = values[0]
			
			prefix = values[1]

			if _token.type == HenCnode.SUB_TYPE.SINGLETON:
				prefix = ''

			return indent + prefix + '{name}({params}){id}'.format({
				name = _token.name,
				id = '[{0}]'.format([_token.id]) if _token.id >= 0 else '',
				params = ', '.join(params.map(
					func(x: Dictionary) -> String:
						return parse_token_by_type(x)
			))
			})
		HenCnode.SUB_TYPE.VIRTUAL, HenCnode.SUB_TYPE.FUNC_INPUT, 'signal_virtual':
			return _token.param
		'if':
			var base: String = 'if {condition}:\n'.format({
				condition = parse_token_by_type(_token.condition)
			})
			var code_list: Array = []

			if _token.true_flow.is_empty():
				base += indent + '\tpass\n'
			else:
				for token in _token.true_flow:
					code_list.append(
						parse_token_by_type(token, _level + 1)
					)

			if not _token.false_flow.is_empty():
				var else_code: String = indent + 'else:\n'
				for token in _token.false_flow:
					else_code += parse_token_by_type(token, _level + 1) + '\n'
				code_list.append(else_code)
			
			for token in _token.then_flow:
				code_list.append(
					parse_token_by_type(token, _level)
				)

			if code_list.is_empty():
				if not _token.true_flow.is_empty():
					base += indent + '\tpass'
			else:
				base += '\n'.join(code_list) + '\n\n'
		
			return indent + base
		'signal_connection':
			var ref = (_token.params as Array).pop_front()

			if _token.params.size() > 0:
				return indent + '{ref}.connect("{signal_name}", {call_ref}{callable}.bind({params}))'.format({
					ref = parse_token_by_type(ref),
					call_ref = '_ref.' if _token.route.type == HenRouter.ROUTE_TYPE.STATE else '',
					signal_name = _token.signal_name,
					callable = _get_signal_call_name(_token.item_ref.get_node('%Name').text),
					params = ', '.join(_token.params.map(
						func(x: Dictionary) -> String:
							return parse_token_by_type(x)
				))
				})
			return indent + '{ref}.connect("{signal_name}", {call_ref}{callable})'.format({
				ref = parse_token_by_type(ref),
				call_ref = '_ref.' if _token.route.type == HenRouter.ROUTE_TYPE.STATE else '',
				signal_name = _token.signal_name,
				callable = _get_signal_call_name(_token.item_ref.get_node('%Name').text)
			})
		'signal_disconnection':
			var ref = (_token.params as Array).pop_front()

			return indent + '{ref}.disconnect("{signal_name}", {call_ref}{callable})'.format({
				ref = parse_token_by_type(ref),
				call_ref = '_ref.' if _token.route.type == HenRouter.ROUTE_TYPE.STATE else '',
				signal_name = _token.signal_name,
				callable = _get_signal_call_name(_token.item_ref.get_node('%Name').text)
			})
		'signal_emit':
			var ref = (_token.params as Array).pop_front()

			if _token.params.size() > 0:
				return indent + '{ref}.emit_signal("{signal_name}", {params})'.format({
					ref = parse_token_by_type(ref),
					signal_name = _token.signal_name,
					params = ', '.join(_token.params.map(
						func(x: Dictionary) -> String:
							return parse_token_by_type(x)
				))
				})
			return indent + '{ref}.emit_signal("{signal_name}")'.format({
				ref = parse_token_by_type(ref),
				signal_name = _token.signal_name
			})
		HenCnode.SUB_TYPE.NOT_CONNECTED:
			return 'null'
		HenCnode.SUB_TYPE.FOR, HenCnode.SUB_TYPE.FOR_ARR:
			var flow: Array = []
			var loop_item: String = get_sequence_name('loop_idx') if _token.type == HenCnode.SUB_TYPE.FOR else get_sequence_name('loop_item')

			_name_ref[_token.hash] = loop_item

			if _token.flow.size() <= 0:
				flow.append(indent + '\tpass')

			for token in _token.flow:
				flow.append(parse_token_by_type(token, _level + 1))
			
			if _token.type == HenCnode.SUB_TYPE.FOR:
				return indent + 'for {item_name} in range({params}):\n{flow}'.format({
					flow = '\n'.join(flow),
					item_name = loop_item,
					params = ', '.join(_token.params.map(
						func(x: Dictionary) -> String:
							return parse_token_by_type(x)
				))
				})
			else:
				return indent + 'for {item_name} in {arr}:\n{flow}'.format({
					flow = '\n'.join(flow),
					item_name = loop_item,
					arr = parse_token_by_type(_token.params[0])
				})
		'for_item':
			return _name_ref[_token.hash]
		HenCnode.SUB_TYPE.BREAK:
			# TODO check break and continue if is inside for loop
			return indent + 'break'
		HenCnode.SUB_TYPE.CONTINUE:
			return indent + 'continue'
		HenCnode.SUB_TYPE.CAST:
			var from = parse_token_by_type(_token.from)

			if from == 'null':
				return prefix.replace('.', '')

			return '(({from}) as {to})'.format({
				from = from,
				to = _token.to
			})
		HenCnode.SUB_TYPE.IMG:
			return '{a} {op} {b}'.format({
				a = parse_token_by_type(_token.params[0]),
				op = _token.name,
				b = parse_token_by_type(_token.params[1])
			})
		HenCnode.SUB_TYPE.DEBUG:
			return indent + HenGlobal.DEBUG_TOKEN + HenGlobal.DEBUG_VAR_NAME + ' += ' + str(_token.counter)
		HenCnode.SUB_TYPE.DEBUG_PUSH:
			return indent + get_debug_push_str()
		HenCnode.SUB_TYPE.DEBUG_FLOW_START:
			return indent + get_debug_var_start()
		HenCnode.SUB_TYPE.DEBUG_STATE:
			return indent + HenGlobal.DEBUG_TOKEN + "EngineDebugger.send_message('hengo:debug_state', [" + str(_token.id) + "])"
		HenCnode.SUB_TYPE.START_DEBUG_STATE:
			return indent + "EngineDebugger.send_message('hengo:debug_state', [" + str(_token.id) + "])"
		HenCnode.SUB_TYPE.DEBUG_VALUE:
			return indent + HenGlobal.DEBUG_TOKEN + "EngineDebugger.send_message('hengo:debug_value', [" + str(_token.id) + ", var_to_str(" + parse_token_by_type(_token.value) + ")])"
		HenCnode.SUB_TYPE.PASS:
			return indent + 'pass'
		HenCnode.SUB_TYPE.RAW_CODE:
			return _token.code.value.trim_prefix('"').trim_suffix('"')
		HenCnode.SUB_TYPE.CONST:
			return indent + _token.name + '.' + _token.value
		HenCnode.SUB_TYPE.SINGLETON:
			return indent + _token.name
		HenCnode.SUB_TYPE.GET_PROP:
			return indent + parse_token_by_type(_token.from[0]) + '.' + _token.name
		HenCnode.SUB_TYPE.SET_PROP:
			var code: String = ''
			var idx: int = 0

			for param in _token.params:
				if param.type != HenCnode.SUB_TYPE.IN_PROP:
					if idx == 1:
						code += indent + parse_token_by_type(_token.params[0]) + '.' + _token.name + ' = ' + parse_token_by_type(param)
					elif idx > 1:
						code += '\n' + indent + parse_token_by_type(_token.params[0]) + '.' + _token.name + '.' + param.prop_name + ' = ' + parse_token_by_type(param)
				
				idx += 1

			return code
		HenCnode.SUB_TYPE.EXPRESSION:
			var new_exp: String = _token.exp.replacen('\n', '')
			var reg: RegEx = RegEx.new()

			for param in _token.params:
				reg.compile("\\b" + param.prop_name + "\\b")
				new_exp = reg.sub(new_exp, parse_token_by_type(param), true)
			
			return new_exp
		_:
			return ''


static func _provide_params_ref(_params: Array, _prefix: StringName) -> Array:
	if _params.size() > 0:
		var first: Dictionary = _params[0]

		if first.has('ref'):
			return [
				_params.slice(1),
				parse_token_by_type(first) + '.'
			]
	
	return [_params, _prefix]

static func _get_signal_call_name(_name: String) -> String:
	return '_on_' + _name.to_snake_case() + '_signal_'

static func parse_token_and_value(_node: HenCnode, _id: int = 0) -> String:
	var code: String

	match _node.sub_type:
		'if':
			code = parse_token_by_type(
				get_if_token(_node)
			)
		HenCnode.SUB_TYPE.FOR, HenCnode.SUB_TYPE.FOR_ARR:
			code = parse_token_by_type(
				get_for_token(_node)
			)
		HenCnode.SUB_TYPE.VIRTUAL:
			code = '# virtual cnode'
		_:
			code = parse_token_by_type(
				parse_cnode_values(_node, _id)
			)

	return '\n'.join((code.split('\n') as Array).filter(func(x): return not x.contains(HenGlobal.DEBUG_TOKEN))) # removes debug lines

static func get_if_token(_node: HenCnode) -> Dictionary:
	var true_flow: Array = []
	var then_flow: Array = []
	var false_flow: Array = []

	if _node.flow_to.has('true_flow'):
		true_flow = flow_tree_explorer(_node.flow_to.true_flow)
		# debug
		true_flow.append(get_debug_token(_node, 'true_flow'))

	if _node.flow_to.has('then_flow'):
		then_flow = flow_tree_explorer(_node.flow_to.then_flow)
		then_flow.append(get_debug_token(_node, 'then_flow'))
		
	if _node.flow_to.has('false_flow'):
		false_flow = flow_tree_explorer(_node.flow_to.false_flow)
		false_flow.append(get_debug_token(_node, 'false_flow'))
	
	var container = _node.get_node('%TitleContainer').get_child(0)

	return {
		type = 'if',
		true_flow = true_flow,
		then_flow = then_flow,
		false_flow = false_flow,
		condition = get_input_value(container.get_child(0))
	}

static func get_for_token(_node: HenCnode) -> Dictionary:
	return {
		type = _node.sub_type,
		hash = _node.get_instance_id(),
		params = get_cnode_inputs(_node),
		flow = flow_tree_explorer(_node.flow_to.cnode) if _node.flow_to.has('cnode') else []
	}


static func get_sequence_name(_name: String) -> String:
	if _name_list.has(_name):
		_name_counter += 1
		var new_name = _name + '_' + str(_name_counter)
		_name_list.append(new_name)
		return new_name

	_name_list.append(_name)
	return _name


static func check_state_errors(_state: HenState) -> void:
	for _node in HenGlobal.CNODE_CONTAINER.get_children():
		_node.check_error()


static func check_errors_in_flow(_node: HenCnode) -> void:
	match _node.sub_type:
		'signal_connection', HenCnode.SUB_TYPE.GO_TO_VOID:
			_node.check_error()
			if not _node.flow_to.is_empty():
				check_errors_in_flow(_node.flow_to.cnode)
			

static func get_debug_token(_node: HenCnode, _flow: String = 'cnode') -> Dictionary:
	_debug_counter *= 2.
	_debug_symbols[str(_debug_counter)] = [_node.hash, _flow]
	return {type = HenCnode.SUB_TYPE.DEBUG, counter = _debug_counter}


static func get_debug_counter(_node: HenCnode) -> float:
	_debug_counter *= 2.
	_debug_symbols[str(_debug_counter)] = [_node.hash]
	return _debug_counter


static func get_state_debug_counter(_state: HenState) -> float:
	_debug_counter *= 2.
	_debug_symbols[str(_debug_counter)] = [_state.hash]
	return _debug_counter


static func get_push_debug_token(_node: HenCnode) -> Dictionary:
	return {type = HenCnode.SUB_TYPE.DEBUG_PUSH}


static func get_debug_flow_start_token(_node: HenCnode) -> Dictionary:
	return {type = HenCnode.SUB_TYPE.DEBUG_FLOW_START}


static func get_debug_var_start() -> String:
	return HenGlobal.DEBUG_TOKEN + 'var ' + HenGlobal.DEBUG_VAR_NAME + ': float = 0.\n'

static func get_debug_push_str() -> String:
	return HenGlobal.DEBUG_TOKEN + "EngineDebugger.send_message('hengo:cnode', [" + HenGlobal.DEBUG_VAR_NAME + "])"