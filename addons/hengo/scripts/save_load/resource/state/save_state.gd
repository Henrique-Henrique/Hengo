@tool
class_name HenSaveState extends HenSaveResTypeWithRoute

@export var flow_outputs: Array[HenSaveFlowParam]
@export var transition_data: Array[HenSaveParam]
@export var is_sub_state: bool
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
@export_multiline var description: String = ''


# a state is its name and its action list now: the route and the scaffolding
# vcnodes that used to stand for each phase are gone
static func create(_is_sub_state: bool = false) -> HenSaveState:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var state: HenSaveState = HenSaveState.new()

	state.id = global.get_new_node_counter()
	state.name = state.get_new_name()
	state.is_sub_state = _is_sub_state

	return state


func get_new_name() -> String:
	return 'state_' + str(id)


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


func get_sub_states(_save_data: HenSaveData) -> Array:
	if not _save_data.sub_states.has(id):
		return []

	return _save_data.sub_states.get(id)


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
	if _property.name in [&'is_sub_state']:
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
