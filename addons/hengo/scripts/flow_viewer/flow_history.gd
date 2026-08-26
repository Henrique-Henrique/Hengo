@tool
class_name HenFlowHistory
extends RefCounted

# the one undo stack of the plugin. the save data mutates its resources in place,
# so a method pair would hold a reference to the very object that changed: each
# entry carries a copy of what the edit touched from before and after it, and undo
# puts a fresh copy back

const LIMIT: int = 60

var _undo: Array[Dictionary] = []
var _redo: Array[Dictionary] = []
var _pending: Dictionary = {}
var _recording: bool = false


# an array and not one id: moving a step to another state edits two lists, and
# an entry that restores only one of them corrupts the graph on undo
func begin(_save_data: HenSaveData, _state_ids: Array) -> void:
	if not _save_data or not _save_data.identity or _state_ids.is_empty():
		return

	# a second begin before the commit would snapshot the half-edited list
	if not _pending.is_empty():
		return

	var before: Dictionary = {}

	for state_id: StringName in _state_ids:
		if not state_id.is_empty():
			before[state_id] = snapshot(_save_data, state_id)

	if before.is_empty():
		return

	_pending = {script_id = String(_save_data.identity.id), before = before}


# a synchronous edit never touches _pending: that field belongs to the popup
# lifecycle, and a popup that closed without committing used to make the next
# menu or shortcut edit silently record the wrong `before`
func record(_save_data: HenSaveData, _state_ids: Array, _label: String, _mutation: Callable) -> bool:
	if not _save_data or not _save_data.identity or _state_ids.is_empty():
		return false

	# an outer record already owns this edit, and it may span more states than the
	# inner one knows about: nesting must not push a second entry
	if _recording:
		return _mutation.call()

	var before: Dictionary = {}

	for state_id: StringName in _state_ids:
		if not state_id.is_empty():
			before[state_id] = snapshot(_save_data, state_id)

	if before.is_empty():
		return false

	_recording = true

	var ok: bool = _mutation.call()

	_recording = false

	if not ok:
		return false

	var after: Dictionary = {}
	var changed: bool = false

	for state_id: StringName in before:
		after[state_id] = snapshot(_save_data, state_id)

		if digest(after[state_id]) != digest(before[state_id]):
			changed = true

	if not changed:
		return false

	_push({
		script_id = String(_save_data.identity.id),
		before = before,
		after = after,
		label = _label
	})

	return true


# adding, deleting, moving or restarting a state edits the machine itself, which
# no action list reflects: an entry that only diffed the lists would find nothing
# changed and cost the user a ctrl+z that does nothing
func record_tree(_save_data: HenSaveData, _label: String, _mutation: Callable) -> bool:
	if not _save_data or not _save_data.identity:
		return false

	if _recording:
		return _mutation.call()

	var ids: Array = _every_state_id(_save_data)
	var before: Dictionary = {}

	for state_id: StringName in ids:
		before[state_id] = snapshot(_save_data, state_id)

	var tree_before: Dictionary = HenStateOps.tree_snapshot(_save_data)

	_recording = true
	var ok: bool = _mutation.call()
	_recording = false

	if not ok:
		return false

	var tree_after: Dictionary = HenStateOps.tree_snapshot(_save_data)
	var after: Dictionary = {}
	var changed: bool = HenStateOps.tree_digest(tree_after) != HenStateOps.tree_digest(tree_before)

	for state_id: StringName in _every_state_id(_save_data) + ids:
		if after.has(state_id):
			continue

		after[state_id] = snapshot(_save_data, state_id)

		if not before.has(state_id):
			before[state_id] = []

		if digest(after[state_id]) != digest(before[state_id]):
			changed = true

	if not changed:
		return false

	_push({
		script_id = String(_save_data.identity.id),
		before = before,
		after = after,
		tree_before = tree_before,
		tree_after = tree_after,
		label = _label
	})

	return true


# every list a tree edit could take with it: a deleted sub tree drops several at
# once, and a key with no state left still has to be restored
static func _every_state_id(_save_data: HenSaveData) -> Array:
	var ids: Array = []

	for state: HenSaveState in HenStateOps.all_states(_save_data):
		if not ids.has(state.id):
			ids.append(state.id)

	for key: Variant in _save_data.state_actions:
		var id: StringName = StringName(str(key))

		if not ids.has(id):
			ids.append(id)

	return ids


