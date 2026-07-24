@tool
class_name HenActionsPanel extends PanelContainer

const ACTION_ROW_SCENE = preload('res://addons/hengo/scenes/action_row.tscn')
const ACTIONS_SEARCH_SCENE = preload('res://addons/hengo/scenes/actions_search.tscn')
const PHASE_HEADER_SCENE = preload('res://addons/hengo/scenes/action_phase_header.tscn')
const ICON_COLLAPSE_ALL = preload('res://addons/hengo/assets/new_icons/list-collapse.svg')
const ICON_EXPAND_ALL = preload('res://addons/hengo/assets/new_icons/chevrons-up-down.svg')
const TAB_INDEX: int = 4

var state_chip: PanelContainer
var state_name_label: Label
var add_bt: Button
var collapse_all_bt: Button
var hint_label: Label
var list: VBoxContainer

# action id -> folded, ui-only state that has to survive the list rebuilds
var _collapsed: Dictionary = {}
# action id -> the loop action holding it in body_actions, null when top level.
# rebuilt each update() so delete/replace/add know which list to touch
var _parent_of: Dictionary = {}


func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self ):
		return

	state_chip = get_node('%StateChip')
	state_name_label = get_node('%StateName')
	add_bt = get_node('%AddBt')
	collapse_all_bt = get_node('%CollapseAllBt')
	hint_label = get_node('%Hint')
	list = get_node('%List')

	add_bt.pressed.connect(_on_add_pressed)
	collapse_all_bt.pressed.connect(_on_collapse_all_pressed)

	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	if signal_bus:
		signal_bus.route_changed.connect(_on_route_changed)
		if not signal_bus.request_structural_update.is_connected(update):
			signal_bus.request_structural_update.connect(update)

	# value edits commit straight to the resource, so the preview refreshes on popup close
	var general_popup: HenGeneralPopup = Engine.get_singleton(&'GeneralPopup')
	if general_popup and not general_popup.closed.is_connected(update):
		general_popup.closed.connect(update)

	update()


func _on_route_changed(_route: HenRouteData) -> void:
	update()


func update() -> void:
	if not list:
		return

	_clear_list()

	var state_id: StringName = _get_current_state_id()

	if state_id.is_empty():
		state_name_label.text = 'No state'
		state_chip.visible = false
		hint_label.visible = true
		add_bt.disabled = true
		collapse_all_bt.visible = false
		return

	var global: HenGlobal = Engine.get_singleton(&'Global')

	# the route name is the id-based one it was created with; the resource holds the renamed one
	var state: HenSaveState = HenGeneratorAction.find_state(global.SAVE_DATA, state_id)
	state_name_label.text = state.name if state else (Engine.get_singleton(&'Router') as HenRouter).current_route.name
	state_chip.visible = true
	hint_label.visible = false
	add_bt.disabled = false

	# grouped by phase, in the order codegen emits them: visual order is run order
	var groups: Dictionary = group_by_phase(global.SAVE_DATA.get_state_actions(state_id))

	_parent_of.clear()

	for phase: StringName in HenSaveAction.PHASE_ORDER:
		var actions: Array = groups.get(str(phase), [])
		_add_phase_header(phase, actions.size())

		for action: HenSaveAction in actions:
			_add_row(action, 0, null)

	_refresh_collapse_all()


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

	var macro: HenSaveMacro = find_macro(_action.macro_id)

	# values render inline so reading an action doesn't need opening it. a nested
	# row is indented and, for now, not draggable
	row.setup({
		title = display_name(_action),
		icon = macro.icon if macro else '',
		color = macro.color if macro else '',
		doc = HenActionDoc.bbcode(macro),
		values = value_preview(_action),
		meta = _action,
		indent = _depth,
		draggable = _depth == 0
	}, value_parts(_action), _is_collapsed(_action))

	# a loop shows its nested actions indented right below, plus a nested add
	if macro and macro.has_body:
		for child: HenSaveAction in _action.body_actions:
			_add_row(child, _depth + 1, _action)

		_add_nested_add(_action, _depth + 1)


