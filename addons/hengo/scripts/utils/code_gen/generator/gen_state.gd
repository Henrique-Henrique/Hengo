class_name HenGeneratorState extends RefCounted


# puts hook lines at the top of a lifecycle method, creating it when the state
# has nothing else in that phase
static func _prepend_hook(_save_data: HenSaveData, _state: HenSaveState, _virtual_tokens: Dictionary, _phase: StringName, _hook_tokens: Array) -> void:
	if _hook_tokens.is_empty():
		return

	var key: String = str(_phase)

	if not _virtual_tokens.has(key):
		_virtual_tokens[key] = {
			tokens = [],
			params = HenGeneratorAction.get_phase_params(_save_data, _state, _phase)
		}

	_virtual_tokens[key].tokens = _hook_tokens + (_virtual_tokens[key].tokens as Array)


static func get_states_start_code(_save_data: HenSaveData) -> String:
	var code: String = ''
	var idx: int = 0
	for state: HenSaveState in _save_data.states:
		code += ('\n' if idx > 0 else '') + '\t\t{key}={c_name}.new(self),'.format({
			key = state.name.to_snake_case(),
			c_name = state.name.to_pascal_case()
		})
		idx += 1
	
	return code


# the flag rides the instance, so the states dict stays a plain literal
static func get_reenterable_code(_save_data: HenSaveData) -> String:
	var names: Array[String] = []

	for state: HenSaveState in _save_data.states:
		if state.can_reenter:
			names.append('"' + state.name.to_snake_case() + '"')

	if names.is_empty():
		return ''

	return '\n\t_STATE_CONTROLLER.set_reenterable([{names}])'.format({names = ', '.join(names)})


# the values a use hands its macro, kept at script scope: a nested state class
# cannot read the class holding it
static func get_macro_input_lines(_save_data: HenSaveData) -> Array:
	var lines: Array = []

	for use: HenSaveState in _macro_uses(_save_data):
		var macro: HenSaveStateMacro = use.get_macro(_save_data)

		if not macro:
			continue

		for param: HenSaveParam in use.macro_inputs:
			lines.append('var ' + HenSaveStateMacro.INPUT_VAR_PREFIX + str(use.id) + '_' + param.name.to_snake_case() + ' = ' + _macro_input_code(_save_data, use, param))

	return lines


static func _macro_input_code(_save_data: HenSaveData, _use: HenSaveState, _param: HenSaveParam) -> String:
	var bind: String = HenUtils.bind_expression(_save_data, str(_use.macro_bindings.get(str(_param.id), '')))

	# the line lands at script scope, where the node is self and _ref is nothing
	if not bind.is_empty():
		return HenActionCode.process_script_macro_body(bind, true)

	return HenActionCode.get_default_value_code(_save_data, str(_param.type), false, '', null, _param.default_value)


static func _macro_uses(_save_data: HenSaveData) -> Array:
	var uses: Array = []

	for state: HenSaveState in _save_data.states:
		if state.is_macro_use():
			uses.append(state)

	for sub_list: Variant in _save_data.sub_states.values():
		for state: HenSaveState in sub_list:
			if state.is_macro_use():
				uses.append(state)

	return uses


static func get_states_code(_save_data: HenSaveData) -> String:
	return get_states_code_with_arr(_save_data, _save_data.states)

static func get_states_code_with_arr(_save_data: HenSaveData, _state_arr: Array, _level: int = 0) -> String:
	var code: String = ''
	var idx: int = 0

	for state: HenSaveState in _state_arr:
		var is_use: bool = state.is_macro_use()

		# a macro that uses itself would unfold forever, so the inner use stops here
		if is_use and HenGeneratorAction.macro_use_loops(state):
			code += _looping_use_code(state, _level, idx)
			idx += 1
			continue

		# a use writes the machine of its macro, so the drawer is entered around it:
		# its steps and the names they declare belong to this use alone
		if is_use:
			HenGeneratorAction.push_macro_use(state)

		code += _state_code(_save_data, state, _level, idx)

		if is_use:
			HenGeneratorAction.pop_macro_use()

		idx += 1

	return code


# a use of a macro that is already being written: an empty state, since unfolding
# it again would never end
static func _looping_use_code(_use: HenSaveState, _level: int, _idx: int) -> String:
	return '{new_line}{indent}class {name} extends HengoState:
{indent}	pass'.format({
		name = _use.name.to_pascal_case(),
		new_line = '

' if _idx > 0 else '',
		indent = '	'.repeat(_level)
	})


