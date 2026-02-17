@tool
class_name HenCompileAllReportPopup extends VBoxContainer

var report: Dictionary = {}


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override('separation', 8)

	var title: Label = Label.new()
	title.text = _get_title_text()
	add_child(title)

	var summary: Label = Label.new()
	summary.text = _get_summary_text()
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
		empty_label.text = 'Nenhum script encontrado para compilar.'
		list_box.add_child(empty_label)
		return

	for item_data: Dictionary in items:
		list_box.add_child(_create_item(item_data))


func _create_item(item_data: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var content := VBoxContainer.new()
	content.add_theme_constant_override('separation', 3)
	panel.add_child(content)

	var status_text: String = str(item_data.get('status', 'unknown')).to_upper()
	var script_name: String = str(item_data.get('script_name', item_data.get('script_id', '?')))
	var header: Label = Label.new()
	header.text = '%s [%s]' % [script_name, status_text]
	header.add_theme_color_override('font_color', _get_status_color(str(item_data.get('status', 'unknown'))))
	content.add_child(header)

	var id_label: Label = Label.new()
	id_label.text = 'ID: ' + str(item_data.get('script_id', '?'))
	content.add_child(id_label)

	var message: String = str(item_data.get('message', ''))
	if not message.is_empty():
		var msg_label: Label = Label.new()
		msg_label.text = message
		msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(msg_label)

	var errors: Array = item_data.get('errors', [])
	for err in errors:
		var err_label: Label = Label.new()
		err_label.text = '- ' + str(err)
		err_label.add_theme_color_override('font_color', Color('ef4444'))
		err_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(err_label)

	return panel


func _get_title_text() -> String:
	if bool(report.get('success', false)):
		return 'Batch Compilation Succeeded'
	return 'Batch Compilation Failed'


func _get_summary_text() -> String:
	var total: int = int(report.get('total', 0))
	var success_count: int = int(report.get('success_count', 0))
	var failed_count: int = int(report.get('failed_count', 0))
	var skipped_count: int = int(report.get('skipped_count', 0))
	var elapsed_ms: int = int(report.get('elapsed_ms', 0))
	return 'Total: %d | Success: %d | Failed: %d | Skipped: %d | Time: %dms' % [total, success_count, failed_count, skipped_count, elapsed_ms]


func _get_status_color(status: String) -> Color:
	match status:
		'success':
			return Color('22c55e')
		'failed':
			return Color('ef4444')
		'skipped':
			return Color('f59e0b')
	return Color('94a3b8')
