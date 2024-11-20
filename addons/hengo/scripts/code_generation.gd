@tool
extends Node

# imports
const _Global = preload('res://addons/hengo/scripts/global.gd')
const _CNode = preload('res://addons/hengo/scripts/cnode.gd')
const _State = preload('res://addons/hengo/scripts/state.gd')
const _UtilsName = preload('res://addons/hengo/scripts/utils_name.gd')
const _SaveLoad = preload('res://addons/hengo/scripts/save_load.gd')
const _Router = preload('res://addons/hengo/scripts/router.gd')
const _Enums = preload('res://addons/hengo/references/enums.gd')

# references
static var _name_list: Array = []
static var _name_counter: int = 0
static var _name_ref: Dictionary = {}
# debug
static var _debug_counter: float = 1.
static var _debug_symbols: Dictionary = {}


static func generate_and_save(_compile_ref: HBoxContainer) -> void:
	var start: float = Time.get_ticks_usec()
	_SaveLoad.save(generate(), _debug_symbols)
	var end: float = Time.get_ticks_usec()
	
	print('GENERATED AND SAVED HENGO SCRIPT IN -> ', (end - start) / 1000, 'ms.')
	print('debug  => ', _debug_symbols)

	_Global.current_script_debug_symbols = _debug_symbols


static func generate() -> String:
	# reseting internal variables
	_name_list = []
	_name_counter = 0
	_name_ref = {}
	_debug_counter = 1.
	_debug_symbols = {}

	var code: String = 'extends {0}\n\n'.format([_Global.script_config.type])

	# variables
	var var_code: String = '#\n# Variables\n'

	for var_item in _Global.SIDE_BAR.get_node('%Var').get_node('%Container').get_children():
		var var_name: String = var_item.res[0].value
		var var_type: String = var_item.res[1].value
		var var_export: bool = var_item.res[2].value

		var type_value: String = 'null'

		if _Enums.VARIANT_TYPES.has(var_type):
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

	for general in _Global.GENERAL_CONTAINER.get_children():
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
		start_state_name = _Global.start_state.get_state_name().to_snake_case(),
		start_state_debug = parse_token_by_type({type = 'start_debug_state', id = get_state_debug_counter(_Global.start_state)}),
		_input = 'func _input(event: InputEvent) -> void:\n' + '\n'.join(input_data['Input'].tokens.map(func(x: Dictionary): return parse_token_by_type(x, 1))) if input_data.has('Input') else '',
		_shortcut_input = 'func _shortcut_input(event: InputEvent) -> void:\n' + '\n'.join(input_data['Shortcut Input'].tokens.map(func(x: Dictionary): return parse_token_by_type(x, 1))) if input_data.has('Shortcut Input') else '',
		_unhandled_input = 'func _unhandled_input(event: InputEvent) -> void:\n' + '\n'.join(input_data['Unhandled Input'].tokens.map(func(x: Dictionary): return parse_token_by_type(x, 1))) if input_data.has('Unhandled Input') else '',
		_unhandled_key_input = 'func _unhandled_key_input(event: InputEvent) -> void:\n' + '\n'.join(input_data['Unhandled Key Input'].tokens.map(func(x: Dictionary): return parse_token_by_type(x, 1))) if input_data.has('Unhandled Key Input') else '',
		_process = '\n'.join(input_data['Process'].tokens.map(func(x: Dictionary): return parse_token_by_type(x, 1))) if input_data.has('Process') else '',
		_physics_process = '\n'.join(input_data['Physics Process'].tokens.map(func(x: Dictionary): return parse_token_by_type(x, 1))) if input_data.has('Physics Process') else '',
	})

	# functions
	var func_code: String = '#\n# Functions\n'

	for func_item in _Global.SIDE_BAR.get_node('%Function').get_node('%Container').get_children():
		var func_name: String = func_item.res[0].value

		func_code += 'func {name}({params}):\n'.format({
			name = func_name.to_snake_case(),
			params = ', '.join(func_item.res[1].inputs.map(
				func(x: Dictionary) -> String:
					return x.res.name
		))
		})

		# debug
		func_code += '\t' + get_debug_var_start()
		
		# local variable
		var local_var_list: Array = []

		if _Global.LOCAL_VAR_SECTION.local_vars.has(func_item.route.id):
			for local_var in _Global.LOCAL_VAR_SECTION.local_vars[func_item.route.id]:
				local_var_list.append(
					'\tvar {name}'.format({
						name = local_var.get_node('%Name').text
					})
				)

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

	# signal callables
	var signal_code: String = '#\n\n# Signals Callables\n'

	for signal_item in _Global.SIDE_BAR.get_node('%StateSignal').get_node('%Container').get_children():
		var signal_name = '_on_' + signal_item.res[0].value.to_snake_case() + '_signal_'
		var raw_signal_data: Dictionary = ClassDB.class_get_signal(signal_item.data.signal_data.object_name, signal_item.data.signal_data.signal_name)

		signal_code += 'func {name}({params}):\n'.format({
			name = signal_name,
			params = ', '.join(raw_signal_data.args.map( # parsing raw inputs from signal
			func(x: Dictionary) -> String:
				return x.name
		# parsing custom inputs
		) + signal_item.res[1].outputs.map(
				func(x: Dictionary) -> String:
					return x.res.name
		))
		})

		# debug
		signal_code += '\t' + get_debug_var_start()

		var signal_flow_to: Dictionary = signal_item.virtual_cnode_list[0].flow_to

		if signal_flow_to.has('cnode'):
			var signal_tokens: Array = flow_tree_explorer(signal_item.virtual_cnode_list[0].flow_to.cnode)
			var signal_block: Array = []

			for token in signal_tokens:
				signal_block.append(parse_token_by_type(token, 1))

			# debug
			signal_block.append(parse_token_by_type(
				get_debug_token(signal_item.virtual_cnode_list[0]),
				1
			))

			signal_code += '\n'.join(signal_block) + '\n\n'
			signal_code += '\t' + get_debug_push_str() + '\n\n\n'
		else:
			signal_code += '\tpass\n\n'
	
	base_template += signal_code
	# end signal callables

	# parsing all states
	for state in _Global.STATE_CONTAINER.get_children():
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
				token_list.append({type = 'debug_state', id = get_state_debug_counter(virtual_cnode.route_ref.state_ref)})
			
			data[cnode_name] = {
				tokens = token_list,
				params = get_cnode_outputs(virtual_cnode)
			}
		else:
			if cnode_name == 'enter':
				data[cnode_name] = {
					tokens = [ {type = 'debug_state', id = get_state_debug_counter(virtual_cnode.route_ref.state_ref)}, {type = 'pass'}],
					params = []
				}

	return data

