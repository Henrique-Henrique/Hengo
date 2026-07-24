@tool
class_name HenActionRow extends PanelContainer

const VALUE_SCENE = preload('res://addons/hengo/scenes/action_value.tscn')
const SEPARATOR_COLOR: Color = Color('#454e5c')
const ICON_EXPANDED = preload('res://addons/hengo/assets/new_icons/chevron-down.svg')
const ICON_COLLAPSED = preload('res://addons/hengo/assets/new_icons/chevron-right.svg')

const ICON_DIR: String = 'res://addons/hengo/assets/new_icons/'
const FALLBACK_ICON: String = 'square-function'
const FALLBACK_COLOR: String = '#7c93ff'

# colors the phase section header; the row accent is the action's category
const PHASE_COLORS = {
	enter = '#63d98a',
	update = '#7c93ff',
	physics = '#f2b134',
	exit = '#e08b7f'
}

signal row_pressed(meta: Variant, mouse_button_index: int)
signal collapse_toggled(meta: Variant, collapsed: bool)
signal action_dropped(action: HenSaveAction, target: HenSaveAction, before: bool)

var meta: Variant
# a drag preview copy renders only: no input, no signals
var is_preview: bool = false

var _accent: Color = Color(FALLBACK_COLOR)
var _collapsed: bool = false
var _has_values: bool = false
# bbcode doc shown on hover: bold name, description, then the value summary
var _tooltip: String = ''
var _pressed_button: int = 0
var _drop_before: bool = false
var _drop_hint: bool = false
# a nested (loop body) row is not draggable yet, and drops on it are refused
var _draggable: bool = true


func _ready() -> void:
	if is_preview:
		return

	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	_collapse_bt().pressed.connect(_on_collapse_pressed)


# data carries title/icon/color/meta; parts are {kind, label, value} dicts.
# indent shifts a loop-body row right; draggable off disables drag on it
func setup(data: Dictionary, parts: Array, collapsed: bool = false) -> void:
	meta = data.get('meta')
	_draggable = bool(data.get('draggable', true))

	# a nested row is pushed right so the loop grouping reads at a glance
	get_node('Margin').add_theme_constant_override('margin_left', 4 + int(data.get('indent', 0)) * 18)

	_accent = Color(str(data.get('color', '')) if not str(data.get('color', '')).is_empty() else FALLBACK_COLOR)

	_tooltip = _build_tooltip(str(data.get('doc', '')), str(data.get('values', '')))

	var icon_rect: TextureRect = get_node('Margin/Body/Header/Icon')
	icon_rect.texture = icon_texture(str(data.get('icon', '')))
	icon_rect.modulate = _accent

	# no font_size override on the title: it inherits the theme default, like every other list row
	var title_label: Label = get_node('Margin/Body/Header/Title')
	title_label.text = str(data.get('title', ''))
	title_label.add_theme_color_override('font_color', Color('#dde4ed'))

	var values: HFlowContainer = get_node('Margin/Body/ValuesMargin/Values')
	for child: Node in values.get_children():
		values.remove_child(child)
		child.queue_free()

	for part: Dictionary in parts:
		if values.get_child_count() > 0:
			values.add_child(_separator())

		var value: HenActionValue = VALUE_SCENE.instantiate()
		values.add_child(value)
		value.setup(part.get('kind', &'literal'), str(part.get('label', '')), str(part.get('value', '')))

	_has_values = not parts.is_empty()

	# nothing to fold on an action without inputs: keep the slot, drop the affordance
	var collapse_bt: Button = _collapse_bt()
	collapse_bt.disabled = not _has_values
	collapse_bt.modulate = Color(1, 1, 1, 1.0 if _has_values else 0.0)

	set_collapsed(collapsed)
	_set_hovered(false)


func set_collapsed(collapsed: bool) -> void:
	_collapsed = collapsed
	_collapse_bt().icon = ICON_COLLAPSED if collapsed else ICON_EXPANDED
	get_node('Margin/Body/ValuesMargin').visible = _has_values and not collapsed


func _collapse_bt() -> Button:
	return get_node('Margin/Body/Header/CollapseBt')


func _grip() -> TextureRect:
	return get_node('Margin/Body/Header/Grip')


func _on_collapse_pressed() -> void:
	set_collapsed(not _collapsed)
	collapse_toggled.emit(meta, _collapsed)


