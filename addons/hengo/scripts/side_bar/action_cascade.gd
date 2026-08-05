@tool
class_name HenActionCascade extends Control


const INSPECTOR_SCENE: String = 'res://addons/hengo/scenes/custom_inspector.tscn'
const DROPDOWN_SCENE: String = 'res://addons/hengo/scenes/drop_down_menu.tscn'
const CLOSE_ICON: String = 'res://addons/hengo/assets/new_icons/x.svg'

const PANEL_WIDTH: float = 320.0
const PANEL_GAP: float = 8.0
const ACCENT: Color = Color('#ff9e64')
const TRAIL_COLOR: Color = Color('#8fa0b8')
const FOOTER_COLOR: Color = Color('#6e7889')

static var _current_popup: HenPopupContainer = null

var _sidebar: HenInspector
var _scroll: ScrollContainer
var _strip: HBoxContainer
# empty space before the first panel, so it opens beside the inspector
var _lead_in: float = 0.0
# keys: panel, inspector, child, ref, parent_slot, ret_label, out_bt
var _levels: Array[Dictionary] = []


static func open(_inspector: HenInspector, _slot: Dictionary, _chip: Control) -> void:
	close_current()

	var gp: HenGeneralPopup = Engine.get_singleton(&'GeneralPopup')
	var base: Control = EditorInterface.get_base_control()

	var cascade: HenActionCascade = HenActionCascade.new()
	cascade._sidebar = _inspector

	var screen: Rect2 = base.get_global_rect()
	var insp_rect: Rect2 = _inspector.get_global_rect()
	var chip_rect: Rect2 = _chip.get_global_rect()

	var gap: float = 12.0
	var edge: float = 12.0
	var x: float = screen.position.x + edge
	var width: float = screen.size.x - 2.0 * edge

	cascade._lead_in = maxf(0.0, insp_rect.end.x + gap - x)

	var height: float = clampf(screen.size.y - 2.0 * edge, 240.0, 460.0)
	var y: float = clampf(chip_rect.position.y - 6.0, screen.position.y + edge, screen.end.y - height - edge)

	cascade.custom_minimum_size = Vector2(width, height)

	var popup: HenPopupContainer = gp.show_content(cascade, {
		layout = HenGeneralPopup.Layout.ANCHORED,
		pos = Vector2(x, y),
		lod = 0.0
	})
	_current_popup = popup

	var box: Control = popup.get_node_or_null('%GeneralPopUp')
	if box:
		box.add_theme_stylebox_override('panel', StyleBoxEmpty.new())

	popup.closed.connect(func() -> void:
		_current_popup = null
		if is_instance_valid(_inspector):
			_inspector.active_action_key = ''
			_inspector._update_props.call_deferred()
	, CONNECT_ONE_SHOT)

	cascade._open_level(0, _slot, _inspector)


static func close_current() -> void:
	if _current_popup and is_instance_valid(_current_popup):
		_current_popup.hide_popup()

	_current_popup = null


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	# STOP: a click on the empty area lands here instead of the editor below
	mouse_filter = Control.MOUSE_FILTER_STOP

	_scroll = ScrollContainer.new()
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_scroll)

	_strip = HBoxContainer.new()
	_strip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_strip.add_theme_constant_override('separation', int(PANEL_GAP))
	_scroll.add_child(_strip)

	if _lead_in > 0.0:
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(_lead_in, 0)
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_strip.add_child(spacer)


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return

	var mb: InputEventMouseButton = event

	if mb.pressed and (mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT):
		close_current()


func _open_level(index: int, parent_slot: Dictionary, source_inspector: HenInspector) -> void:
	var ref: Variant = (parent_slot.get('action_store') as Dictionary).get(parent_slot.get('action_key', ''))
	var child: HenSaveAction = HenActionsPanel.inline_child(ref)

	if not child:
		return

	_truncate_from(index)

	var level: Dictionary = _make_panel(index, child, ref, parent_slot)
	_levels.append(level)
	_strip.add_child(level.panel)

	# deferred: a direct rebuild would re-enter while this one still runs
	if is_instance_valid(source_inspector):
		source_inspector.active_action_key = str(parent_slot.get('action_key', ''))
		source_inspector._update_props.call_deferred()

	_scroll_to_newest()


func _scroll_to_newest() -> void:
	# two frames: max_value only settles after the strip resized with the new panel
	await get_tree().process_frame
	await get_tree().process_frame

	if is_instance_valid(_scroll):
		_scroll.scroll_horizontal = int(_scroll.get_h_scroll_bar().max_value)


func _on_panel_chip(index: int, slot: Dictionary, _chip: Control) -> void:
	var ref: Variant = (slot.get('action_store') as Dictionary).get(slot.get('action_key', ''))
	var child: HenSaveAction = HenActionsPanel.inline_child(ref)

	if _levels.size() > index + 1 and _levels[index + 1].child == child:
		_truncate_from(index + 1)
		return

	_open_level(index + 1, slot, _levels[index].inspector)


func _on_panel_inline_changed(index: int) -> void:
	_truncate_from.call_deferred(index + 1)


# only the surviving parent is touched: the popped inspectors are already freeing
func _truncate_from(index: int) -> void:
	index = maxi(index, 0)

	if index >= _levels.size():
		return

	var parent_inspector: HenInspector = _sidebar if index == 0 else _levels[index - 1].inspector

	while _levels.size() > index:
		var level: Dictionary = _levels.pop_back()

		if is_instance_valid(level.panel):
			level.panel.queue_free()

	if is_instance_valid(parent_inspector):
		parent_inspector.active_action_key = ''
		parent_inspector._update_props.call_deferred()


