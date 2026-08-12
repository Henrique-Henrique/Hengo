@tool
class_name HenFlowHistory
extends RefCounted

# undo stack of the flow view, kept apart from global.history on purpose. the save
# data mutates its resources in place, so a method pair would hold a reference to
# the very object that changed: each entry carries a copy of a state's action list
# from before and after the edit, and undo puts a fresh copy back

const LIMIT: int = 60

var _undo: Array[Dictionary] = []
var _redo: Array[Dictionary] = []
var _pending: Dictionary = {}


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

	_undo.append({
		script_id = _pending.script_id,
		before = _pending.before,
		after = after,
		label = _label
	})

	if _undo.size() > LIMIT:
		_undo.pop_front()

	_redo.clear()
	_pending.clear()

	return true


func undo(_save_data: HenSaveData) -> bool:
	if _undo.is_empty() or not _matches(_save_data, _undo[-1]):
		return false

	var entry: Dictionary = _undo.pop_back()

	_restore(_save_data, entry.before)
	_redo.append(entry)

	return true


func redo(_save_data: HenSaveData) -> bool:
	if _redo.is_empty() or not _matches(_save_data, _redo[-1]):
		return false

	var entry: Dictionary = _redo.pop_back()

	_restore(_save_data, entry.after)
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

	for nested: HenSaveAction in _action.body_actions:
		body.append(_action_digest(nested))

	return [
		str(_action.id),
		str(_action.macro_id),
		str(_action.phase),
		inputs,
		var_to_str(_action.input_bindings),
		var_to_str(_action.output_bindings),
		var_to_str(_action.branches),
		expressions,
		inline,
		body
	]


# the stack keeps the canonical copy and hands out a new one, so undoing twice
# does not give the live tree the same objects it already mutated once
func _restore(_save_data: HenSaveData, _lists: Dictionary) -> void:
	for state_id: StringName in _lists:
		var copy: Array = []

		for action: HenSaveAction in _lists[state_id]:
			copy.append(action.duplicate(true))

		_save_data.set_state_actions(state_id, copy)


func _matches(_save_data: HenSaveData, _entry: Dictionary) -> bool:
	if not _save_data or not _save_data.identity:
		return false

	return String(_save_data.identity.id) == String(_entry.script_id)
