@tool
class_name HenCompileResultPanel extends PanelContainer

const _COMPILE_ALL_REPORT_POPUP = preload('res://addons/hengo/scenes/utils/compile_all_report_popup.tscn')
const _ICON_SUCCESS: Texture2D = preload('res://addons/hengo/assets/new_icons/circle-check.svg')
const _ICON_FAILED: Texture2D = preload('res://addons/hengo/assets/new_icons/shield-alert.svg')
const _ICON_SKIPPED: Texture2D = preload('res://addons/hengo/assets/new_icons/circle-minus.svg')
const _ICON_EXPAND: Texture2D = preload('res://addons/hengo/assets/new_icons/chevron-down.svg')

static var last_report: Dictionary = {}

var report: Dictionary = {}

var _expanded: bool = false
var _detail_container: Control
var _expand_btn: Button
var _separator: HSeparator


func _ready() -> void:
	z_index = 150
	mouse_filter = MOUSE_FILTER_STOP

	var w: int = HenUtils.get_scaled_size(320)
	custom_minimum_size = Vector2(w, 0)

	HenCompileResultPanel.last_report = report

	_build_ui()
	call_deferred('_position_and_animate')


func _build_ui() -> void:
	var success: bool = bool(report.get('success', false))
	var success_count: int = int(report.get('success_count', 0))
	var failed_count: int = int(report.get('failed_count', 0))
	var skipped_count: int = int(report.get('skipped_count', 0))
	var elapsed_ms: int = int(report.get('elapsed_ms', 0))

	var outer := VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override('separation', 0)
	add_child(outer)

	# Header
	var header_margin := MarginContainer.new()
	header_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var m: int = HenUtils.get_scaled_size(8)
	header_margin.add_theme_constant_override('margin_left', m)
	header_margin.add_theme_constant_override('margin_top', m)
	header_margin.add_theme_constant_override('margin_right', int(m * 0.5))
	header_margin.add_theme_constant_override('margin_bottom', m)
	outer.add_child(header_margin)

	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override('separation', 6)
	header_margin.add_child(header)

	# Status icon
	var status_icon := TextureRect.new()
	status_icon.texture = _ICON_SUCCESS if success else _ICON_FAILED
	status_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	status_icon.custom_minimum_size = Vector2(16, 16)
	status_icon.modulate = Color('22c55e') if success else Color('ef4444')
	header.add_child(status_icon)

	# Summary label
	var summary := Label.new()
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.add_theme_font_size_override('font_size', HenUtils.get_scaled_size(12))
	var parts: Array[String] = []
	if success_count > 0:
		parts.append('%d compiled' % success_count)
	if failed_count > 0:
		parts.append('%d failed' % failed_count)
	if skipped_count > 0:
		parts.append('%d skipped' % skipped_count)
	parts.append('%dms' % elapsed_ms)
	summary.text = ' · '.join(parts)
	header.add_child(summary)

	# expand button
	_expand_btn = Button.new()
	_expand_btn.icon = _ICON_EXPAND
	_expand_btn.flat = true
	_expand_btn.custom_minimum_size = Vector2(HenUtils.get_scaled_size(26), HenUtils.get_scaled_size(26))
	_expand_btn.tooltip_text = 'Show details'
	_expand_btn.pressed.connect(_toggle_expand)
	header.add_child(_expand_btn)

	# close button
	var close_btn := Button.new()
	close_btn.text = '×'
	close_btn.flat = true
	close_btn.custom_minimum_size = Vector2(HenUtils.get_scaled_size(26), HenUtils.get_scaled_size(26))
	close_btn.add_theme_font_size_override('font_size', HenUtils.get_scaled_size(15))
	close_btn.tooltip_text = 'Dismiss'
	close_btn.pressed.connect(_dismiss)
	header.add_child(close_btn)

	# separator (hidden while collapsed)
	_separator = HSeparator.new()
	_separator.visible = false
	outer.add_child(_separator)

	# detail section (hidden while collapsed)
	_detail_container = VBoxContainer.new()
	_detail_container.visible = false
	_detail_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_container.add_theme_constant_override('separation', 0)
	outer.add_child(_detail_container)

	_build_detail_list()


