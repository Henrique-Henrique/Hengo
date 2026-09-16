@tool
class_name HenSearchIndex extends RefCounted

const KIND_COLLECTION: StringName = &'collection'
const KIND_SCRIPT: StringName = &'script'
const KIND_STATE: StringName = &'state'
const KIND_ACTION: StringName = &'action'
const KIND_FUNCTION: StringName = &'function'
const KIND_MACRO: StringName = &'macro'
const KIND_VARIABLE: StringName = &'variable'

# breaks ties between equal scores, so a definition shows before a step using its name
const KIND_ORDER: Array[StringName] = [
	KIND_SCRIPT, KIND_STATE, KIND_FUNCTION, KIND_MACRO, KIND_VARIABLE, KIND_ACTION, KIND_COLLECTION
]

const KIND_LABELS: Dictionary = {
	collection = 'Collection',
	script = 'Script',
	state = 'State',
	action = 'Action',
	function = 'Function',
	macro = 'Macro',
	variable = 'Variable'
}

const KIND_ICONS: Dictionary = {
	collection = 'layers',
	script = 'file-text',
	state = 'activity',
	function = 'square-function',
	macro = 'box',
	variable = 'variable'
}

const KIND_COLORS: Dictionary = {
	collection = '#9fb2c7',
	script = '#9fb2c7',
	state = '#4a8fd4',
	action = '#7c93ff',
	function = '#b05353',
	macro = '#a06fd0',
	variable = '#7cc0ff'
}

const MAX_RESULTS: int = 200
const PATH_SEPARATOR: String = ' › '

# script id -> { time: int, collection: String, records: Array[Dictionary] }
static var _disk_cache: Dictionary = {}


# the macro pools are swapped on the main thread whenever the active script changes
static func macro_snapshot() -> Dictionary:
	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null
	var out: Dictionary = {}

	if not global:
		return out

	if global.action_macros.is_empty() and global.script_macros.is_empty():
		HenScriptMacroLoader.load_script_macros()
		HenScriptMacroLoader.load_native_actions()

	for list: Array in [global.action_macros, global.script_macros]:
		for macro: HenSaveMacro in list:
			if not out.has(str(macro.id)):
				out[str(macro.id)] = {name = macro.name, icon = macro.icon, color = macro.color}

	return out


static func open_records(_macros: Dictionary) -> Array[Dictionary]:
	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null
	var out: Array[Dictionary] = []

	if not global or not global.ACTIVE_COLLECTION:
		return out

	for save_data: HenSaveData in global.OPEN_SCRIPTS:
		out.append_array(records_of(save_data, global.ACTIVE_COLLECTION.id, global.ACTIVE_COLLECTION.name, _macros))

	return out


