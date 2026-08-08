@tool
class_name HenStateActionsList extends VBoxContainer

const ACTION_ROW_SCENE = preload('res://addons/hengo/scenes/action_row.tscn')
const ACTIONS_SEARCH_SCENE = preload('res://addons/hengo/scenes/actions_search.tscn')
const PHASE_HEADER_SCENE = preload('res://addons/hengo/scenes/action_phase_header.tscn')
const VALUE_POPUP_SCENE = preload('res://addons/hengo/scenes/action_value_popup.tscn')
const DROPDOWN_SCENE = preload('res://addons/hengo/scenes/drop_down_menu.tscn')

# floor of the card width; a capsule wider than this still grows it
const CONTENT_WIDTH: float = 320.0

signal structure_changed
signal focus_requested

var save_data: HenSaveData
var state_id: StringName
var is_editing: bool = false

var list: VBoxContainer
var add_bt: Button

# action id -> the loop action holding it, null at top level
var _parent_of: Dictionary = {}
var _rows_by_id: Dictionary = {}
# text-editable chips in reading order, at any capsule depth: the tab order
var _chips: Array[HenActionValue] = []
var _value_popup: HenPopupContainer
var _value_editor: HenActionValuePopup


func _ready() -> void:
	list = get_node('%List')
	add_bt = get_node('%AddBt')

	add_bt.pressed.connect(_on_add_pressed)


func setup(_save_data: HenSaveData, _state_id: StringName) -> void:
	save_data = _save_data
	state_id = _state_id
	refresh()


func refresh() -> void:
	if not list:
		return

	_clear_list()
	_parent_of.clear()

	var actions: Array = current_actions()

	custom_minimum_size.x = CONTENT_WIDTH if not actions.is_empty() else 0.0

	# phase order matches codegen: visual order is run order
	var groups: Dictionary = HenActionsPanel.group_by_phase(actions)

	for phase: StringName in HenSaveAction.PHASE_ORDER:
		var bucket: Array = groups.get(str(phase), [])

		if bucket.is_empty():
			continue

		_add_phase_header(phase, bucket.size())

		for action: HenSaveAction in bucket:
			_add_row(action, 0, null)


func current_actions() -> Array:
	if not save_data or state_id.is_empty():
		return []

	return save_data.get_state_actions(state_id)


func _clear_list() -> void:
	_rows_by_id.clear()
	_chips.clear()

	for child: Node in list.get_children():
		list.remove_child(child)
		child.queue_free()


func _add_phase_header(_phase: StringName, _count: int) -> void:
	var header: HenActionPhaseHeader = PHASE_HEADER_SCENE.instantiate()
	header.add_pressed.connect(_on_add_pressed)
	header.action_dropped.connect(_on_header_dropped)
	list.add_child(header)
	header.setup(_phase, _count)


func _add_row(_action: HenSaveAction, _depth: int, _parent: HenSaveAction) -> void:
	_parent_of[str(_action.id)] = _parent

	var row: HenActionRow = ACTION_ROW_SCENE.instantiate()
	row.row_pressed.connect(_on_action_row_pressed)
	row.action_dropped.connect(_on_row_dropped)
	list.add_child(row)
	_rows_by_id[str(_action.id)] = row

	var macro: HenSaveMacro = HenActionsPanel.find_macro(_action.macro_id)

	row.setup({
		title = HenActionsPanel.display_name(_action),
		icon = macro.icon if macro else '',
		color = macro.color if macro else '',
		doc = HenActionDoc.bbcode(macro),
		values = HenActionsPanel.value_preview(_action, save_data),
		meta = _action,
		indent = _depth,
		draggable = _depth == 0
	}, HenActionsPanel.value_parts(_action, save_data), _chips, _on_chip_pressed)

	if macro and macro.has_body:
		for child: HenSaveAction in _action.body_actions:
			_add_row(child, _depth + 1, _action)

		_add_nested_add(_action, _depth + 1)


func _add_nested_add(_loop: HenSaveAction, _depth: int) -> void:
	# MarginContainer: Button has no margin constant to indent with
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override('margin_left', 4 + _depth * 18)

	var bt := Button.new()
	bt.text = '+ Add to loop'
	bt.flat = true
	bt.alignment = HORIZONTAL_ALIGNMENT_LEFT
	bt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	bt.add_theme_color_override('font_color', Color(1, 1, 1, 0.45))
	bt.pressed.connect(func() -> void: _open_search(&'', null, _loop, bt))

	margin.add_child(bt)
	list.add_child(margin)


