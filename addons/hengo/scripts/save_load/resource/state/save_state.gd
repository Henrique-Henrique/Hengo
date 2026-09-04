@tool
class_name HenSaveState extends HenSaveResTypeWithRoute

const BASE_NAME: String = 'base'

@export var flow_outputs: Array[HenSaveFlowParam]
@export var transition_data: Array[HenSaveParam]
@export var is_sub_state: bool
@export var is_base: bool = false
@export var start: bool = false:
	set(value):
		if start == value: return
		start = value

		var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
		var batch_loading: bool = signal_bus != null and signal_bus.is_batch_loading

		# during load the persisted flags are authoritative; mutating siblings here
		# corrupts them (property load order can misfire this setter)
		if start and not batch_loading:
			_set_other_states_start_false()

		if signal_bus and not batch_loading:
			signal_bus.request_structural_update.emit()
@export var can_reenter: bool = false
@export_multiline var description: String = ''
# set when this state is a use of a macro: its behaviour comes from the definition
# and it holds no actions or sub states of its own
@export var macro_id: StringName
# values bound to the macro inputs, cloned from the definition on creation
@export var macro_inputs: Array[HenSaveParam]
# macro input id -> bind code, for a use that reads a variable instead of a literal
@export var macro_bindings: Dictionary
# macro flow output id -> { state_id: StringName, label: String }, the state of
# this scope a named exit hands control to
@export var flow_targets: Dictionary

# set on the in-memory state that stands for a function body, never persisted: a
# function holds actions like a state does, but changes no state
var is_function_scope: bool = false


# a state is its name and its action list now: the route and the scaffolding
# vcnodes that used to stand for each phase are gone
static func create(_is_sub_state: bool = false, _owner: HenSaveData = null) -> HenSaveState:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var state: HenSaveState = HenSaveState.new()

	# the global counter belongs to the active script, which is not the one being
	# built when a script is created while another is open
	state.id = _owner.new_counter_id() if _owner else global.get_new_node_counter()
	state.name = state.get_new_name()
	state.is_sub_state = _is_sub_state

	return state


func get_new_name() -> String:
	return 'state_' + str(id)


func is_macro_use() -> bool:
	return not str(macro_id).is_empty()


# the definition behind a macro use, null for a plain state
func get_macro(_save_data: HenSaveData) -> HenSaveStateMacro:
	return _save_data.find_macro(macro_id) if _save_data and is_macro_use() else null


# a use clones the macro inputs when it is created, so one that predates a new
# input never draws its slot
func sync_macro_inputs(_save_data: HenSaveData) -> void:
	var macro: HenSaveStateMacro = get_macro(_save_data)

	if not macro:
		return

	var held: Dictionary = {}

	for param: HenSaveParam in macro_inputs:
		held[str(param.id)] = true

	for index: int in macro.inputs.size():
		var declared: HenSaveParam = macro.inputs[index]

		if held.has(str(declared.id)):
			continue

		macro_inputs.insert(mini(index, macro_inputs.size()), HenSaveParam.create(declared.get_data()))


static func create_macro_use(_macro: HenSaveStateMacro, _save_data: HenSaveData) -> HenSaveState:
	var use: HenSaveState = HenSaveState.create(true, _save_data)

	use.macro_id = _macro.id
	# two uses of one macro would be born with the same name, and a machine cannot
	# hold two states called the same
	use.name = _save_data.unique_state_name(_macro.name)

	for param: HenSaveParam in _macro.inputs:
		use.macro_inputs.append(HenSaveParam.create(param.get_data()))

	return use


func add_sub_state(_save_data: HenSaveData) -> HenSaveState:
	var s: HenSaveState = HenSaveState.create(true)

	if not s:
		return null

	if not _save_data.sub_states.has(id):
		_save_data.sub_states.set(id, [])

	var states_list: Array = _save_data.sub_states.get(id)

	if not states_list.has(s):
		states_list.append(s)

	# a sub machine has its own start, and the flag is set after the append: its
	# setter sweeps the siblings by looking for the list holding this state
	if states_list.size() == 1:
		s.start = true

	return s


# a use of a macro runs the states of the definition, which is what makes it
# behave like a state someone filled in by hand
func get_sub_states(_save_data: HenSaveData) -> Array:
	var key: StringName = macro_id if is_macro_use() else id

	if not _save_data.sub_states.has(key):
		return []

	return _save_data.sub_states.get(key)


func _get_resource_info() -> Dictionary:
	var map_dep: HenMapDependencies = Engine.get_singleton(&'MapDependencies')

	if not map_dep:
		return {name = name, type = &'Variant'}

	for project_ast: HenMapDependencies.ProjectAST in map_dep.ast_list.values():
		for state_res: HenSaveState in project_ast.states:
			if state_res.id == id:
				if project_ast.identity:
					return {name = project_ast.identity.name, type = project_ast.identity.type}
				break

	return {name = name, type = &'Variant'}


func _validate_property(_property: Dictionary) -> void:
	super (_property)
	if _property.name in [&'is_sub_state', &'is_base', &'macro_id', &'macro_inputs', &'macro_bindings', &'flow_targets']:
		_property.usage = PROPERTY_USAGE_STORAGE


func _set_other_states_start_false() -> void:
	for s: HenSaveState in _get_sibling_states():
		if s != self and s.start:
			s.start = false


# the list this state belongs to, searched in the open scripts. a state loaded
# from disk (another script) belongs to none, so it can't touch their flags
func _get_sibling_states() -> Array:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global: return []

	var candidates: Array[HenSaveData] = global.OPEN_SCRIPTS.duplicate()

	if global.SAVE_DATA and not candidates.has(global.SAVE_DATA):
		candidates.append(global.SAVE_DATA)

	for save_data: HenSaveData in candidates:
		if not save_data: continue

		if is_sub_state:
			for state_id_key in save_data.sub_states.keys():
				var sub_states: Array = save_data.sub_states.get(state_id_key)
				if sub_states.has(self ):
					return sub_states
		elif save_data.states.has(self ):
			return save_data.states

	return []