func _make_panel(index: int, child: HenSaveAction, ref: Variant, parent_slot: Dictionary) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_style_panel(panel)

	var margin := MarginContainer.new()
	for side: String in ['left', 'right', 'top', 'bottom']:
		margin.add_theme_constant_override('margin_' + side, 8)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override('separation', 6)
	margin.add_child(vbox)

	vbox.add_child(_make_header(index, child))

	var inspector: HenInspector = load(INSPECTOR_SCENE).instantiate()
	inspector.nested_producer = true
	inspector.hide_phase = true
	inspector.on_action_chip = func(_slot: Dictionary, _chip: Control) -> void:
		_on_panel_chip(index, _slot, _chip)
	inspector.inline_changed.connect(_on_panel_inline_changed.bind(index))
	vbox.add_child(inspector)
	inspector.header_panel.visible = false
	inspector.make_flat()
	inspector.edit(child, '', [])

	var footer: Dictionary = _make_footer(index, child, ref, parent_slot)
	vbox.add_child(footer.node)

	return {
		panel = panel,
		inspector = inspector,
		child = child,
		ref = ref,
		parent_slot = parent_slot,
		ret_label = footer.ret_label,
		out_bt = footer.out_bt
	}


func _make_header(index: int, child: HenSaveAction) -> Control:
	var header := HBoxContainer.new()
	header.add_theme_constant_override('separation', 6)

	var trail := Label.new()
	trail.text = _trail_text(index, child)
	trail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trail.clip_text = true
	trail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	ThemeUtils.apply_font_size(trail, 12)
	trail.add_theme_color_override('font_color', TRAIL_COLOR)
	header.add_child(trail)

	var depth := Label.new()
	depth.text = 'L' + str(index + 1)
	ThemeUtils.apply_font_size(depth, 12)
	depth.add_theme_color_override('font_color', ACCENT)
	header.add_child(depth)

	var close_bt := Button.new()
	close_bt.flat = true
	close_bt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_bt.tooltip_text = 'Close this panel and the ones after it'
	if ResourceLoader.exists(CLOSE_ICON):
		close_bt.icon = load(CLOSE_ICON)
	else:
		close_bt.text = 'X'
	close_bt.pressed.connect(_truncate_from.bind(index))
	header.add_child(close_bt)

	return header


func _make_footer(index: int, child: HenSaveAction, ref: Variant, parent_slot: Dictionary) -> Dictionary:
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override('separation', 6)

	var outputs: Array = _child_outputs(child)
	var ret_label := Label.new()
	ret_label.text = 'returns ' + _return_type(ref, outputs)
	ThemeUtils.apply_font_size(ret_label, 12)
	ret_label.add_theme_color_override('font_color', FOOTER_COLOR)
	footer.add_child(ret_label)

	var out_bt: Button = null

	if outputs.size() > 1:
		out_bt = Button.new()
		out_bt.text = _output_name(ref, outputs)
		out_bt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		out_bt.tooltip_text = 'Which output feeds the slot'
		out_bt.pressed.connect(_open_output_picker.bind(index, out_bt))
		footer.add_child(out_bt)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)

	var to_label := Label.new()
	to_label.text = '-> ' + str((parent_slot.get('param') as HenSaveParam).name)
	ThemeUtils.apply_font_size(to_label, 12)
	to_label.add_theme_color_override('font_color', FOOTER_COLOR)
	footer.add_child(to_label)

	return {node = footer, ret_label = ret_label, out_bt = out_bt}


func _open_output_picker(index: int, anchor: Button) -> void:
	var level: Dictionary = _levels[index]
	var outputs: Array = _child_outputs(level.child)
	var menu: HenDropDownMenu = load(DROPDOWN_SCENE).instantiate()

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(menu, {
		layout = HenGeneralPopup.Layout.ANCHORED,
		pos = anchor.global_position,
		min_size = Vector2(180, 220)
	})

	var list: Array = []
	for output: HenSaveParam in outputs:
		list.append({name = output.name, output_id = str(output.id)})

	menu.mount(list, func(item: Dictionary) -> void:
		if level.ref is Dictionary:
			(level.ref as Dictionary).output = StringName(str(item.output_id))
		level.out_bt.text = _output_name(level.ref, outputs)
		level.ret_label.text = 'returns ' + _return_type(level.ref, outputs)
		(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()
	, 'item_type')


func _trail_text(index: int, child: HenSaveAction) -> String:
	var names: PackedStringArray = []

	for i: int in range(index):
		names.append(HenActionsPanel.display_name(_levels[i].child))

	names.append(HenActionsPanel.display_name(child))

	return ' > '.join(names)


func _child_outputs(child: HenSaveAction) -> Array:
	var macro: HenSaveMacro = HenActionsPanel.find_macro(child.macro_id)

	return macro.outputs if macro else []


func _output_id(ref: Variant, outputs: Array) -> String:
	var id: String = str((ref as Dictionary).get('output', '')) if ref is Dictionary else ''

	if not id.is_empty():
		return id

	return str((outputs[0] as HenSaveParam).id) if not outputs.is_empty() else ''


func _output_name(ref: Variant, outputs: Array) -> String:
	var id: String = _output_id(ref, outputs)

	for output: HenSaveParam in outputs:
		if str(output.id) == id:
			return output.name

	return id


func _return_type(ref: Variant, outputs: Array) -> String:
	var id: String = _output_id(ref, outputs)

	for output: HenSaveParam in outputs:
		if str(output.id) == id:
			return str(output.type)

	return 'Variant'


func _style_panel(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color('#20262f')
	style.set_corner_radius_all(8)
	style.set_content_margin_all(2)
	panel.add_theme_stylebox_override('panel', style)
