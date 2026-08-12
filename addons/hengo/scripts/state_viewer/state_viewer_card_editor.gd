@tool
class_name HenStateViewerCardEditor
extends RefCounted

# the action edits a card drives, anchored by rect instead of by a control,
# because a drawn card has nothing to point a popup at

const ACTIONS_SEARCH_SCENE = preload('res://addons/hengo/scenes/actions_search.tscn')
const VALUE_POPUP_SCENE = preload('res://addons/hengo/scenes/action_value_popup.tscn')
const DROPDOWN_SCENE = preload('res://addons/hengo/scenes/drop_down_menu.tscn')

signal changed
signal focus_requested(save_data: HenSaveData)

var is_editing: bool = false

var _save_data: HenSaveData
var _state_id: StringName
# {part, rect} of every text-editable chip in reading order: the tab order
var _ring: Array = []
var _ring_index: int = -1
var _provider: Callable = Callable()
var _value_popup: HenPopupContainer
var _value_editor: HenActionValuePopup


func target(_data: HenSaveData, _id: StringName) -> void:
	_save_data = _data
	_state_id = _id


# mutations read the active script, so another card asks to be focused first
func _is_active() -> bool:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	return global != null and _save_data != null and global.SAVE_DATA == _save_data


func _reject() -> bool:
	if _is_active():
		return false

	focus_requested.emit(_save_data)

	return true


# a chip carries the whole edit: the slot type picks the small editor, a fixed
# option set gets its picker, and every other source falls back to the inspector.
# returns whether a popup was left open, which is what tells the caller a commit
# is still coming
# the ring provider re-reads the chip rects, which move as soon as a committed
# value changes the width of its line
func chip_pressed(_part: Dictionary, _chip_index: int, _rect: Rect2, _ring_provider: Callable) -> bool:
	if _reject():
		return false

	if bool(_part.get('editable', false)):
		_provider = _ring_provider
		_ring = _provider.call()
		_ring_index = _index_of(_chip_index)
		_open_value_popup(_part, _rect)
		return true

	if not (_part.get('options', []) as Array).is_empty():
		_open_option_picker(_part, _rect)
		return true

	if StringName(str(_part.get('editor', &''))) == HenActionValueEditors.BOOL:
		_toggle_bool(_part)
		return false

	var slot: Dictionary = _part.get('slot', {})
	var owner: Variant = slot.get('action')

	if owner is HenSaveAction:
		open_slot(owner as HenSaveAction, slot, _rect)

	return true


# a bound value, an expression or a typed editor the chip cannot hold: all of them
# are one row of the inspector, so the popup shows that row and nothing else
func open_slot(_action: HenSaveAction, _slot: Dictionary, _rect: Rect2) -> void:
	if _reject() or _slot.is_empty():
		return

	var param: HenSaveParam = _slot.get('param')

	is_editing = true

	HenInspector.edit_slot(
		_action,
		_slot,
		param.name if param else HenActionsPanel.display_name(_action),
		_anchored_opts(_rect, Vector2(300, 0))
	)


