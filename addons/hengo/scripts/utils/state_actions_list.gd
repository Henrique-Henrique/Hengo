@tool
class_name HenStateActionsList extends VBoxContainer

const ACTION_ROW_SCENE = preload('res://addons/hengo/scenes/action_row.tscn')
const ACTIONS_SEARCH_SCENE = preload('res://addons/hengo/scenes/actions_search.tscn')
const PHASE_HEADER_SCENE = preload('res://addons/hengo/scenes/action_phase_header.tscn')

# fixed so editing a value never resizes the card
const CONTENT_WIDTH: float = 260.0

signal structure_changed
signal focus_requested

var save_data: HenSaveData
var state_id: StringName
var is_editing: bool = false

var list: VBoxContainer
var add_bt: Button

# static so a rebuild cannot snap an open row shut
static var _collapsed: Dictionary = {}
# action id -> the loop action holding it, null at top level
var _parent_of: Dictionary = {}
var _rows_by_id: Dictionary = {}


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
	row.collapse_toggled.connect(_on_row_collapse_toggled)
	row.action_dropped.connect(_on_row_dropped)
	list.add_child(row)
	_rows_by_id[str(_action.id)] = row

	var macro: HenSaveMacro = HenActionsPanel.find_macro(_action.macro_id)

	row.setup({
		title = HenActionsPanel.display_name(_action),
		icon = macro.icon if macro else '',
		color = macro.color if macro else '',
		doc = HenActionDoc.bbcode(macro),
		values = HenActionsPanel.value_preview(_action),
		meta = _action,
		indent = _depth,
		draggable = _depth == 0
	}, HenActionsPanel.value_parts(_action), _is_collapsed(_action))

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


func _is_collapsed(_action: HenSaveAction) -> bool:
	var settings: HenSettings = _settings()
	return _collapsed.get(_fold_key(_action), not (settings.actions_expanded if settings else false))


func _fold_key(_action: HenSaveAction) -> String:
	var script_id: String = str(save_data.identity.id) if save_data and save_data.identity else ''
	return script_id + ':' + str(_action.id)


func _settings() -> HenSettings:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	return global.SETTINGS if global else null


# mutations read the active script, so another card asks to be focused first
func _is_active() -> bool:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	return global != null and save_data != null and global.SAVE_DATA == save_data


func _on_row_collapse_toggled(_meta: Variant, _collapsed_state: bool) -> void:
	if _meta is HenSaveAction:
		_collapsed[_fold_key(_meta as HenSaveAction)] = _collapsed_state
		structure_changed.emit()


func _on_action_row_pressed(_meta: Variant, _button: int) -> void:
	if _button != MOUSE_BUTTON_LEFT or not _meta is HenSaveAction:
		return

	if not _is_active():
		focus_requested.emit()
		return

	var action: HenSaveAction = _meta as HenSaveAction
	var row: HenActionRow = _rows_by_id.get(str(action.id))
	var nested: bool = _parent_of.get(str(action.id)) != null

	is_editing = true

	HenInspector.edit_resource(
		action,
		HenActionsPanel.display_name(action),
		_action_menu(action),
		_popup_opts(row),
		nested,
		true
	)


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

	_collapsed.erase(_fold_key(_action))

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