func _push(_entry: Dictionary) -> void:
	_undo.append(_entry)

	if _undo.size() > LIMIT:
		_undo.pop_front()

	_redo.clear()


func abort() -> void:
	_pending.clear()


# pushes only when the list really changed: a popup opened and closed without an
# edit would otherwise cost the user a ctrl+z that does nothing
func commit(_save_data: HenSaveData, _label: String) -> bool:
	if _pending.is_empty() or not _save_data:
		return false

	var after: Dictionary = {}
	var changed: bool = false

	for state_id: StringName in _pending.before:
		after[state_id] = snapshot(_save_data, state_id)

		if digest(after[state_id]) != digest(_pending.before[state_id]):
			changed = true

	if not changed:
		_pending.clear()
		return false

	_push({
		script_id = _pending.script_id,
		before = _pending.before,
		after = after,
		label = _label
	})

	_pending.clear()

	return true


func undo(_save_data: HenSaveData) -> bool:
	if _undo.is_empty() or not _matches(_save_data, _undo[-1]):
		return false

	var entry: Dictionary = _undo.pop_back()

	_restore(_save_data, entry.before, entry.get('tree_before'))
	_redo.append(entry)

	return true


func redo(_save_data: HenSaveData) -> bool:
	if _redo.is_empty() or not _matches(_save_data, _redo[-1]):
		return false

	var entry: Dictionary = _redo.pop_back()

	_restore(_save_data, entry.after, entry.get('tree_after'))
	_undo.append(entry)

	return true


func can_undo() -> bool:
	return not _undo.is_empty()


func can_redo() -> bool:
	return not _redo.is_empty()


func clear() -> void:
	_undo.clear()
	_redo.clear()
	_pending.clear()


static func snapshot(_save_data: HenSaveData, _state_id: StringName) -> Array:
	var out: Array = []

	for action: HenSaveAction in _save_data.get_state_actions(_state_id):
		out.append(action.duplicate(true))

	return out


# a digest instead of ==: two lists of resources never compare equal, and the
# object ids inside them change with every duplicate
static func digest(_actions: Array) -> String:
	var parts: Array = []

	for action: HenSaveAction in _actions:
		parts.append(_action_digest(action))

	return var_to_str(parts)


static func _action_digest(_action: HenSaveAction) -> Array:
	if not _action:
		return []

	var inputs: Array = []

	for param: HenSaveParam in _action.inputs:
		inputs.append([str(param.id), str(param.type), var_to_str(param.default_value)])

	var expressions: Array = []

	for key: Variant in _action.input_expressions:
		var expr: HenSaveActionExpression = _action.input_expressions[key]
		var words: Array = []

		if expr:
			for word: HenSaveParam in expr.words:
				words.append([str(word.id), str(word.name), str(word.type)])

		expressions.append([
			str(key),
			expr.code if expr else '',
			words,
			var_to_str(expr.word_bindings) if expr else ''
		])

	var inline: Array = []

	for key: Variant in _action.input_actions:
		var entry: Dictionary = _action.input_actions[key]

		inline.append([str(key), str(entry.get('output', '')), _action_digest(entry.get('action'))])

	var body: Array = []

	for list: Array in HenGeneratorAction.nested_lists(_action):
		for nested: HenSaveAction in list:
			body.append(_action_digest(nested))

	return [
		str(_action.id),
		str(_action.macro_id),
		str(_action.phase),
		inputs,
		var_to_str(_action.input_bindings),
		var_to_str(_action.input_wires),
		var_to_str(_action.branches),
		expressions,
		inline,
		body,
		_action.disabled,
		_action.label
	]


# the stack keeps the canonical copy and hands out a new one, so undoing twice
# does not give the live tree the same objects it already mutated once
# the tree comes back before the lists: a state_actions key means nothing until
# the state that owns it is in the machine again
func _restore(_save_data: HenSaveData, _lists: Dictionary, _tree: Variant = null) -> void:
	if _tree != null:
		HenStateOps.apply_tree(_save_data, _tree as Dictionary)

	for state_id: StringName in _lists:
		var copy: Array = []

		for action: HenSaveAction in _lists[state_id]:
			copy.append(action.duplicate(true))

		_save_data.set_state_actions(state_id, copy)


func _matches(_save_data: HenSaveData, _entry: Dictionary) -> bool:
	if not _save_data or not _save_data.identity:
		return false

	return String(_save_data.identity.id) == String(_entry.script_id)
