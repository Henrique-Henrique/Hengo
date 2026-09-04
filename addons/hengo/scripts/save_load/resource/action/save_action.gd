@tool
class_name HenSaveAction extends HenSaveResType

# execution order of the lifecycle phases, the order codegen emits them in.
# physics runs on the fixed tick, which is where a body must be moved
const PHASE_ORDER: Array[StringName] = [&'enter', &'update', &'physics', &'exit']

# durable link to the macro definition (get_id()) — survives file/path renames
@export var macro_id: StringName
# bound parameters, cloned from the macro inputs (values default for now)
@export var inputs: Array[HenSaveParam]
# input id -> bound value source (snake name of a var/prop); empty/absent = literal
@export var input_bindings: Dictionary
# input id -> HenSaveActionExpression (free-text expression); absent = not an expression
@export var input_expressions: Dictionary
# input id -> { action: HenSaveAction, output: StringName }
@export var input_actions: Dictionary
# input id -> { action_id: StringName, output: StringName }. unlike an inline action
# this reads a value another step already produced instead of running one of its own
@export var input_wires: Dictionary
# lifecycle phase this action runs in: enter (once) | update (per-frame) |
# physics (fixed tick) | exit
@export var phase: StringName = &'update'
# flow output id -> { state_id: StringName, label: String }; a branch with no
# entry emits `pass`. the target is stored by id so renames can't break it
@export var branches: Dictionary
# nested action list a loop macro runs per iteration; empty for every other macro
@export var body_actions: Array[HenSaveAction]
# flow output id -> Array[HenSaveAction] the branch runs while staying in this
# state. a branch can run steps, transition, or both: the steps go first
@export var branch_actions: Dictionary
# skipped by codegen while set, so a step can be muted without losing its values
@export var disabled: bool = false
# optional name the user gave this instance; empty falls back to the macro name
@export var label: String = ''


static func create(_macro: HenSaveMacro) -> HenSaveAction:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var action: HenSaveAction = HenSaveAction.new()

	action.id = global.get_new_node_counter()
	action.macro_id = _macro.id
	action.name = _macro.name
	action.phase = default_phase(_macro)

	for param: HenSaveParam in _macro.inputs:
		action.inputs.append(HenSaveParam.create(param.get_data()))

	return action


# a branching action used to keep its steps in body_actions, before every branch
# could hold its own. the macro names the branch they belong to, so the move never
# guesses from declaration order. idempotent: an already moved list is empty
static func migrate_branch_bodies(_save_data: HenSaveData) -> void:
	if not _save_data:
		return

	for state: HenSaveState in _save_data.states:
		_migrate_list(_save_data.get_state_actions(state.id))

	for sub_list: Variant in _save_data.sub_states.values():
		for state: HenSaveState in sub_list:
			_migrate_list(_save_data.get_state_actions(state.id))


static func _migrate_list(_actions: Array) -> void:
	for action: HenSaveAction in _actions:
		for list: Array in HenGeneratorAction.nested_lists(action):
			_migrate_list(list)

		if action.body_actions.is_empty():
			continue

		var branch: StringName = HenActionsPanel.body_branch_of(action.macro_id)

		if branch.is_empty():
			continue

		var moved: Array[HenSaveAction] = []

		moved.assign(action.body_actions)
		moved.append_array(HenGeneratorAction.branch_steps(action, str(branch)))

		action.branch_actions[str(branch)] = moved
		action.body_actions.clear()


# a question that only branched used to need a twin action to be read as a value,
# and the twin retired once the question started answering both ways. same inputs
# and same output id, so the id is all that moves
const RETIRED_MACROS: Dictionary = {check = &'compare'}


static func migrate_retired_macros(_save_data: HenSaveData) -> void:
	if not _save_data:
		return

	for state: HenSaveState in _save_data.states:
		_migrate_ids(_save_data.get_state_actions(state.id))

	for sub_list: Variant in _save_data.sub_states.values():
		for state: HenSaveState in sub_list:
			_migrate_ids(_save_data.get_state_actions(state.id))


static func _migrate_ids(_actions: Array) -> void:
	for action: HenSaveAction in _actions:
		for list: Array in HenGeneratorAction.nested_lists(action):
			_migrate_ids(list)

		for nested: Variant in action.input_actions.values():
			var child: HenSaveAction = HenGeneratorAction._inline_child(nested)

			if child:
				_migrate_ids([child])

		if RETIRED_MACROS.has(str(action.macro_id)):
			action.macro_id = RETIRED_MACROS[str(action.macro_id)]


# an action clones the macro inputs when it is created, so one that predates a new
# input never draws its slot. matched by id, placed where the macro declares it
static func sync_macro_inputs(_save_data: HenSaveData) -> void:
	if not _save_data:
		return

	for state: HenSaveState in _save_data.states:
		_sync_list(_save_data.get_state_actions(state.id))

	for sub_list: Variant in _save_data.sub_states.values():
		for state: HenSaveState in sub_list:
			_sync_list(_save_data.get_state_actions(state.id))


