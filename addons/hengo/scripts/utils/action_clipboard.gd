@tool
class_name HenActionClipboard
extends RefCounted

# copied actions live here detached from any script: the entries are duplicates,
# so editing or deleting the originals afterwards cannot reach them
# in memory on purpose: this covers copying here and pasting into another state
# or another open script, and the os clipboard would need its own serialisation

static var _items: Array[HenSaveAction] = []


static func copy(_actions: Array) -> int:
	_items.clear()

	for action: HenSaveAction in _actions:
		if action:
			_items.append(action.duplicate(true))

	return _items.size()


static func has_content() -> bool:
	return not _items.is_empty()


static func size() -> int:
	return _items.size()


# fresh copies with new ids every time, so pasting twice never hands the graph
# the same action id and the stored entries survive for the next paste
static func take() -> Array[HenSaveAction]:
	var out: Array[HenSaveAction] = []

	for action: HenSaveAction in _items:
		out.append(HenActionsPanel.duplicate_action(action))

	return out


static func clear() -> void:
	_items.clear()
