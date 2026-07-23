@tool
class_name HenActionsSearch extends VBoxContainer

const SIDE_BAR_ROW_SCENE = preload('res://addons/hengo/scenes/side_bar_row.tscn')
const CATEGORY_SCENE = preload('res://addons/hengo/scenes/side_bar_category.tscn')
const ACTION_COLOR: Color = Color('#7c93ff')
# folder of a user macro that declares none, so it lands in its own group
const USER_CATEGORY: String = 'my_macros'

var search_field: LineEdit
var results: VBoxContainer
var _state_id: StringName
# phase the new action lands on when the macro supports it; empty = macro default
var _phase: StringName
# action being swapped out, kept so the new one takes its slot
var _replacing: HenSaveAction
# loop action the new action is inserted into; null adds to the state list
var _parent: HenSaveAction


func setup(_id: StringName, _target_phase: StringName = &'', _replaced: HenSaveAction = null, _parent_action: HenSaveAction = null) -> void:
	_state_id = _id
	_phase = _target_phase
	_replacing = _replaced
	_parent = _parent_action


func _ready() -> void:
	search_field = get_node('%Search')
	results = get_node('%Results')

	var hint: Label = get_node('%Hint')
	hint.visible = _replacing != null
	if _replacing:
		hint.text = 'Replacing ' + HenActionsPanel.display_name(_replacing)

	# scale static chrome fonts before rows populate (rows scale themselves)
	ThemeUtils.apply_font_scale(self )

	search_field.text_changed.connect(_on_search_changed)
	_populate('')
	search_field.grab_focus()


func _on_search_changed(_text: String) -> void:
	_populate(_text)


# browsing groups by category, searching flattens — the grouping only helps while
# scanning the whole library
func _populate(_query: String) -> void:
	for child: Node in results.get_children():
		results.remove_child(child)
		child.queue_free()

	var query: String = _query.strip_edges().to_lower()

	if query.is_empty():
		_populate_grouped()
		return

	for macro: HenSaveMacro in _get_pool():
		if not macro.name.to_lower().contains(query):
			continue

		results.add_child(_build_row(macro))


func _populate_grouped() -> void:
	var groups: Dictionary = {}

	for macro: HenSaveMacro in _get_pool():
		var folder: String = macro.category

		if folder.is_empty():
			folder = USER_CATEGORY

		if not groups.has(folder):
			groups[folder] = []

		(groups[folder] as Array).append(macro)

	for folder: String in HenActionCategories.sorted(groups.keys()):
		var data: Dictionary = HenActionCategories.get_data(folder)
		var color: Color = Color(str(data.color))
		var category: HenSideBarCategory = CATEGORY_SCENE.instantiate()
		results.add_child(category)
		category.setup(str(data.name), -1, HenActionRow.icon_texture(str(data.icon)), color, true, '', false)

		for macro: HenSaveMacro in groups[folder]:
			category.add_row(_build_row(macro))


# same icon/color the row gets once added, so the search reads as the same list
func _build_row(_macro: HenSaveMacro) -> HenSideBarRow:
	var row: HenSideBarRow = SIDE_BAR_ROW_SCENE.instantiate()
	var color: Color = Color(_macro.color) if not _macro.color.is_empty() else ACTION_COLOR

	row.setup(_macro.name, _macro, HenActionRow.icon_texture(_macro.icon), color, false, 4)
	row.row_pressed.connect(_on_result_pressed)

	return row


# native plugin actions first, then the user's custom macros, both filtered by
# the class the current script extends
func _get_pool() -> Array[HenSaveMacro]:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var script_class: StringName = global.SAVE_DATA.identity.type if global.SAVE_DATA and global.SAVE_DATA.identity else &''
	var all: Array[HenSaveMacro] = []
	all.append_array(global.action_macros)
	all.append_array(global.script_macros)

	var pool: Array[HenSaveMacro] = []

	for macro: HenSaveMacro in all:
		if macro.serves_class(script_class):
			pool.append(macro)

	return pool


func _on_result_pressed(_meta: Variant, _mouse_button_index: int) -> void:
	if _mouse_button_index != MOUSE_BUTTON_LEFT or not _meta is HenSaveMacro:
		return

	_add_action(_meta as HenSaveMacro)
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).hide_popup()


# in replace mode the new action takes the slot of the old one; the inputs are not
# migrated because each macro declares its own schema
func _add_action(_macro: HenSaveMacro) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global.SAVE_DATA:
		return

	var action: HenSaveAction = HenSaveAction.create(_macro)
	action.phase = _target_phase(_macro)

	var state_id: StringName = _state_id
	var replaced: HenSaveAction = _replacing
	var parent: HenSaveAction = _parent
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')

	# a loop body is its own list; everything else is the state's action list
	var insert: Callable = func(_a: HenSaveAction, _i: int) -> void:
		if parent:
			parent.body_actions.insert(_i if _i >= 0 else parent.body_actions.size(), _a)
		else:
			global.SAVE_DATA.insert_state_action(state_id, _a, _i)
	var remove: Callable = func(_a: HenSaveAction) -> void:
		if parent:
			parent.body_actions.erase(_a)
		else:
			global.SAVE_DATA.remove_state_action(state_id, _a)

	var index: int = (parent.body_actions.find(replaced) if parent else global.SAVE_DATA.get_state_actions(state_id).find(replaced)) if replaced else -1

	var do_method: Callable = func() -> void:
		if replaced:
			remove.call(replaced)

		insert.call(action, index)
		signal_bus.request_structural_update.emit()

	if global.history:
		global.history.create_action(('Replace Action ' if replaced else 'Add Action ') + _macro.name)
		global.history.add_do_method(do_method)
		global.history.add_undo_method(func() -> void:
			remove.call(action)

			if replaced:
				insert.call(replaced, index)

			signal_bus.request_structural_update.emit()
		)
		global.history.commit_action()
	else:
		do_method.call()


# the phase asked for when the macro has a body for it, its default otherwise
func _target_phase(_macro: HenSaveMacro) -> StringName:
	if not _phase.is_empty() and HenSaveAction.supported_phases(_macro).has(_phase):
		return _phase

	return HenSaveAction.default_phase(_macro)