func _build_detail_list() -> void:
	var items: Array = report.get('items', [])

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var max_h: int = HenUtils.get_scaled_size(220)
	scroll.custom_minimum_size = Vector2(0, min(items.size() * HenUtils.get_scaled_size(28), max_h))
	_detail_container.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override('separation', 2)
	scroll.add_child(list)

	if items.is_empty():
		var empty := Label.new()
		empty.text = 'No scripts found.'
		empty.add_theme_color_override('font_color', Color('9ca3af'))
		list.add_child(empty)
	else:
		var sorted: Array = items.duplicate()
		sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return _item_rank(str(a.get('status', ''))) < _item_rank(str(b.get('status', '')))
		)
		for item_data: Dictionary in sorted:
			list.add_child(_create_row(item_data))

	# footer with "Open Full Report" button
	var footer_margin := MarginContainer.new()
	var m: int = HenUtils.get_scaled_size(6)
	footer_margin.add_theme_constant_override('margin_left', m)
	footer_margin.add_theme_constant_override('margin_top', m)
	footer_margin.add_theme_constant_override('margin_right', m)
	footer_margin.add_theme_constant_override('margin_bottom', m)
	_detail_container.add_child(footer_margin)

	var full_btn := Button.new()
	full_btn.text = 'Open Full Report'
	full_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	full_btn.flat = false
	full_btn.pressed.connect(_open_full_report)
	footer_margin.add_child(full_btn)


func _create_row(item_data: Dictionary) -> Control:
	var status: String = str(item_data.get('status', '')).to_lower()
	var m: int = HenUtils.get_scaled_size(6)
	var row_margin := MarginContainer.new()
	row_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_margin.add_theme_constant_override('margin_left', m)
	row_margin.add_theme_constant_override('margin_right', m)
	row_margin.add_theme_constant_override('margin_top', 2)
	row_margin.add_theme_constant_override('margin_bottom', 2)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override('separation', 6)
	row_margin.add_child(row)

	var icon := TextureRect.new()
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(14, 14)
	match status:
		'success':
			icon.texture = _ICON_SUCCESS
			icon.modulate = Color('22c55e')
		'failed':
			icon.texture = _ICON_FAILED
			icon.modulate = Color('ef4444')
		_:
			icon.texture = _ICON_SKIPPED
			icon.modulate = Color('6b7280')
	row.add_child(icon)

	var name_label := Label.new()
	name_label.text = str(item_data.get('script_name', item_data.get('script_id', '?')))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.add_theme_font_size_override('font_size', HenUtils.get_scaled_size(11))
	match status:
		'success':
			name_label.add_theme_color_override('font_color', Color('d1d5db'))
		'failed':
			name_label.add_theme_color_override('font_color', Color('ef4444'))
		_:
			name_label.add_theme_color_override('font_color', Color('6b7280'))
	row.add_child(name_label)

	var status_label := Label.new()
	status_label.text = status.to_upper()
	status_label.add_theme_font_size_override('font_size', HenUtils.get_scaled_size(10))
	match status:
		'success':
			status_label.add_theme_color_override('font_color', Color('22c55e'))
		'failed':
			status_label.add_theme_color_override('font_color', Color('ef4444'))
		_:
			status_label.add_theme_color_override('font_color', Color('6b7280'))
	row.add_child(status_label)

	return row_margin


func _item_rank(status: String) -> int:
	match status.to_lower():
		'failed': return 0
		'success': return 1
		'skipped': return 2
	return 3


func _toggle_expand() -> void:
	_expanded = not _expanded
	_detail_container.visible = _expanded
	_separator.visible = _expanded
	_expand_btn.pivot_offset = _expand_btn.size / 2.0
	_expand_btn.tooltip_text = 'Hide details' if _expanded else 'Show details'

	var tween := get_tree().create_tween()
	var target_rotation: float = PI if _expanded else 0.0
	tween.tween_property(_expand_btn, 'rotation', target_rotation, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _open_full_report() -> void:
	var popup_content: HenCompileAllReportPopup = _COMPILE_ALL_REPORT_POPUP.instantiate()
	popup_content.report = report
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(popup_content, 'Compile All — Full Report')


func _dismiss() -> void:
	var tween := get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(self , 'position:x', position.x + HenUtils.get_scaled_size(20), 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self , 'modulate:a', 0.0, 0.18).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_callback(queue_free)


func _position_and_animate() -> void:
	var parent := get_parent() as Control
	if not parent:
		queue_free()
		return

	var margin: int = HenUtils.get_scaled_size(12)
	var toolbar_h: int = HenUtils.get_scaled_size(50)
	var w: int = HenUtils.get_scaled_size(320)

	# Place at top-right, just below the toolbar
	var target_x: float = parent.size.x - w - margin
	position = Vector2(parent.size.x + 10, toolbar_h)
	modulate.a = 0.0

	var tween := get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(self , 'position:x', target_x, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self , 'modulate:a', 1.0, 0.25).set_trans(Tween.TRANS_SINE)