# a small "+" row that inserts an action into a loop's body
func _add_nested_add(_loop: HenSaveAction, _depth: int) -> void:
	# a MarginContainer indents it under the nested rows (Button has no margin constant)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override('margin_left', 4 + _depth * 18)

	var bt := Button.new()
	bt.text = '+ Add to loop'
	bt.flat = true
	bt.alignment = HORIZONTAL_ALIGNMENT_LEFT
	bt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	bt.add_theme_color_override('font_color', Color(1, 1, 1, 0.45))
	bt.pressed.connect(func() -> void: _open_search(_get_current_state_id(), &'', null, _loop))

	margin.add_child(bt)
	list.add_child(margin)


# drop on a row: land right above or below it, inside that row's phase
func _on_row_dropped(_dragged: HenSaveAction, _target: HenSaveAction, _before: bool) -> void:
	if not _dragged or not _target:
		return

	var index: int = drop_index(_current_actions(), _target, _dragged, _before)

	if index >= 0:
		_move_action(_dragged, _target.phase, index)


# slot the target row sits on, counted without the action being dragged; -1 when
# the target is gone from the list
static func drop_index(_actions: Array, _target: HenSaveAction, _dragged: HenSaveAction, _before: bool) -> int:
	var bucket: Array = []

	for action: HenSaveAction in _actions:
		if str(action.phase) == str(_target.phase) and action != _dragged:
			bucket.append(action)

	var index: int = bucket.find(_target)

	return -1 if index < 0 else (index if _before else index + 1)


# drop on a phase header: land at the top of that phase
func _on_header_dropped(_dragged: HenSaveAction, _phase: StringName) -> void:
	if _dragged:
		_move_action(_dragged, _phase, 0)


# rewrites the whole list so array order stays enter -> update -> exit
func _move_action(_action: HenSaveAction, _phase: StringName, _index: int) -> void:
	var state_id: StringName = _get_current_state_id()

	if state_id.is_empty():
		return

	var old_order: Array = _current_actions().duplicate()
	var old_phase: StringName = _action.phase
	var new_order: Array = reorder(old_order, _action, _phase, _index)

	if new_order == old_order and str(old_phase) == str(_phase):
		return

	var global: HenGlobal = Engine.get_singleton(&'Global')
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')

	var apply: Callable = func(_order: Array, _target_phase: StringName) -> void:
		_action.phase = _target_phase
		global.SAVE_DATA.set_state_actions(state_id, _order)
		signal_bus.request_structural_update.emit()

	if global.history:
		global.history.create_action('Move Action ' + display_name(_action))
		global.history.add_do_method(apply.bind(new_order, _phase))
		global.history.add_undo_method(apply.bind(old_order, old_phase))
		global.history.commit_action()
	else:
		apply.call(new_order, _phase)


# list with the action pulled out and reinserted at index inside the target phase
static func reorder(_actions: Array, _action: HenSaveAction, _phase: StringName, _index: int) -> Array:
	var rest: Array = _actions.duplicate()
	rest.erase(_action)

	var groups: Dictionary = group_by_phase(rest)
	var bucket: Array = groups.get(str(_phase), [])

	bucket.insert(clampi(_index, 0, bucket.size()), _action)
	groups[str(_phase)] = bucket

	return flatten_phases(groups)


func _on_row_collapse_toggled(_meta: Variant, _collapsed_state: bool) -> void:
	if _meta is HenSaveAction:
		_collapsed[str((_meta as HenSaveAction).id)] = _collapsed_state
		_refresh_collapse_all()


# folds everything, or unfolds everything once nothing is left expanded
func _on_collapse_all_pressed() -> void:
	var actions: Array = _current_actions()
	if actions.is_empty():
		return

	var collapse: bool = _expanded_count(actions) > 0

	# the all-or-nothing state persists; individual folds stay session-only
	var settings: HenSettings = _settings()
	if settings:
		settings.actions_expanded = not collapse

	_collapsed.clear()
	update()