# one state as a class: its lifecycle methods, what its actions declare and the
# machine it holds, which for a use of a macro comes from the drawer
static func _state_code(_save_data: HenSaveData, state: HenSaveState, _level: int, idx: int) -> String:
	var code: String = ''

	if true:
		# the phases a state has come from its action list alone: the scaffolding
		# vcnode that used to stand for each one carried no logic of its own
		var virtual_tokens: Dictionary = {}

		# inject linear action bodies into the state's lifecycle methods.
		# exit gets super() for free (the != 'enter' rule), which the base needs
		# to tear down current_sub_state
		for phase: StringName in HenSaveAction.PHASE_ORDER:
			var action_tokens: Array = HenGeneratorAction.get_state_action_tokens(_save_data, state, phase)
			if action_tokens.is_empty():
				continue

			var key: String = str(phase)
			if not virtual_tokens.has(key):
				virtual_tokens[key] = {
					tokens = [],
					params = HenGeneratorAction.get_phase_params(_save_data, state, phase)
				}

			(virtual_tokens[key].tokens as Array).append_array(action_tokens)

		# an action that keeps state resets it on entry and undoes it on exit,
		# whatever phase it runs in
		_prepend_hook(_save_data, state, virtual_tokens, &'enter', HenGeneratorAction.get_state_reset_tokens(_save_data, state))
		_prepend_hook(_save_data, state, virtual_tokens, &'exit', HenGeneratorAction.get_state_teardown_tokens(_save_data, state))

		var base = '{new_line}{indent}class {name} extends HengoState:\n'.format({
			name = state.name.to_pascal_case(),
			new_line = '\n\n' if idx > 0 else '',
			indent = '\t'.repeat(_level)
		})

		# local variable
		base += '\n'.join(state.local_vars.map(func(x: HenSaveParam):
			return '\t'.repeat(_level + 1) + HenGeneratorVariable.get_var_code_from_param(x, x.name.to_snake_case())))
		
		# add new line if local var is not empty
		base += '\n' if not state.local_vars.is_empty() else ''

		# class-level declarations the actions need, indented line by line
		var action_base: Array = HenGeneratorAction.get_state_base_lines(_save_data, state)

		if not action_base.is_empty():
			base += '\n'.join(action_base.map(func(line: String) -> String:
				return ('\t'.repeat(_level + 1) + line) if not line.is_empty() else line)) + '\n'

		var sub_states: Array = state.get_sub_states(_save_data)

		if not sub_states.is_empty():
			base += get_states_code_with_arr(_save_data, sub_states, _level + 1)
			var sub_state_tokens: Array = []
			var start_sub_state: HenSaveState = null

			for sub_state: HenSaveState in sub_states:
				if sub_state.start:
					start_sub_state = sub_state
				sub_state_tokens.append('add_sub_state("{name_key}", {name}.new(_p){reenter})'.format(({
					name_key = sub_state.name.to_snake_case(),
					name = sub_state.name.to_pascal_case(),
					reenter = ', true' if sub_state.can_reenter else ''
				})))
			
			virtual_tokens.set('_init', {
				tokens = sub_state_tokens,
				params = [ {name = '_p'}]
			})

			if start_sub_state:
				var sub_state_data: String = ''
				var flow_tokens: Array = HenGeneratorAction.get_phase_params(_save_data, start_sub_state, &'enter')

				sub_state_data = (', ' if not flow_tokens.is_empty() else '') + ', '.join(flow_tokens.map(func(x: Dictionary) -> String:
					return HenActionCode.get_default_value_code(_save_data, x.type, false, x.get('category', ''), x.get('data', null))))
				
				# the state enters its own start sub-state: through the controller this
				# reads current_state, which is the TOP level one, so a sub-state with
				# sub-states of its own would hand the name to its ancestor and the
				# call would silently find nothing
				var change_sub_command = 'change_sub_state("{name}"{data})'.format({
					name = start_sub_state.name.to_snake_case(),
					data = sub_state_data
				})

				if not virtual_tokens.has('enter'):
					virtual_tokens['enter'] = {
						tokens = [change_sub_command],
						params = []
					}
				else:
					(virtual_tokens['enter'].tokens as Array).append(change_sub_command)
		else:
			if virtual_tokens.is_empty():
				return base + '\t'.repeat(_level + 1) + 'pass'

		var idx_1: int = 0

		for virtual_name in virtual_tokens.keys():
			var func_tokens: Array = virtual_tokens[virtual_name].tokens
			var func_params: Array = virtual_tokens[virtual_name].params

			if func_tokens.is_empty():
				continue
			
			var params_str: String = ', '.join(func_params.map(
				func(x: Dictionary) -> String:
					return (x.name as String).to_snake_case()
			))

			var func_base: String = '{new_line}{indent}func {name}({params}) -> void:\n{super_call}'.format({
				name = virtual_name,
				new_line = '\n\n' if idx_1 > 0 or not state.get_sub_states(_save_data).is_empty() else '',
				indent = '\t'.repeat(_level + 1),
				super_call = '\t'.repeat(_level + 2) + 'super({params})\n'.format({
					params = params_str
				}) if virtual_name != 'enter' else '',
				params = params_str
			})

			var func_codes: Array = []

			for token in func_tokens:
				if token is String:
					func_codes.append('\t'.repeat(_level + 2) + token)
				elif token is Dictionary:
					func_codes.append(
						''
					)
		
			func_base += '\n'.join(func_codes)
			base += func_base
			idx_1 += 1

		code += base

	return code