static func records_of(_save_data: HenSaveData, _collection_id: StringName, _collection_name: String, _macros: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []

	if not _save_data or not _save_data.identity:
		return out

	var identity: HenSaveDataIdentity = _save_data.identity
	var base: Dictionary = {
		collection_id = str(_collection_id),
		collection_name = _collection_name,
		script_id = str(identity.id),
		script_name = identity.name
	}

	var script_record: Dictionary = _record(base, KIND_SCRIPT, str(identity.id), identity.name, _collection_name)

	script_record.detail = str(identity.type)
	script_record.class_icon = str(identity.type)
	out.append(script_record)

	var scope_names: Dictionary = {}

	for state: HenSaveState in HenGeneratorAction._all_states(_save_data):
		scope_names[str(state.id)] = state.name

	for func_res: HenSaveFunc in _save_data.functions:
		scope_names[str(func_res.id)] = func_res.name

	for macro: HenSaveStateMacro in _save_data.macros:
		scope_names[str(macro.id)] = macro.name

	for state: HenSaveState in _save_data.states:
		out.append(_state_record(base, _save_data, state, identity.name))

	for key: Variant in _save_data.sub_states:
		var holder: String = identity.name + PATH_SEPARATOR + str(scope_names.get(str(key), ''))

		for state: HenSaveState in _save_data.sub_states[key]:
			out.append(_state_record(base, _save_data, state, holder))

	for func_res: HenSaveFunc in _save_data.functions:
		out.append(_record(base, KIND_FUNCTION, str(func_res.id), func_res.name, identity.name))

	for macro: HenSaveStateMacro in _save_data.macros:
		out.append(_record(base, KIND_MACRO, str(macro.id), macro.name, identity.name))

	for variable: HenSaveVar in _save_data.variables:
		var record: Dictionary = _record(base, KIND_VARIABLE, str(variable.id), variable.name, identity.name)

		record.detail = str(variable.type)
		out.append(record)

	for scope_id: Variant in _save_data.state_actions:
		var is_function: bool = _save_data.find_function(StringName(str(scope_id))) != null
		var context: String = identity.name + PATH_SEPARATOR + str(scope_names.get(str(scope_id), ''))

		_walk_actions(out, _save_data.state_actions[scope_id], {
			base = base,
			save_data = _save_data,
			scope_id = str(scope_id),
			context = context,
			is_function = is_function,
			macros = _macros
		}, &'')

	return out


static func _walk_actions(_out: Array[Dictionary], _list: Array, _scope: Dictionary, _inherited_phase: StringName) -> void:
	for action: Variant in _list:
		if not action is HenSaveAction:
			continue

		var step: HenSaveAction = action
		var phase: StringName = _inherited_phase if not _inherited_phase.is_empty() else step.phase

		_out.append(_action_record(step, _scope, phase))

		for entry: Variant in step.input_actions.values():
			var nested: Variant = (entry as Dictionary).get('action') if entry is Dictionary else null

			if nested is HenSaveAction:
				_walk_actions(_out, [nested], _scope, phase)

		for nested_list: Array in HenGeneratorAction.nested_lists(step):
			_walk_actions(_out, nested_list, _scope, phase)


static func _action_record(_action: HenSaveAction, _scope: Dictionary, _phase: StringName) -> Dictionary:
	var look: Dictionary = _macro_look(_action.macro_id, _scope.save_data, _scope.macros)
	var title: String = _action.label.strip_edges()
	var macro_name: String = str(look.get('name', ''))

	if title.is_empty():
		title = macro_name if not macro_name.is_empty() else _action.name

	var record: Dictionary = _record(_scope.base, KIND_ACTION, str(_action.id), title, _scope.context)

	record.state_id = _scope.scope_id
	record.detail = macro_name if macro_name != title else ''
	record.icon = str(look.get('icon', ''))
	record.color = str(look.get('color', ''))
	record.phase = '' if _scope.is_function else str(_phase)
	record.disabled = _action.disabled

	return record


# resolved without HenFunctionMacro.macro_for, whose static caches are not thread safe
static func _macro_look(_macro_id: StringName, _save_data: HenSaveData, _macros: Dictionary) -> Dictionary:
	if HenFunctionMacro.is_function_macro(_macro_id):
		var func_res: HenSaveFunc = _save_data.find_function(HenFunctionMacro.function_id_of(_macro_id))

		if not func_res:
			return {}

		if HenFunctionMacro.is_return_macro(_macro_id):
			return {name = 'Finish ' + func_res.name, icon = HenFunctionMacro.RETURN_ICON, color = HenFunctionMacro.COLOR}

		return {name = func_res.name, icon = HenFunctionMacro.ICON, color = HenFunctionMacro.COLOR}

	if HenMacroHookMacro.is_hook_macro(_macro_id):
		var parts: PackedStringArray = HenMacroHookMacro.parts_of(_macro_id)
		var macro_res: HenSaveStateMacro = _save_data.find_macro(StringName(parts[0])) if parts.size() == 2 else null
		var flow: HenSaveFlowParam = macro_res.find_flow_input(StringName(parts[1])) if macro_res else null

		if not flow:
			return {}

		return {name = 'Run ' + flow.name, icon = HenMacroHookMacro.ICON, color = HenMacroHookMacro.COLOR}

	return _macros.get(str(_macro_id), {})


static func _state_record(_base: Dictionary, _save_data: HenSaveData, _state: HenSaveState, _context: String) -> Dictionary:
	var record: Dictionary = _record(_base, KIND_STATE, str(_state.id), _state.name, _context)
	var macro: HenSaveStateMacro = _state.get_macro(_save_data)

	record.state_id = str(_state.id)
	record.detail = macro.name if macro else ''
	record.color = HenActionVisuals.state_color(str(_state.id)).to_html(false)

	return record


static func _record(_base: Dictionary, _kind: StringName, _id: String, _title: String, _context: String) -> Dictionary:
	var record: Dictionary = _base.duplicate()

	record.kind = _kind
	record.id = _id
	record.state_id = ''
	record.title = _title
	record.context = _context
	record.detail = ''
	record.icon = str(KIND_ICONS.get(str(_kind), ''))
	record.class_icon = ''
	record.color = str(KIND_COLORS.get(str(_kind), ''))
	record.phase = ''
	record.disabled = false

	return record


# the active collection comes from memory, where the unsaved edits live
static func project_plan(_active_id: String, _open_records: Array[Dictionary]) -> Array:
	var items: Array = []

	if not DirAccess.dir_exists_absolute(HenEnums.HENGO_COLLECTION_PATH):
		items.append(_open_records)
		return items

	for collection: HenSaveCollection in _collections():
		items.append([collection_record(collection)])

		if str(collection.id) == _active_id:
			items.append(_open_records)
			continue

		for script_id: StringName in collection.script_ids:
			items.append({script_id = script_id, collection = collection})

	return items


static func collection_records(_skip_id: String = '') -> Array[Dictionary]:
	var out: Array[Dictionary] = []

	for collection: HenSaveCollection in _collections():
		if str(collection.id) != _skip_id:
			out.append(collection_record(collection))

	return out


static func collection_record(_collection: HenSaveCollection) -> Dictionary:
	var record: Dictionary = _record({
		collection_id = str(_collection.id),
		collection_name = _collection.name,
		script_id = '',
		script_name = ''
	}, KIND_COLLECTION, str(_collection.id), _collection.name, '')

	record.detail = str(_collection.script_ids.size()) + ' scripts'

	return record


static func _collections() -> Array[HenSaveCollection]:
	var out: Array[HenSaveCollection] = []

	if not DirAccess.dir_exists_absolute(HenEnums.HENGO_COLLECTION_PATH):
		return out

	for dir_name: String in DirAccess.get_directories_at(HenEnums.HENGO_COLLECTION_PATH):
		var path: String = HenEnums.HENGO_COLLECTION_PATH.path_join(dir_name).path_join(HenEnums.COLLECTION_FILE)
		var collection: HenSaveCollection = ResourceLoader.load(path, '', ResourceLoader.CACHE_MODE_IGNORE) as HenSaveCollection if FileAccess.file_exists(path) else null

		if collection:
			out.append(collection)

	return out


# a save loaded on a worker thread in the editor comes back without its script
static func read_script(_script_id: StringName, _collection: HenSaveCollection, _macros: Dictionary) -> Array[Dictionary]:
	var dir: String = HenUtils.get_script_dir(_script_id)
	var path: String = dir.path_join(HenEnums.SAVE_FILE)

	if dir.is_empty() or not FileAccess.file_exists(path):
		return []

	var time: int = FileAccess.get_modified_time(path)
	var stamp: String = str(_collection.id) + '/' + _collection.name
	var cached: Dictionary = _disk_cache.get(str(_script_id), {})

	if not cached.is_empty() and cached.time == time and cached.collection == stamp:
		return cached.records

	HenGlobal.set_thread_quiet(true)
	var save_data: HenSaveData = ResourceLoader.load(path, '', ResourceLoader.CACHE_MODE_IGNORE) as HenSaveData
	HenGlobal.set_thread_quiet(false)

	if not save_data:
		return []

	var records: Array[Dictionary] = records_of(save_data, _collection.id, _collection.name, _macros)

	_disk_cache[str(_script_id)] = {time = time, collection = stamp, records = records}

	return records


static func search(_records: Array[Dictionary], _query: String, _limit: int = MAX_RESULTS) -> Array[Dictionary]:
	var query: String = _query.strip_edges().to_lower()
	var out: Array[Dictionary] = []

	if query.is_empty():
		for record: Dictionary in _records:
			if record.kind == KIND_SCRIPT or record.kind == KIND_COLLECTION:
				out.append(record)

				if out.size() >= _limit:
					break

		return out

	var scored: Array = []

	for record: Dictionary in _records:
		var score: int = HenSearch.score_only(query, str(record.title).to_lower())

		if score <= 0 and not str(record.detail).is_empty():
			score = HenSearch.score_only(query, str(record.detail).to_lower()) / 4

		if score > 0:
			scored.append([score, KIND_ORDER.find(record.kind), record])

	scored.sort_custom(func(_a: Array, _b: Array) -> bool:
		if _a[0] != _b[0]:
			return _a[0] > _b[0]

		return _a[1] < _b[1]
	)

	for entry: Array in scored.slice(0, _limit):
		out.append(entry[2])

	return out