# mutations read the active script, so another card asks to be focused first
func _is_active() -> bool:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	return global != null and save_data != null and global.SAVE_DATA == save_data


func _on_action_row_pressed(_meta: Variant, _button: int) -> void:
	if _button != MOUSE_BUTTON_LEFT or not _meta is HenSaveAction:
		return

	if not _is_active():
		focus_requested.emit()
		return

	_edit_action(_meta as HenSaveAction, _rows_by_id.get(str((_meta as HenSaveAction).id)), false)


# a chip carries the whole edit: a typed literal opens the value popup, a fixed
# option set its picker, and every other source falls back to the inspector
func _on_chip_pressed(_part: Dictionary, _anchor: Control) -> void:
	if not _is_active():
		focus_requested.emit()
		return

	if _anchor is HenActionValue and (_anchor as HenActionValue).is_editable():
		_open_value_popup(_anchor as HenActionValue)
		return

	if not (_part.get('options', []) as Array).is_empty():
		_open_option_picker(_part, _anchor)
		return

	var slot: Dictionary = _part.get('slot', {})
	var owner: Variant = slot.get('action')

	if owner is HenSaveAction:
		_edit_action(owner as HenSaveAction, _anchor, bool(slot.get('inline', false)))


func _edit_action(_action: HenSaveAction, _anchor: Control, _inline: bool) -> void:
	var nested: bool = _inline or _parent_of.get(str(_action.id)) != null
	var menu: Array[Dictionary] = []

	# an inline producer is not in the state list, so replace/delete would look
	# there and miss it
	if not _inline:
		menu = _action_menu(_action)

	is_editing = true

	HenInspector.edit_resource(
		_action,
		HenActionsPanel.display_name(_action),
		menu,
		_popup_opts(_anchor),
		nested,
		true
	)


func _open_option_picker(_part: Dictionary, _anchor: Control) -> void:
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
		anchor_to = _anchor,
		side = SIDE_TOP,
		min_size = Vector2(180, 220)
	})

	menu.mount(options, func(item: Dictionary) -> void:
		param.default_value = str(item.name)
	, 'item_type')


# a small field right above the chip; the container is kept alive across tabs so
# hopping down a line does not respawn (and re-animate) the popup
func _open_value_popup(_chip: HenActionValue) -> void:
	var slot: Dictionary = _chip.part.get('slot', {})
	var text: String = HenActionsPanel.edit_text(HenActionsPanel.literal_value(slot))

	is_editing = true

	var opts: Dictionary = {
		layout = HenGeneralPopup.Layout.ANCHORED,
		anchor_to = _chip.value_anchor(),
		side = SIDE_TOP,
		blur = false,
		min_size = Vector2(150, 0)
	}

	if is_instance_valid(_value_popup) and is_instance_valid(_value_editor):
		_set_editing_chip(_chip)
		_value_editor.edit(_chip, text)
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

	_set_editing_chip(_chip)
	_value_editor.edit(_chip, text)
	_value_editor.focus_field.call_deferred()


func _on_value_confirmed(_chip: HenActionValue, _text: String) -> void:
	_commit_value(_chip, _text)
	_close_value_popup()


func _on_value_tabbed(_chip: HenActionValue, _text: String) -> void:
	_commit_value(_chip, _text)

	var next: HenActionValue = _next_chip(_chip)

	if next:
		_open_value_popup(next)
	else:
		_close_value_popup()


func _commit_value(_chip: HenActionValue, _text: String) -> void:
	if not is_instance_valid(_chip):
		return

	var slot: Dictionary = _chip.part.get('slot', {})
	var param: HenSaveParam = slot.get('param')

	if not param:
		return

	param.default_value = HenActionsPanel.parse_literal(_text, str(slot.get('type', param.type)))
	_chip.set_value_text(HenActionsPanel.format_value(param.default_value))


# wraps around, so tab keeps cycling instead of dead-ending on the last chip
func _next_chip(_chip: HenActionValue) -> HenActionValue:
	var index: int = _chips.find(_chip)

	if index < 0 or _chips.size() < 2:
		return null

	return _chips[(index + 1) % _chips.size()]


func _set_editing_chip(_chip: HenActionValue) -> void:
	for chip: HenActionValue in _chips:
		if is_instance_valid(chip):
			chip.set_editing(chip == _chip)