static func flow_tree_explorer(_node: _CNode, _token_list: Array = []) -> Array:
	match _node.type:
		'if':
			_token_list.append(get_if_token(_node))
		'for', 'for_arr':
			_token_list.append(get_for_token(_node))
		_:
			_token_list.append(parse_cnode_values(_node))

			if not _node.flow_to.is_empty():
				flow_tree_explorer(_node.flow_to.cnode, _token_list)

	return _token_list

# getting cnode outputs
static func get_cnode_outputs(_node: _CNode) -> Array:
	var outputs = []

	for output in _node.get_node('%OutputContainer').get_children():
		outputs.append({
			name = output.get_node('%Name').text,
			type = output.connection_type
		})
	
	return outputs

# getting cnode inputs values
static func get_cnode_inputs(_node: _CNode, _get_name: bool = false) -> Array:
	var input_container = _node.get_node('%InputContainer')
	var inputs = []

	for input in input_container.get_children():
		inputs.append(get_input_value(input, _get_name))
	
	return inputs


static func get_input_value(_input, _get_name: bool = false) -> Dictionary:
	if _input.in_connected_from:
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
				type = 'in_prop',
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
				
			if _input.root.route_ref.type != _Router.ROUTE_TYPE.STATE \
			or not _input.is_ref:
				prop_data.use_self = true

			return prop_data
		else:
			# if input don't have a connection
			return {type = 'not_connected', cnode_type = _input.connection_type}