func _separator() -> Label:
	var label := Label.new()
	label.text = '|'
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ThemeUtils.apply_font_size(label, 14)
	label.add_theme_color_override('font_color', SEPARATOR_COLOR)
	return label


# drives the hover style and the doc tooltip together
func _on_hover(hovered: bool) -> void:
	_set_hovered(hovered)

	var global: HenGlobal = Engine.get_singleton(&'Global')
	if hovered and not _tooltip.is_empty():
		global.TOOLTIP.go_to(get_global_mouse_position() + Vector2(16, 16), _tooltip)
	else:
		global.TOOLTIP.close()


# the macro's rich doc, followed by a dim line with the action's current values
func _build_tooltip(doc: String, values: String) -> String:
	var content: String = doc
	if not values.is_empty():
		content += ('\n\n' if not doc.is_empty() else '') + '[color=#5f6a7a]Current: ' + values + '[/color]'
	return content


# the background carries the category color, faint enough to stay readable
func _set_hovered(hovered: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(_accent, 0.17 if hovered else 0.1)
	style.set_corner_radius_all(6)
	add_theme_stylebox_override('panel', style)

	_grip().modulate = Color(1, 1, 1, 0.45 if hovered else 0.0)


# icon name from assets/new_icons, falling back when the macro declares none
static func icon_texture(icon_name: String) -> Texture2D:
	var path: String = ICON_DIR + (icon_name if not icon_name.is_empty() else FALLBACK_ICON) + '.svg'
	return load(path) if ResourceLoader.exists(path) else load(ICON_DIR + FALLBACK_ICON + '.svg')


# a ghost of the row itself follows the cursor while dragging
func _get_drag_data(_pos: Vector2) -> Variant:
	# reorder inside a loop / across levels isn't handled yet, so nested rows don't drag
	if not _draggable or not meta is HenSaveAction:
		return null

	var preview: HenActionRow = duplicate()
	preview.is_preview = true
	preview.custom_minimum_size = size
	preview.modulate = Color(1, 1, 1, 0.8)
	# the preview sits under the cursor: without this it wins the hit test and no row gets the drop
	_ignore_mouse(preview)
	set_drag_preview(preview)

	return {type = &'hengo_action', action = meta}


static func _ignore_mouse(_node: Node) -> void:
	if _node is Control:
		(_node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

	for child: Node in _node.get_children():
		_ignore_mouse(child)


func _can_drop_data(_pos: Vector2, _data: Variant) -> bool:
	var action: HenSaveAction = HenActionsPanel.dragged_action(_data)

	# a nested row neither drags nor accepts a drop while cross-level reorder is out
	if not _draggable or not action or action == meta or not meta is HenSaveAction:
		return false

	if not HenActionsPanel.can_use_phase(action, (meta as HenSaveAction).phase):
		return false

	_set_drop_hint(true, _pos.y < size.y * 0.5)
	return true


func _drop_data(_pos: Vector2, _data: Variant) -> void:
	var before: bool = _drop_before
	_set_drop_hint(false, before)
	action_dropped.emit(HenActionsPanel.dragged_action(_data), meta as HenSaveAction, before)


func _notification(_what: int) -> void:
	if _what == NOTIFICATION_DRAG_END or _what == NOTIFICATION_MOUSE_EXIT:
		_set_drop_hint(false, _drop_before)


func _set_drop_hint(_on: bool, _before: bool) -> void:
	if _drop_hint == _on and _drop_before == _before:
		return

	_drop_hint = _on
	_drop_before = _before
	queue_redraw()


func _draw() -> void:
	if not _drop_hint:
		return

	var y: float = 1.0 if _drop_before else size.y - 1.0
	draw_line(Vector2(0, y), Vector2(size.x, y), _accent, 2.0)


# opens on release so the press can start a drag instead of the anchored popup
func _on_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return

	var mb := event as InputEventMouseButton
	var collapse_bt: Button = _collapse_bt()

	if not collapse_bt.disabled and collapse_bt.get_global_rect().has_point(mb.global_position):
		return

	if mb.button_index != MOUSE_BUTTON_LEFT and mb.button_index != MOUSE_BUTTON_RIGHT:
		return

	if mb.pressed:
		_pressed_button = mb.button_index
		accept_event()
		return

	if _pressed_button == mb.button_index:
		_pressed_button = 0

		if not get_viewport().gui_is_dragging():
			row_pressed.emit(meta, mb.button_index)

		accept_event()
