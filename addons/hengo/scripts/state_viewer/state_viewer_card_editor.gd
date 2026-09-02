@tool
class_name HenStateViewerCardEditor
extends RefCounted

# the action edits a card drives, anchored by rect instead of by a control,
# because a drawn card has nothing to point a popup at

const VALUE_POPUP_SCENE = preload('res://addons/hengo/scenes/action_value_popup.tscn')
const DROPDOWN_SCENE = preload('res://addons/hengo/scenes/drop_down_menu.tscn')
# first row of a suggestion menu: falls back to the plain text field
const TYPED_ENTRY: String = 'Type a value...'

signal changed
signal focus_requested(save_data: HenSaveData)

var is_editing: bool = false
# set by the flow viewer: wraps a mutation in one undo entry. the menu runs its
# callbacks deferred, so the popup boundary has already closed by then
var record_hook: Callable = Callable()

var _save_data: HenSaveData
var _state_id: StringName


func _record(_states: Array, _label: String, _mutation: Callable) -> bool:
	if record_hook.is_valid():
		return record_hook.call(_states, _label, _mutation)

	return _mutation.call()


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


# a chip opens the slot row: the typed editor with the bind, expression and
# producer buttons beside it, which is every source the slot can take at once.
# a fixed option set and a bool are the two the row would only slow down
# returns whether a popup was left open, which is what tells the caller a commit
# is still coming
func chip_pressed(_part: Dictionary, _rect: Rect2) -> bool:
	if _reject():
		return false

	if not (_part.get('options', []) as Array).is_empty():
		_open_option_picker(_part, _rect)
		return true

	var picker: StringName = StringName(str(_part.get('picker', &'')))

	if _part.get('kind', &'') == &'literal' and HenSlotPickers.has(picker):
		_open_picker_menu(_part, picker, _rect)
		return true

	if StringName(str(_part.get('editor', &''))) == HenActionValueEditors.BOOL:
		_toggle_bool(_part)
		return false

	var slot: Dictionary = _part.get('slot', {})

	open_slot(slot.get('action') as HenSaveAction, slot, _rect)

	return true


# a literal, a bound value, an expression or a producer: all of them are one row
# of the inspector, so the popup shows that row and nothing else
func open_slot(_action: HenSaveAction, _slot: Dictionary, _rect: Rect2) -> void:
	if _reject() or _slot.is_empty():
		return

	var param: HenSaveParam = _slot.get('param')

	if not param and not _action:
		return

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


# adding was only reachable through the sidebar tab that the cards replaced, so
# the search opens here with no action to replace and an index to land on
# the lifecycle phase a port stands for: itself, or the phase the macro runs that
# place at when the port is one of its own
func effective_phase(_phase: StringName) -> StringName:
	if HenSaveAction.PHASE_ORDER.has(_phase) or not _save_data:
		return _phase

	var state: HenSaveState = HenGeneratorAction.find_state(_save_data, _state_id)

	if not state or not state.is_macro_use():
		return _phase

	return HenGeneratorAction.hook_phase(_save_data, state, _phase)


func open_add(
	_phase: StringName,
	_parent: HenSaveAction,
	_at: int,
	_rect: Rect2,
	_replacing: HenSaveAction = null,
	_branch_key: StringName = &''
) -> void:
	if _state_id.is_empty() or _reject():
		return

	var state_id: StringName = _state_id
	var parent: HenSaveAction = _parent
	var at: int = _at
	var phase: StringName = _phase
	var replacing: HenSaveAction = _replacing
	var branch_key: StringName = _branch_key

	is_editing = true

	# an empty type means no producer filter: a step of the chain can be any action,
	# branching ones included
	var search: HenCodeSearch = HenCodeSearch.load(Vector2.ZERO, {
		type = &'',
		# a place a macro leaves for its uses is not a lifecycle phase: what can go
		# there is what fits the phase the macro runs it at
		phase = effective_phase(phase),
		on_pick = func(_macro: HenSaveMacro, _output: StringName) -> void:
			_insert_new(_macro, state_id, parent, phase, at, replacing, branch_key)
	})

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(
		search, _anchored_opts(_rect, Vector2(640, 420))
	)