func _refresh_collapse_all() -> void:
	var actions: Array = _current_actions()
	var all_folded: bool = _expanded_count(actions) == 0

	collapse_all_bt.visible = not actions.is_empty()
	collapse_all_bt.icon = ICON_EXPAND_ALL if all_folded else ICON_COLLAPSE_ALL
	collapse_all_bt.tooltip_text = 'Expand all' if all_folded else 'Collapse all'


func _expanded_count(_actions: Array) -> int:
	var count: int = 0

	for action: HenSaveAction in _actions:
		if not _is_collapsed(action):
			count += 1

	return count


# rows the session hasn't touched follow the persisted all-expanded flag
func _is_collapsed(_action: HenSaveAction) -> bool:
	var settings: HenSettings = _settings()
	return _collapsed.get(str(_action.id), not (settings.actions_expanded if settings else true))


func _settings() -> HenSettings:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	return global.SETTINGS if global else null


func _current_actions() -> Array:
	var state_id: StringName = _get_current_state_id()

	if state_id.is_empty():
		return []

	return (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA.get_state_actions(state_id)


# phase key -> actions, preserving the list order inside each phase
static func group_by_phase(_actions: Array) -> Dictionary:
	var groups: Dictionary = {}

	for phase: StringName in HenSaveAction.PHASE_ORDER:
		groups[str(phase)] = []

	for action: HenSaveAction in _actions:
		var key: String = str(action.phase)

		if not groups.has(key):
			groups[key] = []

		(groups[key] as Array).append(action)

	return groups


# flat list in run order; an unknown phase keeps its actions at the end
static func flatten_phases(_groups: Dictionary) -> Array:
	var out: Array = []

	for phase: StringName in HenSaveAction.PHASE_ORDER:
		out.append_array(_groups.get(str(phase), []))

	for key: Variant in _groups:
		if not HenSaveAction.PHASE_ORDER.has(StringName(str(key))):
			out.append_array(_groups[key])

	return out


# the action being dragged, or null when the payload is something else
static func dragged_action(_data: Variant) -> HenSaveAction:
	if not _data is Dictionary or str((_data as Dictionary).get('type', '')) != 'hengo_action':
		return null

	return (_data as Dictionary).get('action') as HenSaveAction


# a phase is only a valid target when the macro has a body for it
static func can_use_phase(_action: HenSaveAction, _phase: StringName) -> bool:
	var macro: HenSaveMacro = find_macro(_action.macro_id)

	if not macro:
		return str(_action.phase) == str(_phase)

	return HenSaveAction.supported_phases(macro).has(_phase)


static func find_macro(_macro_id: StringName) -> HenSaveMacro:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if global:
		for pool: Array in [global.action_macros, global.script_macros]:
			for macro: HenSaveMacro in pool:
				if macro.id == _macro_id:
					return macro

	return null


# resolves the macro pool's current name so renamed macros reach already-saved actions
static func display_name(_action: HenSaveAction) -> String:
	var macro: HenSaveMacro = find_macro(_action.macro_id)
	return macro.name if macro else _action.name


# one {kind, label, value} per input; kind picks the chip icon/color, and the
# label is dropped on single-input actions (the value alone already reads)
static func value_parts(_action: HenSaveAction) -> Array[Dictionary]:
	var macro: HenSaveMacro = find_macro(_action.macro_id)
	var show_names: bool = _action.inputs.size() > 1
	var parts: Array[Dictionary] = []

	for param: HenSaveParam in _action.inputs:
		var key: String = str(param.id)
		var part: Dictionary = _slot_part(_action, key, _seeded_value(macro, key, param.default_value), _is_raw(macro, key, param))

		# a slot that needs a source is unusable until bound, so say it out loud
		var declared: HenSaveParam = _macro_param(macro, key, param)

		if part.kind == &'literal' and (declared.lvalue or declared.bind_only):
			part.value = '(none)' if declared.optional else 'not set'

		part.label = param.name if show_names else ''
		parts.append(part)

	parts.append_array(output_parts(_action, macro))
	parts.append_array(branch_parts(_action, macro))

	return parts


# where each stored output lands, so a producer's reason to exist reads on the
# row; an unbound output is left out
static func output_parts(_action: HenSaveAction, _macro: HenSaveMacro) -> Array[Dictionary]:
	var parts: Array[Dictionary] = []

	if not _macro or _macro.outputs.is_empty():
		return parts

	var show_names: bool = _macro.outputs.size() > 1

	for output: HenSaveParam in _macro.outputs:
		var bind: String = str(_action.output_bindings.get(str(output.id), ''))

		if bind.is_empty():
			continue

		parts.append({
			kind = _bind_kind(bind),
			label = output.name if show_names else '',
			value = '-> ' + _bind_label(bind)
		})

	return parts


# where each configured branch goes; unset branches are left out of the row
static func branch_parts(_action: HenSaveAction, _macro: HenSaveMacro) -> Array[Dictionary]:
	var parts: Array[Dictionary] = []

	if not _macro:
		return parts

	var global: HenGlobal = Engine.get_singleton(&'Global')
	var save_data: HenSaveData = global.SAVE_DATA if global else null

	if not save_data:
		return parts

	for flow: HenSaveFlowParam in _macro.flow_outputs:
		var target: HenSaveState = HenGeneratorAction.branch_target(save_data, _action, str(flow.id))

		if target:
			var source: Dictionary = HenGeneratorAction.branch_instance_source(save_data, _action, str(flow.id))
			var source_name: String = _bind_label(str(source.value)) if str(source.get('kind', '')) == 'bind' else str(source.get('value', ''))
			var suffix: String = (' @ ' + source_name) if not source.is_empty() else ''
			parts.append({kind = &'branch', label = flow.name, value = '-> ' + target.name + suffix})

	return parts


# flattened parts, used as the row tooltip when the chips clip
static func value_preview(_action: HenSaveAction) -> String:
	var texts: PackedStringArray = []

	for part: Dictionary in value_parts(_action):
		var value: String = ('(' + str(part.value) + ')') if part.kind == &'expression' else str(part.value)
		texts.append((str(part.label) + ': ' + value) if not str(part.label).is_empty() else value)

	return ' · '.join(texts)


# same precedence codegen uses: expression > binding > literal
static func _slot_part(_action: HenSaveAction, _key: String, _value: Variant, _raw: bool = false) -> Dictionary:
	if _action.input_expressions.has(_key):
		return {kind = &'expression', value = (_action.input_expressions[_key] as HenSaveActionExpression).code}

	var bind: String = _action.input_bindings.get(_key, '')

	if not bind.is_empty():
		return {kind = _bind_kind(bind), value = _bind_label(bind)}

	# a raw input is emitted verbatim, so quoting it here would misread as a string
	if _raw:
		return {kind = &'literal', value = str(_value) if _value != null else '—'}

	return {kind = &'literal', value = format_value(_value)}


static func _is_raw(_macro: HenSaveMacro, _key: String, _param: HenSaveParam) -> bool:
	return _macro_param(_macro, _key, _param).raw


# the flags live on the macro definition; an action saved before they existed
# falls back to its own clone
static func _macro_param(_macro: HenSaveMacro, _key: String, _param: HenSaveParam) -> HenSaveParam:
	if not _macro:
		return _param

	for p: HenSaveParam in _macro.inputs:
		if str(p.id) == _key:
			return p

	return _param


# a bound slot is one of the script's variables, an engine-provided value or a
# native property
static func _bind_kind(_bind: String) -> StringName:
	var save_data: HenSaveData = _save_data()

	var bind: Dictionary = HenUtils.classify_bind_code(save_data, _bind)

	match str(bind.kind):
		'var':
			return &'variable'
		'native':
			# a source may ask for another chip: a node path reads as a node, not
			# as an engine value
			return StringName(str((bind.value as Dictionary).get('kind', 'native')))

	return &'property'


# bindings are stored by id, so the row shows the variable's current name
static func _bind_label(_bind: String) -> String:
	return HenUtils.get_bind_label(_save_data(), _bind)


static func _save_data() -> HenSaveData:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	return global.SAVE_DATA if global else null


# literals read like code: strings quoted, an unset value shows as a dash
static func format_value(_value: Variant) -> String:
	if _value == null:
		return '—'

	if _value is String or _value is StringName:
		return "'" + str(_value) + "'"

	if _value is float:
		return str(snappedf(_value as float, 0.001))

	return str(_value)


# pre-binding actions stored null, so the macro default is what the inspector shows
static func _seeded_value(_macro: HenSaveMacro, _key: String, _value: Variant) -> Variant:
	if _value != null or not _macro:
		return _value

	for input: HenSaveParam in _macro.inputs:
		if str(input.id) == _key:
			return input.default_value

	return null


# left-click opens the anchored param editor (reuses HenInspector, value-only)
func _on_action_row_pressed(_meta: Variant, _button: int) -> void:
	if _button != MOUSE_BUTTON_LEFT or not _meta is HenSaveAction:
		return

	var state_id: StringName = _get_current_state_id()
	if state_id.is_empty():
		return

	var action: HenSaveAction = _meta as HenSaveAction
	# a nested action runs at the loop's phase, so it hides the phase selector
	var nested: bool = _parent_of.get(str(action.id)) != null
	HenInspector.edit_resource(action, display_name(action), _action_menu(action, state_id), _popup_opts(), nested)


func _popup_opts() -> Dictionary:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	return {
		layout = HenGeneralPopup.Layout.ANCHORED,
		anchor_to = global.SIDE_PANEL,
		side = SIDE_RIGHT,
		fill_axis = true,
		blur = true,
		min_size = Vector2(320, 0)
	}


func _action_menu(_action: HenSaveAction, _state_id: StringName) -> Array[Dictionary]:
	return [
		{
			name = 'Replace',
			callable = _replace_action.bind(_action, _state_id),
			icon = 'res://addons/hengo/assets/new_icons/replace.svg'
		},
		{
			name = 'Delete',
			callable = _delete_action.bind(_action, _state_id),
			color = Color('#c16460'),
			icon = 'res://addons/hengo/assets/new_icons/trash-2.svg'
		}
	]


# swaps the macro keeping the slot: the search comes back in replace mode
func _replace_action(_action: HenSaveAction, _state_id: StringName) -> void:
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).hide_popup()
	_open_search(_state_id, _action.phase, _action, _parent_of.get(str(_action.id)))


