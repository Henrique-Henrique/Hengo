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


# a chip carries the whole edit: a typed literal opens the value popup, a fixed
# option set its picker, and every other source falls back to the inspector
# the ring provider re-reads the chip rects, which move as soon as a committed
# value changes the width of its line
func chip_pressed(_part: Dictionary, _chip_index: int, _rect: Rect2, _ring_provider: Callable) -> void:
	if _reject():
		return

	if bool(_part.get('editable', false)):
		_provider = _ring_provider
		_ring = _provider.call()
		_ring_index = _index_of(_chip_index)
		_open_value_popup(_part, _rect)
		return

	if not (_part.get('options', []) as Array).is_empty():
		_open_option_picker(_part, _rect)
		return

	var slot: Dictionary = _part.get('slot', {})
	var owner: Variant = slot.get('action')

	if owner is HenSaveAction:
		edit_action(owner as HenSaveAction, _rect, bool(slot.get('inline', false)))


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

	var global: HenGlobal = Engine.get_singleton(&'Global')
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	var target_data: HenSaveData = _save_data
	var id: StringName = _state_id

	var apply: Callable = func(_order: Array, _target_phase: StringName) -> void:
		_action.phase = _target_phase
		target_data.set_state_actions(id, _order)
		signal_bus.request_structural_update.emit()

	if global.history:
		global.history.create_action('Move Action ' + HenActionsPanel.display_name(_action))
		global.history.add_do_method(apply.bind(new_order, _phase))
		global.history.add_undo_method(apply.bind(old_order, old_phase))
		global.history.commit_action()
	else:
		apply.call(new_order, _phase)
