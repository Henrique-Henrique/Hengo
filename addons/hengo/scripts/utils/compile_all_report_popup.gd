@tool
class_name HenCompileAllReportPopup extends VBoxContainer

var report: Dictionary = {}
const _STATUS_ICON_SUCCESS: Texture2D = preload('res://addons/hengo/assets/new_icons/circle-check.svg')
const _STATUS_ICON_FAILED: Texture2D = preload('res://addons/hengo/assets/new_icons/shield-alert.svg')
const _STATUS_ICON_SKIPPED: Texture2D = preload('res://addons/hengo/assets/new_icons/circle-minus.svg')
const _STATUS_ICON_DEFAULT: Texture2D = preload('res://addons/hengo/assets/new_icons/clock.svg')
const _SCRIPT_ICON: Texture2D = preload('res://addons/hengo/assets/new_icons/file-text.svg')
const _ID_ICON: Texture2D = preload('res://addons/hengo/assets/new_icons/hash.svg')

# what the last batch did, so the report opened from the toolbar can still tell
# which scripts were written and which were up to date
static var last_report: Dictionary = {}


# the state of the project right now: a broken action is what the button counts,
# and the last batch fills in what it did with the scripts that have none
static func live_report() -> Dictionary:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var previous: Dictionary = {}
	var items: Array = []
	var counts: Dictionary = {}

	for entry: Variant in last_report.get('items', []):
		previous[str((entry as Dictionary).get('script_id', ''))] = entry

	for save_data: HenSaveData in _scanned(global):
		var item: Dictionary = _live_item(save_data, previous)

		counts[item.status] = int(counts.get(item.status, 0)) + 1
		items.append(item)
		previous.erase(str(item.script_id))

	# a script of another collection is only known through the last batch
	for entry: Variant in previous.values():
		var status: String = str((entry as Dictionary).get('status', 'skipped'))

		counts[status] = int(counts.get(status, 0)) + 1
		items.append(entry)

	return {
		title = 'Actions',
		items = items,
		total = items.size(),
		success_count = int(counts.get('success', 0)),
		failed_count = int(counts.get('failed', 0)),
		skipped_count = int(counts.get('skipped', 0)),
		success = int(counts.get('failed', 0)) == 0,
		aborted = false
	}


# the root owns the scope, so the count on the button and this list never disagree
static func _scanned(_global: HenGlobal) -> Array[HenSaveData]:
	if not _global:
		return []

	if _global.HENGO_ROOT:
		return _global.HENGO_ROOT.scanned_scripts()

	var out: Array[HenSaveData] = []

	out.assign(_global.OPEN_SCRIPTS)

	return out


static func _live_item(_save_data: HenSaveData, _previous: Dictionary) -> Dictionary:
	var id: String = str(_save_data.identity.id) if _save_data.identity else ''
	var broken: Array[Dictionary] = HenGeneratorAction.collect_errors(_save_data)
	var item: Dictionary = {
		script_id = id,
		script_name = _save_data.identity.name if _save_data.identity else id,
		status = 'success',
		message = 'No broken actions.',
		errors = []
	}

	if not broken.is_empty():
		item.status = 'failed'
		item.message = 'Broken action(s): ' + str(broken.size()) + '.'
		item.errors = broken
	elif _previous.has(id):
		item.status = str((_previous[id] as Dictionary).get('status', 'success'))
		item.message = str((_previous[id] as Dictionary).get('message', ''))

	return item


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override('separation', 10)

	var title: Label = Label.new()
	title.text = _get_title_text()
	ThemeUtils.apply_font_size(title, 18)
	add_child(title)

	var summary: Label = Label.new()
	summary.text = _get_summary_text()
	summary.add_theme_color_override('font_color', Color('9ca3af'))
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(summary)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 300)
	add_child(scroll)

	var list_box: VBoxContainer = VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.add_theme_constant_override('separation', 6)
	scroll.add_child(list_box)

	var items: Array = report.get('items', [])
	if items.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = 'No scripts to show.'
		empty_label.add_theme_color_override('font_color', Color('9ca3af'))
		list_box.add_child(empty_label)
		return

	var sorted_items: Array = items.duplicate(true)
	sorted_items.sort_custom(_sort_items_by_status)
	for item_data: Dictionary in sorted_items:
		list_box.add_child(_create_item(item_data))


func _create_item(item_data: Dictionary) -> Control:
	var status: String = str(item_data.get('status', 'unknown')).to_lower()
	if status == 'skipped':
		return _create_skipped_item(item_data)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override('panel', _create_item_style(status))

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override('separation', 3)
	panel.add_child(content)

	var header_row := HBoxContainer.new()
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_theme_constant_override('separation', 8)
	content.add_child(header_row)

	var status_icon := TextureRect.new()
	status_icon.texture = _get_status_icon(status)
	status_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	status_icon.custom_minimum_size = Vector2(18, 18)
	header_row.add_child(status_icon)

	var script_icon := TextureRect.new()
	script_icon.texture = _SCRIPT_ICON
	script_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	script_icon.custom_minimum_size = Vector2(16, 16)
	header_row.add_child(script_icon)

	var script_name: String = str(item_data.get('script_name', item_data.get('script_id', '?')))
	var status_text: String = status.to_upper()
	var header: Label = Label.new()
	header.text = '%s  [%s]' % [script_name, status_text]
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_color_override('font_color', _get_status_color(status))
	header_row.add_child(header)

	var id_box := HBoxContainer.new()
	id_box.add_theme_constant_override('separation', 4)
	header_row.add_child(id_box)

	var id_icon := TextureRect.new()
	id_icon.texture = _ID_ICON
	id_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	id_icon.custom_minimum_size = Vector2(14, 14)
	id_icon.modulate = Color('9ca3af')
	id_box.add_child(id_icon)

	var id_label: Label = Label.new()
	id_label.text = str(item_data.get('script_id', '?'))
	id_label.add_theme_color_override('font_color', Color('9ca3af'))
	id_box.add_child(id_label)

	var message: String = str(item_data.get('message', ''))
	if not message.is_empty():
		var msg_label: Label = Label.new()
		msg_label.text = message
		msg_label.add_theme_color_override('font_color', Color('d1d5db'))
		msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(msg_label)

	var errors: Array = item_data.get('errors', [])
	for err: Variant in errors:
		content.add_child(_create_error_row(err))

	return panel


