class_name HenActionTestSuite extends HenTestSuite

# shared ground for the action codegen suites: the fixture macros, the state
# under test and the helpers that register a macro and hang an action on it.

const FIX_PHASES: String = 'res://tests/fixtures/action_phases.gd'
const FIX_TYPED: String = 'res://tests/fixtures/action_typed.gd'
const FIX_PROCESS: String = 'res://tests/fixtures/action_process.gd'
const FIX_TRANSITION: String = 'res://addons/hengo/actions/flow/transition.gd'

# single-output, multi-output and branching, one per inline case
const FIX_MATH: String = 'res://addons/hengo/actions/math/math_operator.gd'


var state: HenSaveState


func before_test() -> void:
	super()
	# a type that actually has float/vector props, so property binding has a target
	save_data.identity.type = 'Sprite2D'
	state = save_data.add_state(false)
	state.name = 'state test'


# mirrors HenScriptMacroLoader._load_macro_script so the tests exercise the real
# pool shape without depending on the native actions shipped with the addon
func _register(_path: String) -> HenSaveMacro:
	var instance: HenScriptMacroBase = (load(_path) as GDScript).new()
	var macro: HenSaveMacro = HenSaveMacro.new()

	macro.id = instance.get_id()
	macro.name = _path.get_file().get_basename()
	macro.is_script_macro = true
	macro.script_path = _path

	for input: Dictionary in instance.get_inputs():
		macro.inputs.append(HenSaveParam.create(input))

	for flow: Dictionary in instance.get_flow_inputs():
		macro.flow_inputs.append(HenSaveFlowParam.create(flow))

	for flow: Dictionary in instance.get_flow_outputs():
		macro.flow_outputs.append(HenSaveFlowParam.create(flow))

	macro.target_classes.assign(instance.get_target_classes())

	(Engine.get_singleton(&'Global') as HenGlobal).action_macros.append(macro)
	return macro


func _add_action(_macro: HenSaveMacro, _phase: StringName) -> HenSaveAction:
	var action: HenSaveAction = HenSaveAction.create(_macro)
	action.phase = _phase
	save_data.add_state_action(state.id, action)
	return action


func _expression(_code: String, _words: Array, _bindings: Dictionary, _literals: Dictionary) -> HenSaveActionExpression:
	var expr: HenSaveActionExpression = HenSaveActionExpression.new()
	expr.code = _code

	var words: Array[HenSaveParam] = []
	for word_name: String in _words:
		var param: HenSaveParam = HenSaveParam.create({name = word_name, type = 'Variant'})
		if _literals.has(word_name):
			param.default_value = _literals[word_name]
		words.append(param)

	expr.words = words
	expr.word_bindings = _bindings
	return expr


func _math_child(_a: Variant, _op: String, _b: Variant) -> HenSaveAction:
	var child: HenSaveAction = HenSaveAction.create(_register(FIX_MATH))

	for param: HenSaveParam in child.inputs:
		match str(param.id):
			'a': param.default_value = _a
			'op': param.default_value = _op
			'b': param.default_value = _b

	return child


# a second script the transition can target, registered as if it were open
func _other_script(_state_name: String) -> Dictionary:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var other: HenSaveData = HenSaveData.new()

	other.identity = HenSaveDataIdentity.create(str(ResourceUID.create_id()), 'Node', 'Player')
	other.counter = 1

	var target: HenSaveState = HenSaveState.new()
	target.id = StringName('other_' + _state_name)
	target.name = _state_name
	other.states.append(target)

	global.OPEN_SCRIPTS.append(other)

	return {save_data = other, state = target}


func _cross_branch(_key: String, _other: Dictionary, _extra: Dictionary) -> Dictionary:
	var branch: Dictionary = {
		state_id = _other.state.id,
		script_id = _other.save_data.identity.id,
		label = ''
	}
	branch.merge(_extra)
	return branch


func _option_names(_inspector: HenInspector, _action: HenSaveAction, _key: String) -> Array:
	var macro_params: Dictionary = {}

	for p: HenSaveParam in HenActionsPanel.find_macro(_action.macro_id).inputs:
		macro_params[str(p.id)] = p

	var param: HenSaveParam = null

	for p: HenSaveParam in _action.inputs:
		if str(p.id) == _key:
			param = p

	var options: Array = _inspector._build_bind_options({
		param = param,
		bind_store = _action.input_bindings,
		bind_key = _key,
		macro_params = macro_params,
		indent = 0
	})

	return options.map(func(o: Dictionary) -> String: return str(o.name))


func _nested(_macro_id: StringName) -> HenSaveAction:
	var action := HenSaveAction.new()
	action.macro_id = _macro_id
	action.id = (Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()
	return action


# storing a result is a Set Value fed by a wire now, so a test that only needs the
# producer to have a reader asks for one of these
func _sink(_producer: HenSaveAction, _output: StringName, _target: HenSaveVar, _phase: StringName = &'') -> HenSaveAction:
	var sink: HenSaveAction = HenSaveAction.create(HenActionsPanel.find_macro(&'set_value'))

	sink.phase = _phase if not str(_phase).is_empty() else _producer.phase
	sink.input_bindings['target'] = HenUtils.bind_code_for_var(_target)
	sink.input_wires['value'] = {action_id = StringName(str(_producer.id)), output = _output}

	save_data.add_state_action(state.id, sink)

	return sink
