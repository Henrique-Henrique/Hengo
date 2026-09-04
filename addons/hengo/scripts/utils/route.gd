@tool
class_name HenRoute extends RefCounted

# the scope the canvas edits. an empty stack is the script itself, and every entry
# opens a definition reached from the one before it

const KIND_FUNCTION: StringName = &'function'
const KIND_MACRO: StringName = &'macro'

const ICONS: Dictionary = {
	script = 'file-text',
	function = 'square-function',
	macro = 'box'
}


static func _global() -> HenGlobal:
	return Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null


static func _emit() -> void:
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus') if Engine.has_singleton(&'SignalBus') else null

	# the palette offers the finish of the open function, so it changes with the scope
	HenActionPool.invalidate()

	if signal_bus:
		signal_bus.route_changed.emit()


static func stack() -> Array:
	var global: HenGlobal = _global()

	return global.ROUTE if global else []


static func is_base() -> bool:
	return stack().is_empty()


static func current() -> Dictionary:
	var route: Array = stack()

	return route.back() if not route.is_empty() else {}


static func current_kind() -> StringName:
	return StringName(str(current().get('kind', '')))


static func current_id() -> StringName:
	return StringName(str(current().get('id', '')))


# a definition reached from inside the open one nests under it; one picked from
# the sidebar starts a path of its own, since the sidebar lists the script itself.
# opening a scope already on the stack means going back to it, never nesting it
static func enter(_kind: StringName, _id: StringName, _nested: bool = false) -> void:
	var global: HenGlobal = _global()

	if not global or str(_id).is_empty():
		return

	for index: int in global.ROUTE.size():
		var entry: Dictionary = global.ROUTE[index]

		if StringName(str(entry.kind)) == _kind and StringName(str(entry.id)) == _id:
			go_to(index)
			return

	if not _nested:
		global.ROUTE.clear()

	global.ROUTE.append({kind = _kind, id = _id})
	_emit()


# the definition an action list belongs to: the function whose body it is, or the
# macro whose machine holds the state. null when it is a state of the script
static func definition_of(_save_data: HenSaveData, _scope_id: StringName) -> HenSaveResType:
	if not _save_data or str(_scope_id).is_empty():
		return null

	var func_res: HenSaveFunc = _save_data.find_function(_scope_id)

	if func_res:
		return func_res

	var state: HenSaveState = HenGeneratorAction.find_state(_save_data, _scope_id)

	while state:
		var holder: StringName = _holder_key(_save_data, state)

		if holder.is_empty():
			return null

		var macro: HenSaveStateMacro = _save_data.find_macro(holder)

		if macro:
			return macro

		state = HenGeneratorAction.find_state(_save_data, holder)

	return null


# the sub_states key the state is filed under: a state id, or the id of the macro
# whose machine it belongs to
static func _holder_key(_save_data: HenSaveData, _state: HenSaveState) -> StringName:
	for key: Variant in _save_data.sub_states:
		if (_save_data.sub_states[key] as Array).has(_state):
			return StringName(str(key))

	return &''


# the stack that opens the definition an action list belongs to
static func stack_for(_save_data: HenSaveData, _scope_id: StringName) -> Array:
	var definition: HenSaveResType = definition_of(_save_data, _scope_id)

	if definition is HenSaveFunc:
		return [{kind = KIND_FUNCTION, id = definition.id}]

	if definition is HenSaveStateMacro:
		return [{kind = KIND_MACRO, id = definition.id}]

	return []


static func go_base() -> void:
	var global: HenGlobal = _global()

	if not global or global.ROUTE.is_empty():
		return

	global.ROUTE.clear()
	_emit()


# keeps the entries up to _index, so the crumb picked becomes the open scope
static func go_to(_index: int) -> void:
	var global: HenGlobal = _global()

	if not global:
		return

	if _index < 0:
		go_base()
		return

	if _index >= global.ROUTE.size() - 1:
		return

	global.ROUTE.resize(_index + 1)
	_emit()


static func go_up() -> void:
	go_to(stack().size() - 2)


# swaps the whole stack at once, for the paths that restore a view instead of
# navigating it (switching scripts, undoing a delete)
static func set_stack(_entries: Array) -> void:
	var global: HenGlobal = _global()

	if not global or _entries == global.ROUTE:
		return

	# assign and not =: the stack is typed, and a plain array cannot be given to it
	global.ROUTE.assign(_entries.duplicate(true))
	_emit()


# every script keeps its own open scope: switching tabs parks the current stack
# and brings back the one that tab was left on
static func sync_to_script(_script_id: String) -> void:
	var global: HenGlobal = _global()

	if not global or global.ROUTE_OWNER == _script_id:
		return

	if not global.ROUTE_OWNER.is_empty():
		global.ROUTE_VIEWS[global.ROUTE_OWNER] = global.ROUTE.duplicate(true)

	global.ROUTE_OWNER = _script_id
	set_stack(global.ROUTE_VIEWS.get(_script_id, []))


# drops the entries whose definition is gone, so a deleted function cannot leave
# the canvas pointing at nothing
static func validate(_save_data: HenSaveData) -> void:
	var global: HenGlobal = _global()

	if not global or global.ROUTE.is_empty():
		return

	var valid: int = 0

	for entry: Dictionary in global.ROUTE:
		if not _resolve(_save_data, StringName(str(entry.kind)), StringName(str(entry.id))):
			break

		valid += 1

	if valid == global.ROUTE.size():
		return

	global.ROUTE.resize(valid)
	_emit()


static func _resolve(_save_data: HenSaveData, _kind: StringName, _id: StringName) -> HenSaveResType:
	if not _save_data:
		return null

	if _kind == KIND_FUNCTION:
		return _save_data.find_function(_id)

	if _kind == KIND_MACRO:
		return _save_data.find_macro(_id)

	return null


static func resolve(_save_data: HenSaveData, _entry: Dictionary) -> HenSaveResType:
	return _resolve(_save_data, StringName(str(_entry.get('kind', ''))), StringName(str(_entry.get('id', ''))))


# the open definition, null while the script itself is being edited
static func current_scope(_save_data: HenSaveData) -> HenSaveResType:
	return resolve(_save_data, current())


# the whole path shown in the status bar, the script first
static func crumbs(_save_data: HenSaveData) -> Array[Dictionary]:
	var out: Array[Dictionary] = []

	if not _save_data or not _save_data.identity:
		return out

	out.append({kind = &'script', id = _save_data.identity.id, name = _save_data.identity.name, index = -1})

	var index: int = 0

	for entry: Dictionary in stack():
		var res: HenSaveResType = resolve(_save_data, entry)

		if not res:
			break

		out.append({kind = StringName(str(entry.kind)), id = res.id, name = res.name, index = index})
		index += 1

	return out


# the cam and the undo stack are per scope: an entry restores a list into the one
# it was taken from
static func key(_script_id: String) -> String:
	var parts: PackedStringArray = PackedStringArray([_script_id])

	for entry: Dictionary in stack():
		parts.append(str(entry.kind) + ':' + str(entry.id))

	return '/'.join(parts)