func _close_value_popup() -> void:
	if is_instance_valid(_value_popup):
		_value_popup.hide_popup()


func _on_value_popup_closed() -> void:
	_value_popup = null
	_value_editor = null
	_set_editing_chip(null)


func _popup_opts(_anchor: Control) -> Dictionary:
	return {
		layout = HenGeneralPopup.Layout.ANCHORED,
		anchor_to = _anchor,
		side = SIDE_RIGHT,
		blur = true,
		min_size = Vector2(320, 0)
	}


func _action_menu(_action: HenSaveAction) -> Array[Dictionary]:
	return [
		{
			name = 'Replace',
			callable = _replace_action.bind(_action),
			icon = 'res://addons/hengo/assets/new_icons/replace.svg'
		},
		{
			name = 'Delete',
			callable = _delete_action.bind(_action),
			color = Color('#c16460'),
			icon = 'res://addons/hengo/assets/new_icons/trash-2.svg'
		}
	]


func _replace_action(_action: HenSaveAction) -> void:
	var row: HenActionRow = _rows_by_id.get(str(_action.id))

	# closing refreshes inline, freeing the row the search below anchors to
	is_editing = false

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).hide_popup()
	_open_search(_action.phase, _action, _parent_of.get(str(_action.id)), row)


func _delete_action(_action: HenSaveAction) -> void:
	var parent: HenSaveAction = _parent_of.get(str(_action.id))

	if parent:
		parent.body_actions.erase(_action)
	elif save_data:
		save_data.remove_state_action(state_id, _action)

	# the refresh below covers it, so closing must not trigger a second one
	is_editing = false

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).hide_popup()
	refresh()
	structure_changed.emit()


func _on_add_pressed(_phase: StringName = &'') -> void:
	_open_search(_phase, null, null, add_bt)


func _open_search(_phase: StringName, _replacing: HenSaveAction, _parent: HenSaveAction, _anchor: Control) -> void:
	if state_id.is_empty():
		return

	if not _is_active():
		focus_requested.emit()
		return

	var search: HenActionsSearch = ACTIONS_SEARCH_SCENE.instantiate()
	search.setup(state_id, _phase, _replacing, _parent)

	var opts: Dictionary = _popup_opts(_anchor)
	opts.min_size = Vector2(320, 360)
	opts.blur = false

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(search, opts)


func _on_row_dropped(_dragged: HenSaveAction, _target: HenSaveAction, _before: bool) -> void:
	if not _dragged or not _target:
		return

	var index: int = HenActionsPanel.drop_index(current_actions(), _target, _dragged, _before)

	if index >= 0:
		_move_action(_dragged, _target.phase, index)


func _on_header_dropped(_dragged: HenSaveAction, _phase: StringName) -> void:
	if _dragged:
		_move_action(_dragged, _phase, 0)


# rewrites the whole list so array order stays enter -> update -> exit
func _move_action(_action: HenSaveAction, _phase: StringName, _index: int) -> void:
	if not save_data or state_id.is_empty():
		return

	var old_order: Array = current_actions().duplicate()
	var old_phase: StringName = _action.phase
	var new_order: Array = HenActionsPanel.reorder(old_order, _action, _phase, _index)

	if new_order == old_order and str(old_phase) == str(_phase):
		return

	var global: HenGlobal = Engine.get_singleton(&'Global')
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	var target: HenSaveData = save_data
	var id: StringName = state_id

	var apply: Callable = func(_order: Array, _target_phase: StringName) -> void:
		_action.phase = _target_phase
		target.set_state_actions(id, _order)
		signal_bus.request_structural_update.emit()

	if global.history:
		global.history.create_action('Move Action ' + HenActionsPanel.display_name(_action))
		global.history.add_do_method(apply.bind(new_order, _phase))
		global.history.add_undo_method(apply.bind(old_order, old_phase))
		global.history.commit_action()
	else:
		apply.call(new_order, _phase)


# false when this card has no such row, so the host can fan out to every list
func flash_action(_action_id: StringName) -> bool:
	var row: HenActionRow = _rows_by_id.get(str(_action_id))

	if not is_instance_valid(row):
		return false

	row.set_running(true)
	return true


func clear_flash() -> void:
	for row: Variant in _rows_by_id.values():
		if is_instance_valid(row):
			(row as HenActionRow).set_running(false)