# parsing cnode code base on type
static func parse_cnode_values(_node: _CNode, _id: int = 0) -> Dictionary:
	var use_self: bool = _node.route_ref.type != _Router.ROUTE_TYPE.STATE

	var token: Dictionary = {
		type = _node.type,
		use_self = use_self,
	}

	if _node.category:
		token.category = _node.category

	match _node.type:
		'void', 'go_to_void', 'self_go_to_void':
			token.merge({
				name = _node.get_cnode_name().to_snake_case(),
				params = get_cnode_inputs(_node)
			})
		'func', 'user_func':
			token.merge({
				name = _node.get_cnode_name().to_snake_case(),
				params = get_cnode_inputs(_node),
				id = _id if _node.get_node('%OutputContainer').get_child_count() > 1 else -1,
			})
		'var', 'local_var':
			token.merge({
				name = _node.get_node('%OutputContainer').get_child(0).get_in_out_name().to_snake_case(),
			})
		'debug_value':
			token.merge({
				value = get_cnode_inputs(_node)[0],
				id = get_debug_counter(_node)
			})
		'set_var', 'set_local_var':
			token.merge({
				name = _node.get_node('%InputContainer').get_child(0).get_in_out_name().to_snake_case(),
				value = get_cnode_inputs(_node)[0],
			})
		'virtual', 'func_input', 'signal_virtual':
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
		'for', 'for_arr':
			return {
				type = 'for_item',
				hash = _node.get_instance_id()
			}
		'cast':
			return {
				type = _node.type,
				to = _node.get_node('%OutputContainer').get_child(0).connection_type,
				from = get_input_value(_node.get_node('%InputContainer').get_child(0))
			}
		'img':
			token.merge({
				name = (_node.get_node('%Title').text as String).to_snake_case(),
				params = get_cnode_inputs(_node)
			})
		'raw_code':
			token.merge({
				code = get_cnode_inputs(_node)[0],
			})
		'const':
			token.merge({
				name = _node.get_cnode_name(),
				value = _node.get_node('%OutputContainer').get_child(0).get_node('%CNameOutput').get_child(0).get_value()
			})
		'singleton':
			token.merge({
				name = _node.get_cnode_name(),
				params = get_cnode_inputs(_node),
				id = _id if _node.get_node('%OutputContainer').get_child_count() > 1 else -1,
			})
		'get_prop':
			token.merge({
				from = get_cnode_inputs(_node),
				name = _node.get_node('%OutputContainer').get_child(0).get_in_out_name() if _id <= 0 else _node.get_node('%OutputContainer').get_child(0).get_in_out_name() + '.' + _node.get_node('%OutputContainer').get_child(_id).get_in_out_name(),
			})
		'set_prop':
			token.merge({
				params = get_cnode_inputs(_node, true),
				name = _node.get_node('%InputContainer').get_child(1).get_in_out_name()
			})
		'expression':
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
		'var':
			return indent + prefix + _token.name
		'set_var':
			return indent + prefix + '{name} = {value}'.format({
				name = _token.name,
				value = parse_token_by_type(_token.value)
			})
		'set_local_var':
			return indent + '{name} = {value}'.format({
				name = _token.name,
				value = parse_token_by_type(_token.value)
			})
		'local_var':
			return indent + _token.name
		'in_prop':
			if _token.has('use_self'):
				if _token.has('ref'):
					if _token.ref:
						return indent + 'self'
			return indent + _token.value
		'void', 'go_to_void', 'self_go_to_void':
			var values: Array = _provide_params_ref(_token.params, prefix)
			var params: Array = values[0]

			prefix = values[1]

			var selfInput: String = ''

			if _token.type == 'self_go_to_void':
				selfInput = 'self, '

			return indent + prefix + '{name}({params})'.format({
				name = _token.name,
				params = selfInput + ', '.join(params.map(
					func(x: Dictionary) -> String:
						return parse_token_by_type(x)
			))
			})
		'func', 'user_func', 'singleton':
			var values: Array = _provide_params_ref(_token.params, prefix)
			var params: Array = values[0]
			
			prefix = values[1]

			if _token.type == 'singleton':
				prefix = ''

			return indent + prefix + '{name}({params}){id}'.format({
				name = _token.name,
				id = '[{0}]'.format([_token.id]) if _token.id >= 0 else '',
				params = ', '.join(params.map(
					func(x: Dictionary) -> String:
						return parse_token_by_type(x)
			))
			})
		'virtual', 'func_input', 'signal_virtual':
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
					call_ref = '_ref.' if _token.route.type == _Router.ROUTE_TYPE.STATE else '',
					signal_name = _token.signal_name,
					callable = _get_signal_call_name(_token.item_ref.get_node('%Name').text),
					params = ', '.join(_token.params.map(
						func(x: Dictionary) -> String:
							return parse_token_by_type(x)
				))
				})
			return indent + '{ref}.connect("{signal_name}", {call_ref}{callable})'.format({
				ref = parse_token_by_type(ref),
				call_ref = '_ref.' if _token.route.type == _Router.ROUTE_TYPE.STATE else '',
				signal_name = _token.signal_name,
				callable = _get_signal_call_name(_token.item_ref.get_node('%Name').text)
			})
		'signal_disconnection':
			var ref = (_token.params as Array).pop_front()

			return indent + '{ref}.disconnect("{signal_name}", {call_ref}{callable})'.format({
				ref = parse_token_by_type(ref),
				call_ref = '_ref.' if _token.route.type == _Router.ROUTE_TYPE.STATE else '',
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
		'not_connected':
			return 'null'
		'for', 'for_arr':
			var flow: Array = []
			var loop_item: String = get_sequence_name('loop_idx') if _token.type == 'for' else get_sequence_name('loop_item')

			_name_ref[_token.hash] = loop_item

			if _token.flow.size() <= 0:
				flow.append(indent + '\tpass')

			for token in _token.flow:
				flow.append(parse_token_by_type(token, _level + 1))
			
			if _token.type == 'for':
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
		'break':
			# TODO check break and continue if is inside for loop
			return indent + 'break'
		'continue':
			return indent + 'continue'
		'cast':
			var from = parse_token_by_type(_token.from)

			if from == 'null':
				return prefix.replace('.', '')

			return '(({from}) as {to})'.format({
				from = from,
				to = _token.to
			})
		'img':
			return '{a} {op} {b}'.format({
				a = parse_token_by_type(_token.params[0]),
				op = _token.name,
				b = parse_token_by_type(_token.params[1])
			})
		'debug':
			return indent + _Global.DEBUG_TOKEN + _Global.DEBUG_VAR_NAME + ' += ' + str(_token.counter)
		'debug_push':
			return indent + get_debug_push_str()
		'debug_flow_start':
			return indent + get_debug_var_start()
		'debug_state':
			return indent + _Global.DEBUG_TOKEN + "EngineDebugger.send_message('hengo:debug_state', [" + str(_token.id) + "])"
		'start_debug_state':
			return indent + "EngineDebugger.send_message('hengo:debug_state', [" + str(_token.id) + "])"
		'debug_value':
			return indent + _Global.DEBUG_TOKEN + "EngineDebugger.send_message('hengo:debug_value', [" + str(_token.id) + ", var_to_str(" + parse_token_by_type(_token.value) + ")])"
		'pass':
			return indent + 'pass'
		'raw_code':
			return _token.code.value.trim_prefix('"').trim_suffix('"')
		'const':
			return indent + _token.name + '.' + _token.value
		'singleton':
			return indent + _token.name
		'get_prop':
			return indent + parse_token_by_type(_token.from[0]) + '.' + _token.name
		'set_prop':
			var code: String = ''
			var idx: int = 0

			for param in _token.params:
				if param.type != 'in_prop':
					if idx == 1:
						code += indent + parse_token_by_type(_token.params[0]) + '.' + _token.name + ' = ' + parse_token_by_type(param)
					elif idx > 1:
						code += '\n' + indent + parse_token_by_type(_token.params[0]) + '.' + _token.name + '.' + param.prop_name + ' = ' + parse_token_by_type(param)
				
				idx += 1

			return code
		'expression':
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

static func parse_token_and_value(_node: _CNode, _id: int = 0) -> String:
	match _node.type:
		'if':
			return parse_token_by_type(
				get_if_token(_node)
			)
		'for', 'for_arr':
			return parse_token_by_type(
				get_for_token(_node)
			)
		'virtual':
			return '# virtual cnode'

	return parse_token_by_type(
		parse_cnode_values(_node, _id)
	)

static func get_if_token(_node: _CNode) -> Dictionary:
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

static func get_for_token(_node: _CNode) -> Dictionary:
	return {
		type = _node.type,
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


static func check_state_errors(_state: _State) -> void:
	for _node in _Global.CNODE_CONTAINER.get_children():
		_node.check_error()


static func check_errors_in_flow(_node: _CNode) -> void:
	match _node.type:
		'signal_connection', 'go_to_void':
			_node.check_error()
			if not _node.flow_to.is_empty():
				check_errors_in_flow(_node.flow_to.cnode)
			

static func get_debug_token(_node: _CNode, _flow: String = 'cnode') -> Dictionary:
	_debug_counter *= 2.
	_debug_symbols[str(_debug_counter)] = [_node.hash, _flow]
	return {type = 'debug', counter = _debug_counter}


static func get_debug_counter(_node: _CNode) -> float:
	_debug_counter *= 2.
	_debug_symbols[str(_debug_counter)] = [_node.hash]
	return _debug_counter


static func get_state_debug_counter(_state: _State) -> float:
	_debug_counter *= 2.
	_debug_symbols[str(_debug_counter)] = [_state.hash]
	return _debug_counter


static func get_push_debug_token(_node: _CNode) -> Dictionary:
	return {type = 'debug_push'}


static func get_debug_flow_start_token(_node: _CNode) -> Dictionary:
	return {type = 'debug_flow_start'}


static func get_debug_var_start() -> String:
	return _Global.DEBUG_TOKEN + 'var ' + _Global.DEBUG_VAR_NAME + ': float = 0.\n'

static func get_debug_push_str() -> String:
	return _Global.DEBUG_TOKEN + "EngineDebugger.send_message('hengo:cnode', [" + _Global.DEBUG_VAR_NAME + "])"