func _delete_action(_action: HenSaveAction, _state_id: StringName) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var parent: HenSaveAction = _parent_of.get(str(_action.id))

	if parent:
		# a nested action is removed from its loop's body, not the state list
		parent.body_actions.erase(_action)
	elif global.SAVE_DATA:
		global.SAVE_DATA.remove_state_action(_state_id, _action)

	_collapsed.erase(str(_action.id))

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).hide_popup()
	update()


func _clear_list() -> void:
	for child: Node in list.get_children():
		list.remove_child(child)
		child.queue_free()


# active state id, or empty when not inside a state route
func _get_current_state_id() -> StringName:
	var router: HenRouter = Engine.get_singleton(&'Router')
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if not router or not router.current_route or not global or not global.SAVE_DATA:
		return &''

	if router.current_route.type != HenRouter.ROUTE_TYPE.STATE:
		return &''

	return router.current_route.id


# the header buttons pass their own phase; the panel button lets the macro decide
func _on_add_pressed(_phase: StringName = &'') -> void:
	_open_search(_get_current_state_id(), _phase, null)


func _open_search(_state_id: StringName, _phase: StringName, _replacing: HenSaveAction, _parent: HenSaveAction = null) -> void:
	if _state_id.is_empty():
		return

	var search: HenActionsSearch = ACTIONS_SEARCH_SCENE.instantiate()
	search.setup(_state_id, _phase, _replacing, _parent)

	var global: HenGlobal = Engine.get_singleton(&'Global')
	var opts: Dictionary = {
		layout = HenGeneralPopup.Layout.ANCHORED,
		anchor_to = global.SIDE_PANEL,
		side = SIDE_RIGHT,
		min_size = Vector2(320, 360)
	}

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(search, opts)