static func _sync_list(_actions: Array) -> void:
	for action: HenSaveAction in _actions:
		for list: Array in HenGeneratorAction.nested_lists(action):
			_sync_list(list)

		for nested: Variant in action.input_actions.values():
			var child: HenSaveAction = HenGeneratorAction._inline_child(nested)

			if child:
				_sync_list([child])

		sync_action_inputs(action, HenActionsPanel.find_macro(action.macro_id))


# a macro script is fixed, so an action of it only ever misses a slot that was
# added later. a definition of the script can be renamed and retyped while its
# actions exist, and there the clone has to follow the declaration
static func sync_action_inputs(_action: HenSaveAction, _macro: HenSaveMacro) -> void:
	if not _macro:
		return

	if not HenFunctionMacro.is_function_macro(_action.macro_id):
		_insert_missing_inputs(_action, _macro)
		return

	var kept: Dictionary = {}

	for param: HenSaveParam in _action.inputs:
		kept[str(param.id)] = param

	var synced: Array[HenSaveParam] = []

	for declared: HenSaveParam in _macro.inputs:
		var held: HenSaveParam = kept.get(str(declared.id))

		synced.append(_sync_param(held, declared) if held else HenSaveParam.create(declared.get_data()))
		kept.erase(str(declared.id))

	_action.inputs = synced

	# a slot the definition dropped takes whatever was feeding it with it
	for id: Variant in kept:
		for store: Dictionary in [_action.input_bindings, _action.input_expressions, _action.input_actions, _action.input_wires]:
			store.erase(str(id))


# name and shape come from the declaration; the value stays unless the type moved
static func _sync_param(_param: HenSaveParam, _declared: HenSaveParam) -> HenSaveParam:
	if _param.type != _declared.type:
		# the type setter clears the value, which is what a retyped slot needs
		_param.type = _declared.type
		_param.default_value = _declared.default_value

	_param.name = _declared.name
	_param.options = _declared.options.duplicate()
	_param.option_labels = _declared.option_labels.duplicate()
	_param.raw = _declared.raw
	_param.lvalue = _declared.lvalue
	_param.bind_only = _declared.bind_only
	_param.optional = _declared.optional
	_param.doc = _declared.doc
	_param.picker = _declared.picker
	_param.type_from = _declared.type_from

	return _param


static func _insert_missing_inputs(_action: HenSaveAction, _macro: HenSaveMacro) -> void:
	var held: Dictionary = {}

	for param: HenSaveParam in _action.inputs:
		held[str(param.id)] = true

	for index: int in _macro.inputs.size():
		var declared: HenSaveParam = _macro.inputs[index]

		if held.has(str(declared.id)):
			continue

		_action.inputs.insert(mini(index, _action.inputs.size()), HenSaveParam.create(declared.get_data()))


func get_new_name() -> String:
	return 'action_' + str(id)


# phases the macro declares as flow inputs; update is always offered (it can fall
# back to the _process override body). read from the pool — no disk access
static func supported_phases(_macro: HenSaveMacro) -> Array:
	var declared: Dictionary = {}
	for f: HenSaveFlowParam in _macro.flow_inputs:
		declared[str(f.id)] = true

	var phases: Array = []
	if declared.has('enter'):
		phases.append(&'enter')

	# update is offered when the macro declares it, or has no flow inputs (its body
	# comes from the _process override); an enter-only tween must not land there
	if declared.is_empty() or declared.has('update'):
		phases.append(&'update')

	# branching from physics is safe, the ban is exit-only
	if declared.has('physics'):
		phases.append(&'physics')

	# a branching action can't run on exit: change_state calls exit() BEFORE swapping
	# current_state, so transitioning from there re-enters it forever
	if declared.has('exit') and _optional_branches(_macro):
		phases.append(&'exit')

	return phases


# an action whose branches are all optional keeps working with none of them wired,
# so exit stays on the table until one is
static func _optional_branches(_macro: HenSaveMacro) -> bool:
	for flow: HenSaveFlowParam in _macro.flow_outputs:
		if not flow.optional:
			return false

	return true


# a new action starts on a phase the macro actually has a body for, so it never
# lands on a silent phase (e.g. an enter-only macro must not default to update)
static func default_phase(_macro: HenSaveMacro) -> StringName:
	var declared: Dictionary = {}
	for f: HenSaveFlowParam in _macro.flow_inputs:
		declared[str(f.id)] = true

	# the macro can name the phase it wants, as long as it has a body for it
	if not _macro.default_phase.is_empty() and declared.has(str(_macro.default_phase)):
		return _macro.default_phase

	# no flow inputs at all -> the macro uses the _process override (update only)
	if declared.is_empty() or declared.has('update'):
		return &'update'
	if declared.has('enter'):
		return &'enter'
	if declared.has('exit'):
		return &'exit'

	return &'update'