# the pin is where a value comes from, so it offers the actions that produce one
# of its type. the same picker the inspector's producer button opens
func open_producer(_slot: Dictionary, _rect: Rect2) -> void:
	if _reject() or _slot.is_empty():
		return

	var param: HenSaveParam = _slot.get('param')

	if not param:
		return

	is_editing = true

	var search: HenCodeSearch = HenCodeSearch.load(Vector2.ZERO, {
		type = StringName(str(_slot.get('type', param.type))),
		io_type = &'in',
		on_pick = func(_macro: HenSaveMacro, _output: StringName) -> void:
			HenActionsPanel.set_producer(_slot, _macro, _output)
			(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()
	})

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(
		search, _anchored_opts(_rect, Vector2(640, 420))
	)


# a checkbox behind a popup is one click too many, so the chip is the checkbox
func _toggle_bool(_part: Dictionary) -> void:
	var param: HenSaveParam = (_part.get('slot', {}) as Dictionary).get('param')

	if not param:
		return

	param.default_value = not bool(param.default_value)
	changed.emit()


func _anchored_opts(_rect: Rect2, _min_size: Vector2) -> Dictionary:
	return {
		layout = HenGeneralPopup.Layout.ANCHORED,
		anchor_rect = _rect,
		side = SIDE_TOP,
		blur = false,
		min_size = _min_size
	}


func edit_action(_action: HenSaveAction, _rect: Rect2, _inline: bool) -> void:
	if _reject():
		return

	var nested: bool = _inline or _parent_of(_action) != null
	var menu: Array[Dictionary] = []

	# an inline producer is not in the state list, so replace and delete would look
	# there and miss it
	if not _inline:
		menu = _action_menu(_action, _rect)

	is_editing = true

	HenInspector.edit_resource(
		_action,
		HenActionsPanel.display_name(_action),
		menu,
		_popup_opts(_rect),
		nested,
		true
	)


func open_search(_phase: StringName, _replacing: HenSaveAction, _parent: HenSaveAction, _rect: Rect2) -> void:
	if _state_id.is_empty() or _reject():
		return

	var search: HenActionsSearch = ACTIONS_SEARCH_SCENE.instantiate()
	search.setup(_state_id, _phase, _replacing, _parent)

	var opts: Dictionary = _popup_opts(_rect)
	opts.min_size = Vector2(320, 360)
	opts.blur = false

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(search, opts)


func _open_option_picker(_part: Dictionary, _rect: Rect2) -> void:
	var param: HenSaveParam = (_part.get('slot', {}) as Dictionary).get('param')

	if not param:
		return

	var menu: HenDropDownMenu = DROPDOWN_SCENE.instantiate()
	var options: Array = []

	for option: String in _part.get('options', []):
		options.append({name = option})

	is_editing = true

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(menu, {
		layout = HenGeneralPopup.Layout.ANCHORED,
		anchor_rect = _rect,
		side = SIDE_TOP,
		min_size = Vector2(180, 220)
	})

	menu.mount(options, func(item: Dictionary) -> void:
		param.default_value = str(item.name)
	, 'item_type')


# a small field right above the chip; the container is kept alive across tabs so
# hopping down a line does not respawn (and re-animate) the popup
func _open_value_popup(_part: Dictionary, _rect: Rect2) -> void:
	var slot: Dictionary = _part.get('slot', {})
	var text: String = HenActionsPanel.edit_text(HenActionsPanel.literal_value(slot))

	is_editing = true

	var opts: Dictionary = {
		layout = HenGeneralPopup.Layout.ANCHORED,
		anchor_rect = _rect,
		side = SIDE_TOP,
		blur = false,
		min_size = Vector2(150, 0)
	}

	if is_instance_valid(_value_popup) and is_instance_valid(_value_editor):
		_value_editor.edit(_part, text)
		_value_popup.reanchor(opts)
		# queued after the reanchor above, which defers the move itself
		_value_editor.focus_field.call_deferred()
		return

	_value_editor = VALUE_POPUP_SCENE.instantiate()
	_value_editor.confirmed.connect(_on_value_confirmed)
	_value_editor.tabbed.connect(_on_value_tabbed)
	_value_editor.cancelled.connect(_close_value_popup)

	_value_popup = (Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(_value_editor, opts)
	_value_popup.closed.connect(_on_value_popup_closed, CONNECT_ONE_SHOT)

	_value_editor.edit(_part, text)
	_value_editor.focus_field.call_deferred()


func _on_value_confirmed(_part: Variant, _text: String) -> void:
	_commit_value(_part, _text)
	_close_value_popup()


func _on_value_tabbed(_part: Variant, _text: String) -> void:
	_commit_value(_part, _text)

	if _provider.is_valid():
		_ring = _provider.call()

	if _ring.size() < 2:
		_close_value_popup()
		return

	_ring_index = (_ring_index + 1) % _ring.size()

	var next: Dictionary = _ring[_ring_index]

	_open_value_popup(next.part, next.rect)


func _commit_value(_part: Variant, _text: String) -> void:
	if not _part is Dictionary:
		return

	var slot: Dictionary = (_part as Dictionary).get('slot', {})
	var param: HenSaveParam = slot.get('param')

	if not param:
		return

	param.default_value = HenActionsPanel.parse_literal(_text, str(slot.get('type', param.type)))


func _index_of(_chip_index: int) -> int:
	for i: int in range(_ring.size()):
		if int(_ring[i].index) == _chip_index:
			return i

	return 0


func _close_value_popup() -> void:
	if is_instance_valid(_value_popup):
		_value_popup.hide_popup()


func _on_value_popup_closed() -> void:
	_value_popup = null
	_value_editor = null
	_provider = Callable()
	_ring.clear()
	_ring_index = -1


func _popup_opts(_rect: Rect2) -> Dictionary:
	return {
		layout = HenGeneralPopup.Layout.ANCHORED,
		anchor_rect = _rect,
		side = SIDE_RIGHT,
		blur = false,
		min_size = Vector2(320, 0)
	}


# the card's own menu, in a small anchored list instead of the whole inspector
func open_action_menu(_action: HenSaveAction, _rect: Rect2, _inline: bool) -> void:
	if _reject():
		return

	var entries: Array[Dictionary] = []

	if not _inline:
		entries.append({name = 'Phase', callable = func() -> void: _open_phase_menu(_action, _rect)})

	entries.append_array(_action_menu(_action, _rect))
	entries.append({name = 'Duplicate', callable = _duplicate_action.bind(_action)})
	entries.append({name = 'Move up', callable = func() -> void: move_in_chain(_action, -1)})
	entries.append({name = 'Move down', callable = func() -> void: move_in_chain(_action, 1)})
	entries.append({name = 'Rename', callable = func() -> void: _prompt_label(_action, _rect)})
	entries.append({name = 'Enable' if _action.disabled else 'Disable', callable = _toggle_disabled.bind(_action)})

	_open_menu(entries, _rect)


func _open_menu(_entries: Array, _rect: Rect2) -> void:
	var menu: HenDropDownMenu = DROPDOWN_SCENE.instantiate()
	var by_name: Dictionary = {}
	var items: Array = []

	for entry: Dictionary in _entries:
		by_name[str(entry.name)] = entry.callable
		items.append({name = str(entry.name)})

	is_editing = true

	# an ItemList with no minimum height collapses, leaving the search bar alone
	var height: float = minf(280.0, 56.0 + items.size() * 30.0)

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(menu, _anchored_opts(_rect, Vector2(200, height)))

	menu.mount(items, func(_item: Dictionary) -> void:
		var call: Variant = by_name.get(str(_item.name))

		# the menu closes itself on click, so a submenu opened here would be closed
		# by the very click that asked for it
		if call is Callable:
			(call as Callable).call_deferred()
	, 'item_type')


func _open_phase_menu(_action: HenSaveAction, _rect: Rect2) -> void:
	var macro: HenSaveMacro = HenActionsPanel.find_macro(_action.macro_id)

	if not macro:
		return

	var entries: Array = []

	for phase: StringName in HenSaveAction.supported_phases(macro):
		entries.append({
			name = (str(phase) + '  •') if str(phase) == str(_action.phase) else str(phase),
			callable = func() -> void: move_action(_action, phase, -1)
		})

	_open_menu(entries, _rect)


# reordering in a graph is swapping places with the neighbour step of the same
# chain: the chain is the `then` sequence, linear by definition, so this stays
# well defined however branchy the state gets
func move_in_chain(_action: HenSaveAction, _delta: int) -> bool:
	if not _save_data or _state_id.is_empty():
		return false

	var parent: HenSaveAction = _parent_of(_action)

	if parent:
		return _swap_in_body(parent, _action, _delta)

	var bucket: Array = HenActionsPanel.group_by_phase(_save_data.get_state_actions(_state_id)).get(str(_action.phase), [])
	var index: int = bucket.find(_action)
	var target: int = index + _delta

	if index < 0 or target < 0 or target >= bucket.size():
		return false

	move_action(_action, _action.phase, target)

	return true


# a loop body is its own list, and its order is not grouped by phase
func _swap_in_body(_parent: HenSaveAction, _action: HenSaveAction, _delta: int) -> bool:
	var index: int = _parent.body_actions.find(_action)
	var target: int = index + _delta

	if index < 0 or target < 0 or target >= _parent.body_actions.size():
		return false

	_parent.body_actions.remove_at(index)
	_parent.body_actions.insert(target, _action)

	(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()

	return true


func _toggle_disabled(_action: HenSaveAction) -> void:
	_action.disabled = not _action.disabled

	(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()


func _prompt_label(_action: HenSaveAction, _rect: Rect2) -> void:
	var editor: HenActionValuePopup = VALUE_POPUP_SCENE.instantiate()

	is_editing = true

	var popup: HenPopupContainer = (Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(
		editor, _anchored_opts(_rect, Vector2(220, 0))
	)

	editor.confirmed.connect(func(_chip: Variant, _text: String) -> void:
		_action.label = _text.strip_edges()
		popup.hide_popup()
		(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()
	)
	editor.cancelled.connect(func() -> void: popup.hide_popup())

	editor.edit(null, _action.label)
	editor.focus_field.call_deferred()


func _duplicate_action(_action: HenSaveAction) -> void:
	if not _save_data:
		return

	var copy: HenSaveAction = HenActionsPanel.duplicate_action(_action)
	var parent: HenSaveAction = _parent_of(_action)

	if parent:
		parent.body_actions.insert(parent.body_actions.find(_action) + 1, copy)
	else:
		_save_data.insert_state_action(_state_id, copy, _save_data.get_state_actions(_state_id).find(_action) + 1)

	(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()


func _action_menu(_action: HenSaveAction, _rect: Rect2) -> Array[Dictionary]:
	return [
		{
			name = 'Replace',
			callable = _replace_action.bind(_action, _rect),
			icon = 'res://addons/hengo/assets/new_icons/replace.svg'
		},
		{
			name = 'Delete',
			callable = _delete_action.bind(_action),
			color = Color('#c16460'),
			icon = 'res://addons/hengo/assets/new_icons/trash-2.svg'
		}
	]


func _replace_action(_action: HenSaveAction, _rect: Rect2) -> void:
	# closing refreshes inline, so the rebuild must not fire a second time
	is_editing = false

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).hide_popup()
	open_search(_action.phase, _action, _parent_of(_action), _rect)


func _delete_action(_action: HenSaveAction) -> void:
	var parent: HenSaveAction = _parent_of(_action)

	if parent:
		parent.body_actions.erase(_action)
	elif _save_data:
		_save_data.remove_state_action(_state_id, _action)

	is_editing = false

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).hide_popup()
	changed.emit()


# the loop action holding this one, null at top level
func _parent_of(_action: HenSaveAction) -> HenSaveAction:
	if not _save_data:
		return null

	for action: HenSaveAction in _save_data.get_state_actions(_state_id):
		var found: HenSaveAction = _find_parent(action, _action)

		if found:
			return found

	return null


func _find_parent(_root: HenSaveAction, _target: HenSaveAction) -> HenSaveAction:
	for child: HenSaveAction in _root.body_actions:
		if child == _target:
			return _root

		var deeper: HenSaveAction = _find_parent(child, _target)

		if deeper:
			return deeper

	return null


# rewrites the whole list so array order stays enter -> update -> exit
func move_action(_action: HenSaveAction, _phase: StringName, _index: int) -> void:
	if not _save_data or _state_id.is_empty():
		return

	var old_order: Array = _save_data.get_state_actions(_state_id).duplicate()
	var old_phase: StringName = _action.phase
	var new_order: Array = HenActionsPanel.reorder(old_order, _action, _phase, _index)

	if new_order == old_order and str(old_phase) == str(_phase):
		return

	# the flow history snapshots the whole list at the popup boundary, so a method
	# pair on global.history would record the same edit into a second stack
	_action.phase = _phase
	_save_data.set_state_actions(_state_id, new_order)

	(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()
