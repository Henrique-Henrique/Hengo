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

# where a brand new action lands; -1 appends to the end of its phase
var _insert_at: int = -1
var _on_pick: Callable = Callable()
var _producer_type: String = ''


func setup(_id: StringName, _target_phase: StringName = &'', _replaced: HenSaveAction = null, _parent_action: HenSaveAction = null, _at: int = -1) -> void:
	_state_id = _id
	_phase = _target_phase
	_replacing = _replaced
	_parent = _parent_action
	_insert_at = _at


# _ready runs inside the add_child of show_content, so a caller that configures
# the picker afterwards gets a list that was populated with no filter at all
func setup_producer_picker(_type: String, _pick: Callable) -> void:
	_producer_type = _type
	_on_pick = _pick

	HenActionPool.invalidate()

	if is_node_ready():
		_populate(search_field.text if is_instance_valid(search_field) else '')


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
	# deferred because the popup places itself deferred too, and focus taken on the
	# frame the container jumps is dropped
	search_field.grab_focus.call_deferred()


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

		results.add_child(_build_row(macro, true))


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
		category.setup(str(data.name), -1, HenActionVisuals.icon_texture(str(data.icon)), color, true, '', false)

		for macro: HenSaveMacro in groups[folder]:
			category.add_row(_build_row(macro))


# same icon/color the row gets once added, so the search reads as the same list.
# a flat list has no category header, and two actions of a 2d/3d pair share a name
func _build_row(_macro: HenSaveMacro, _with_category: bool = false) -> HenSideBarRow:
	var row: HenSideBarRow = SIDE_BAR_ROW_SCENE.instantiate()
	var color: Color = Color(_macro.color) if not _macro.color.is_empty() else ACTION_COLOR

	row.setup(_macro.name, _macro, HenActionVisuals.icon_texture(_macro.icon), color, false, 4)

	if _with_category:
		var data: Dictionary = HenActionCategories.get_data(_macro.category)
		row.set_type_badge(str(data.name), Color(str(data.color)))
	# native tooltip: the search popup lives on the editor base control, above the
	# custom HenTooltip, so only the native one renders on top of it
	row.tooltip_text = HenActionDoc.plain(_macro)
	row.row_pressed.connect(_on_result_pressed)

	return row


# native plugin actions first, then the user's custom macros, both filtered by
# the class the current script extends
func _get_pool() -> Array[HenSaveMacro]:
	return HenActionPool.producers_for(_producer_type)


func _on_result_pressed(_meta: Variant, _mouse_button_index: int) -> void:
	if _mouse_button_index != MOUSE_BUTTON_LEFT or not _meta is HenSaveMacro:
		return

	# adding and replacing live in HenStateViewerCardEditor now: this is a picker
	if not _on_pick.is_valid():
		return

	_on_pick.call(_meta as HenSaveMacro)
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).hide_popup()


# in replace mode the new action takes the slot of the old one; the inputs are not
# migrated because each macro declares its own schema
# the phase asked for when the macro has a body for it, its default otherwise
func _target_phase(_macro: HenSaveMacro) -> StringName:
	if not _phase.is_empty() and HenSaveAction.supported_phases(_macro).has(_phase):
		return _phase

	return HenSaveAction.default_phase(_macro)