# replacing is the same insert with the old step removed in the same entry: the
# search used to own a second copy of this, with its own index rules and its own
# undo stack
func _insert_new(
	_macro: HenSaveMacro,
	_state_id: StringName,
	_parent: HenSaveAction,
	_phase: StringName,
	_at: int,
	_replacing: HenSaveAction = null,
	_branch_key: StringName = &''
) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if not global or not global.SAVE_DATA:
		return

	var data: HenSaveData = global.SAVE_DATA

	_record([_state_id], 'Replace Action' if _replacing else 'Add Action', func() -> bool:
		if _replacing:
			data.remove_action_anywhere(_state_id, _replacing)

		_do_insert(_macro, data, _state_id, _parent, _phase, _at, _branch_key)

		return true
	)

	(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()


func _do_insert(
	_macro: HenSaveMacro,
	_data: HenSaveData,
	_state_id: StringName,
	_parent: HenSaveAction,
	_phase: StringName,
	_at: int,
	_branch_key: StringName = &''
) -> void:
	var action: HenSaveAction = HenSaveAction.create(_macro)

	# the macro decides: a phase it has no body for would emit nothing at all. a
	# step going onto a place of a macro is judged by the phase that place runs at
	action.phase = _phase if HenSaveAction.supported_phases(_macro).has(effective_phase(_phase)) else HenSaveAction.default_phase(_macro)

	if _parent:
		var list: Array = _target_list(_parent, _branch_key)

		list.insert(clampi(_at if _at >= 0 else list.size(), 0, list.size()), action)
		return

	var list: Array = _data.get_state_actions(_state_id).duplicate()
	var bucket: Array = HenActionsPanel.group_by_phase(list).get(str(action.phase), [])

	list.append(action)
	_data.set_state_actions(_state_id, HenActionsPanel.reorder(list, action, action.phase, _at if _at >= 0 else bucket.size()))


# the list a new step lands in: the loop body, or the branch when one is named.
# a branch list is created on demand, so an untouched branch stores nothing
func _target_list(_parent: HenSaveAction, _branch_key: StringName) -> Array:
	if _branch_key.is_empty():
		return _parent.body_actions

	var key: String = str(_branch_key)

	if not _parent.branch_actions.has(key):
		var fresh: Array[HenSaveAction] = []
		_parent.branch_actions[key] = fresh

	return _parent.branch_actions[key]


# the anchor decides which list a paste lands in, and a nested anchor never means
# the state chain
func paste_around(_actions: Array, _anchor: HenSaveAction) -> bool:
	var slot: Dictionary = _slot_around(_anchor, true)

	return paste_actions(_actions, _anchor.phase, slot.at, slot.parent, slot.branch)


# pasted steps land in run order after the anchor, each one keeping its own phase
# when the macro has a body for the target chain
func paste_actions(
	_actions: Array,
	_phase: StringName,
	_at: int,
	_parent: HenSaveAction = null,
	_branch_key: StringName = &''
) -> bool:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if _actions.is_empty() or not global or not global.SAVE_DATA or _state_id.is_empty():
		return false

	var data: HenSaveData = global.SAVE_DATA
	var state_id: StringName = _state_id

	var done: bool = _record([state_id], 'Paste Action', func() -> bool:
		var index: int = _at

		for action: HenSaveAction in _actions:
			if HenActionsPanel.can_use_phase(action, _phase, _save_data, HenGeneratorAction.find_state(_save_data, _state_id)):
				action.phase = _phase

			if _parent:
				var nested: Array = _target_list(_parent, _branch_key)

				nested.insert(clampi(index if index >= 0 else nested.size(), 0, nested.size()), action)
				index += 1
				continue

			var list: Array = data.get_state_actions(state_id).duplicate()
			var bucket: Array = HenActionsPanel.group_by_phase(list).get(str(action.phase), [])

			list.append(action)
			data.set_state_actions(state_id, HenActionsPanel.reorder(list, action, action.phase, index if index >= 0 else bucket.size()))

			index += 1

		return true
	)

	(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()

	return done


# the flat index a new step lands on to sit right before or after this one
func index_around(_action: HenSaveAction, _below: bool) -> int:
	if not _save_data:
		return -1

	var parent: HenSaveAction = _parent_of(_action)
	var list: Array = _list_of(_action)
	var index: int = list.find(_action)

	if index < 0:
		return -1

	if parent:
		return index + (1 if _below else 0)

	var bucket: Array = HenActionsPanel.group_by_phase(list).get(str(_action.phase), [])
	var at: int = bucket.find(_action)

	return -1 if at < 0 else at + (1 if _below else 0)


# a branch with nowhere to go is drawn as a loose pin, so clicking it is how the
# hole the graph is showing gets filled
func open_branch(_action: HenSaveAction, _key: String, _title: String, _rect: Rect2) -> void:
	if _reject():
		return

	is_editing = true

	HenInspector.edit_branch(_action, _key, _title, _anchored_opts(_rect, Vector2(320, 0)))


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


# the list is read when the menu opens, so it follows what the project holds now
func _open_picker_menu(_part: Dictionary, _picker: StringName, _rect: Rect2) -> void:
	var param: HenSaveParam = (_part.get('slot', {}) as Dictionary).get('param')

	if not param:
		return

	var menu: HenDropDownMenu = DROPDOWN_SCENE.instantiate()
	var options: Array = [{name = TYPED_ENTRY}]

	for entry: String in HenSlotPickers.entries(_picker):
		options.append({name = entry})

	is_editing = true

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(menu, {
		layout = HenGeneralPopup.Layout.ANCHORED,
		anchor_rect = _rect,
		side = SIDE_TOP,
		min_size = Vector2(240, 260)
	})

	var slot: Dictionary = _part.get('slot', {})
	var owner: Variant = slot.get('action')

	menu.mount(options, func(item: Dictionary) -> void:
		if str(item.name) == TYPED_ENTRY:
			if owner is HenSaveAction:
				open_slot.call_deferred(owner as HenSaveAction, slot, _rect)
			return

		param.default_value = str(item.name)
	, 'item_type')


func _open_option_picker(_part: Dictionary, _rect: Rect2) -> void:
	var param: HenSaveParam = (_part.get('slot', {}) as Dictionary).get('param')

	if not param:
		return

	var menu: HenDropDownMenu = DROPDOWN_SCENE.instantiate()
	var options: Array = []

	# an option whose value is an id nobody typed is listed by the name it was given
	for option: String in _part.get('options', []):
		options.append({name = param.option_label(option), value = option})

	is_editing = true

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(menu, {
		layout = HenGeneralPopup.Layout.ANCHORED,
		anchor_rect = _rect,
		side = SIDE_TOP,
		min_size = Vector2(180, 220)
	})

	menu.mount(options, func(item: Dictionary) -> void:
		param.default_value = str(item.get('value', item.name))
	, 'item_type')


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
		entries.append({name = 'Add above', callable = func() -> void: add_around(_action, _rect, false)})
		entries.append({name = 'Add below', callable = func() -> void: add_around(_action, _rect, true)})
		entries.append({name = 'Phase', callable = func() -> void: _open_phase_menu(_action, _rect)})

	entries.append_array(_action_menu(_action, _rect))
	entries.append({name = 'Duplicate', callable = duplicate_action.bind(_action)})
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
		var label: String = HenActionVisuals.phase_label(phase)

		entries.append({
			name = (label + '  •') if str(phase) == str(_action.phase) else label,
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


# a nested list is its own chain, and its order is not grouped by phase
func _swap_in_body(_parent: HenSaveAction, _action: HenSaveAction, _delta: int) -> bool:
	var list: Array = _list_of(_action)
	var index: int = list.find(_action)
	var target: int = index + _delta

	if index < 0 or target < 0 or target >= list.size():
		return false

	_record([_state_id], 'Move Action', func() -> bool:
		list.remove_at(index)
		list.insert(target, _action)
		return true
	)

	(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()

	return true


func _toggle_disabled(_action: HenSaveAction) -> void:
	_record([_state_id], 'Toggle Action', func() -> bool:
		_action.disabled = not _action.disabled
		return true
	)

	(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()


func _prompt_label(_action: HenSaveAction, _rect: Rect2) -> void:
	var editor: HenActionValuePopup = VALUE_POPUP_SCENE.instantiate()

	is_editing = true

	var popup: HenPopupContainer = (Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(
		editor, _anchored_opts(_rect, Vector2(220, 0))
	)

	editor.confirmed.connect(func(_chip: Variant, _text: String) -> void:
		_record([_state_id], 'Rename Action', func() -> bool:
			_action.label = _text.strip_edges()
			return true
		)
		popup.hide_popup()
		(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()
	)
	editor.cancelled.connect(func() -> void: popup.hide_popup())

	editor.edit(null, _action.label)
	editor.focus_field.call_deferred()


func duplicate_action(_action: HenSaveAction) -> void:
	if not _save_data:
		return

	var data: HenSaveData = _save_data
	var state_id: StringName = _state_id
	var parent: HenSaveAction = _parent_of(_action)

	_record([state_id], 'Duplicate Action', func() -> bool:
		var copy: HenSaveAction = HenActionsPanel.duplicate_action(_action)

		if parent:
			var list: Array = _list_of(_action)
			list.insert(list.find(_action) + 1, copy)
		else:
			data.insert_state_action(state_id, copy, data.get_state_actions(state_id).find(_action) + 1)

		return true
	)

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
			callable = delete_action.bind(_action),
			color = Color('#c16460'),
			icon = 'res://addons/hengo/assets/new_icons/trash-2.svg'
		}
	]


func _replace_action(_action: HenSaveAction, _rect: Rect2) -> void:
	# closing refreshes inline, so the rebuild must not fire a second time
	is_editing = false

	var slot: Dictionary = _slot_around(_action, false)

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).hide_popup()
	open_add(_action.phase, slot.parent, slot.at, _rect, _action, slot.branch)


# the menu closes on click, so the search it opens has to outlive that close
func add_around(_action: HenSaveAction, _rect: Rect2, _below: bool) -> void:
	is_editing = false

	var popup: HenGeneralPopup = Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup
	var slot: Dictionary = _slot_around(_action, _below)

	if popup.has_open_popups():
		popup.hide_popup()

	open_add(_action.phase, slot.parent, slot.at, _rect, null, slot.branch)


# { parent: HenSaveAction, branch: StringName, at: int }
func _slot_around(_action: HenSaveAction, _below: bool) -> Dictionary:
	return {
		parent = _parent_of(_action),
		branch = _branch_key_of(_action),
		at = index_around(_action, _below)
	}


func delete_action(_action: HenSaveAction) -> void:
	if not _save_data:
		return

	is_editing = false

	var data: HenSaveData = _save_data
	var state_id: StringName = _state_id

	_record([state_id], 'Delete Action', func() -> bool:
		return data.remove_action_anywhere(state_id, _action)
	)

	if (Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).has_open_popups():
		(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).hide_popup()

	# the card has to leave the graph, and `changed` only redraws the edited one
	(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()


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
	for list: Array in HenGeneratorAction.nested_lists(_root):
		for child: HenSaveAction in list:
			if child == _target:
				return _root

			var deeper: HenSaveAction = _find_parent(child, _target)

			if deeper:
				return deeper

	return null


# the branch of the parent this action is a step of, empty for a loop body and
# for a top level step
func _branch_key_of(_action: HenSaveAction) -> StringName:
	var parent: HenSaveAction = _parent_of(_action)

	if not parent:
		return &''

	for key: Variant in parent.branch_actions:
		var stored: Variant = parent.branch_actions[key]

		if stored is Array and (stored as Array).has(_action):
			return StringName(str(key))

	return &''


# the array holding this action: a loop body, one branch of it, or the state
# chain. moving and duplicating write into it, and it is not always body_actions
func _list_of(_action: HenSaveAction) -> Array:
	var parent: HenSaveAction = _parent_of(_action)

	if not parent:
		return _save_data.get_state_actions(_state_id) if _save_data else []

	for list: Array in HenGeneratorAction.nested_lists(parent):
		if list.has(_action):
			return list

	return []


# the drop target can sit in the state chain, in a loop body or in a branch, and
# the step lands in the very list that holds it
func drop_step(_action: HenSaveAction, _target: HenSaveAction, _before: bool, _from: StringName, _to: StringName) -> bool:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	# contains_action is true for the action itself, so a drop on its own card stops here
	if not global or not global.SAVE_DATA or HenActionsPanel.contains_action(_action, _target):
		return false

	var data: HenSaveData = global.SAVE_DATA

	target(data, _to)

	var parent: HenSaveAction = _parent_of(_target)

	if not parent:
		var index: int = HenActionsPanel.drop_index(data.get_state_actions(_to), _target, _action, _before)

		return false if index < 0 else move_step(_action, _target, index, _from, _to)

	# the live array, taken before the removal empties the list it came from
	var list: Array = _list_of(_target)

	var done: bool = _record([_from, _to], 'Move Action', func() -> bool:
		data.remove_action_anywhere(_from, _action)

		var at: int = list.find(_target)

		if at < 0:
			return false

		if HenActionsPanel.can_use_phase(_action, parent.phase):
			_action.phase = parent.phase

		list.insert(at + (0 if _before else 1), _action)

		return true
	)

	(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()

	return done


# rewrites the whole list so array order stays enter -> update -> exit
# the only move there is: same state or across two, so the phase rule and the
# reorder are written once
func move_step(_action: HenSaveAction, _target: HenSaveAction, _index: int, _from: StringName, _to: StringName) -> bool:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if not global or not global.SAVE_DATA or _from.is_empty() or _to.is_empty():
		return false

	var data: HenSaveData = global.SAVE_DATA

	return _record([_from, _to], 'Move Action', func() -> bool:
		# a nested step has no place in the chain, so reordering it there would leave
		# the copy inside its loop or branch behind
		if _from == _to and data.get_state_actions(_from).has(_action):
			target(data, _to)
			move_action(_action, _target.phase, _index)

			return true

		data.remove_action_anywhere(_from, _action)

		if HenActionsPanel.can_use_phase(_action, _target.phase):
			_action.phase = _target.phase

		var list: Array = data.get_state_actions(_to).duplicate()

		list.append(_action)
		data.set_state_actions(_to, HenActionsPanel.reorder(list, _action, _action.phase, _index))

		(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()

		return true
	)


func move_action(_action: HenSaveAction, _phase: StringName, _index: int) -> void:
	if not _save_data or _state_id.is_empty():
		return

	var old_order: Array = _save_data.get_state_actions(_state_id).duplicate()
	var old_phase: StringName = _action.phase
	var new_order: Array = HenActionsPanel.reorder(old_order, _action, _phase, _index)

	if new_order == old_order and str(old_phase) == str(_phase):
		return

	# the history snapshots the whole list at the popup boundary, so the reorder
	# only has to happen once here
	var data: HenSaveData = _save_data
	var state_id: StringName = _state_id

	_record([state_id], 'Move Action', func() -> bool:
		_action.phase = _phase
		data.set_state_actions(state_id, new_order)
		return true
	)

	(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()