# a broken action carries where it is, the other failures are plain text
func _create_error_row(_error: Variant) -> Control:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override('separation', 8)

	var text: String = str((_error as Dictionary).get('description', '')) if _error is Dictionary else str(_error)
	var label: Label = Label.new()

	label.text = '- ' + text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override('font_color', Color('ef4444'))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)

	if _error is Dictionary and not str((_error as Dictionary).get('action_id', '')).is_empty():
		var button: Button = Button.new()

		button.text = 'Go to'
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.pressed.connect(_go_to.bind(_error as Dictionary))
		row.add_child(button)

	return row


# navigates to the action, switching scripts if necessary
func _go_to(_error: Dictionary) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if not global:
		return

	var script_id: StringName = StringName(str(_error.get('script_id', '')))
	var target: HenSaveData = null

	for save_data: HenSaveData in global.OPEN_SCRIPTS:
		if save_data.identity and StringName(str(save_data.identity.id)) == script_id:
			target = save_data
			break

	if not target:
		(Engine.get_singleton(&'ToastContainer') as HenToast).notify.call_deferred(
			'The script of this error is not open.', HenToast.MessageType.ERROR
		)
		return

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).hide_all()
	(Engine.get_singleton(&'Loader') as HenLoader).set_active_script(target)

	var flow: HenFlowViewer = global.HENGO_ROOT.get_node_or_null('%FlowViewer') if global.HENGO_ROOT else null

	if flow:
		flow.focus_action.call_deferred(str(_error.get('action_id', '')))


func _create_skipped_item(item_data: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override('panel', _create_item_style('skipped'))

	var row := HBoxContainer.new()
	row.add_theme_constant_override('separation', 8)
	panel.add_child(row)

	var status_icon := TextureRect.new()
	status_icon.texture = _STATUS_ICON_SKIPPED
	status_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	status_icon.custom_minimum_size = Vector2(16, 16)
	status_icon.modulate = Color('9ca3af')
	row.add_child(status_icon)

	var script_name: String = str(item_data.get('script_name', item_data.get('script_id', '?')))
	var name_label := Label.new()
	name_label.text = script_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override('font_color', Color('9ca3af'))
	row.add_child(name_label)

	var id_label := Label.new()
	id_label.text = '#' + str(item_data.get('script_id', '?'))
	id_label.add_theme_color_override('font_color', Color('6b7280'))
	row.add_child(id_label)

	var status_label := Label.new()
	status_label.text = 'SKIPPED'
	status_label.add_theme_color_override('font_color', Color('6b7280'))
	row.add_child(status_label)
	return panel


func _get_title_text() -> String:
	if report.has('title'):
		return str(report.title)

	if bool(report.get('success', false)):
		return 'Batch Compilation Succeeded'
	return 'Batch Compilation Failed'


func _get_summary_text() -> String:
	var total: int = int(report.get('total', 0))
	var success_count: int = int(report.get('success_count', 0))
	var failed_count: int = int(report.get('failed_count', 0))
	var skipped_count: int = int(report.get('skipped_count', 0))
	var text: String = 'Total: %d | Success: %d | Failed: %d | Skipped: %d' % [total, success_count, failed_count, skipped_count]

	# only a batch was ever timed, the live report just says what the project holds
	if report.has('elapsed_ms'):
		text += ' | Time: %dms' % int(report.elapsed_ms)

	return text


func _sort_items_by_status(a: Dictionary, b: Dictionary) -> bool:
	return _status_rank(str(a.get('status', 'unknown')).to_lower()) < _status_rank(str(b.get('status', 'unknown')).to_lower())


func _status_rank(status: String) -> int:
	if status == 'skipped':
		return 1
	return 0


func _create_item_style(status: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8

	if status == 'skipped':
		style.bg_color = Color(0.07, 0.07, 0.07, 0.45)
		style.border_color = Color('374151')
	else:
		var accent := _get_status_color(status)
		style.bg_color = Color(accent.r, accent.g, accent.b, 0.08)
		style.border_color = Color(accent.r, accent.g, accent.b, 0.35)
	return style


func _get_status_icon(status: String) -> Texture2D:
	match status:
		'success':
			return _STATUS_ICON_SUCCESS
		'failed':
			return _STATUS_ICON_FAILED
		'skipped':
			return _STATUS_ICON_SKIPPED
	return _STATUS_ICON_DEFAULT


func _get_status_color(status: String) -> Color:
	match status:
		'success':
			return Color('22c55e')
		'failed':
			return Color('ef4444')
		'skipped':
			return Color('9ca3af')
	return Color('94a3b8')
