@tool
class_name HenStateViewerCard
extends Node2D

# node2d on purpose: a control's own draw commands are culled by its rect, not by
# the commands it emitted

# FULL desenha as rows, COMPACT troca por nome e contagem, NAME deixa so o nome
enum Detail {FULL, COMPACT, NAME}

const LABEL_COLOR: Color = Color(0.9, 0.9, 0.9, 1)
const COMPOUND_BORDER: Color = Color(0.18992361, 0.18994236, 0.23241404, 1)
const COMPOUND_BODY_BG: Color = Color(0.119071566, 0.119075276, 0.1496324, 0.35)
const COMPOUND_HEADER_BG: Color = Color(0.155, 0.155, 0.195, 1.0)
const LEAF_BG: Color = Color(0.20258576, 0.2025904, 0.2280235, 1)
const LEAF_BORDER: Color = Color(0.27, 0.27, 0.31, 1)
const INITIAL_COLOR: Color = Color('#8eef97')
const RUNNING_BORDER: Color = Color('#63ff92')
const RUNNING_SHADOW: Color = Color(0.39, 1.0, 0.57, 0.30)
const CURRENT_BORDER: Color = Color('#e67e22')
const CURRENT_SHADOW: Color = Color(0.90, 0.49, 0.13, 0.28)
const RUN_BORDER_WIDTH: int = 2
const INITIAL_TEXTURE: Texture2D = preload('res://addons/hengo/assets/new_icons/circle-play.svg')
const GRIP_TEXTURE: Texture2D = preload('res://addons/hengo/assets/new_icons/grip-vertical.svg')
const GRIP_COLOR: Color = Color(1, 1, 1, 0.45)

const CARD_CORNER: int = 8
const CARD_PAD: float = 8.0
const HEADER_CORNER: int = 6
const HEADER_PAD_H: float = 8.0
const HEADER_PAD_V: float = 5.0
const HEADER_SEPARATOR_WIDTH: float = 2.0
const COMPOUND_BORDER_WIDTH: int = 3

const TITLE_SIZE: int = 18
const DESC_SIZE: int = 14
const TYPE_ICON: float = 18.0
const INITIAL_ICON: float = 16.0
const LEAF_TITLE_SEP: float = 4.0
const COMPOUND_TITLE_SEP: float = 6.0

const COMPACT_GAP: float = 4.0
const COMPACT_ICON_RATIO: float = 1.6
const CONTENT_WIDTH: float = 320.0
const LIST_SEP: float = 2.0
const ROWS_SEP: float = 3.0

const ROW_CORNER: int = 6
const ROW_PAD_L: float = 4.0
const ROW_PAD_T: float = 4.0
const ROW_PAD_R: float = 6.0
const ROW_PAD_B: float = 4.0
const ROW_SEP: float = 6.0
const ROW_TITLE_SIZE: int = 18
const ROW_ICON: float = 18.0
const GRIP_SIZE: Vector2 = Vector2(10, 14)
const INDENT_STEP: float = 18.0
const ROW_TITLE_COLOR: Color = Color('#dde4ed')

const CHIP_SEP: float = 4.0
const CHIP_CORNER: int = 4
const CHIP_PAD_H: float = 5.0
const CHIP_PAD_V: float = 1.0

const CAPSULE_CORNER: int = 10
const CAPSULE_PAD_H: float = 7.0
const CAPSULE_PAD_V: float = 3.0
const CAPSULE_ICON: float = 17.0

const PHASE_PAD_L: float = 4.0
const PHASE_PAD_T: float = 4.0
const PHASE_PAD_B: float = 1.0
const PHASE_MIN_H: float = 24.0
const PHASE_SEP: float = 6.0
const PHASE_ICON: float = 13.0
const PHASE_TEXT_SIZE: int = 11
const PHASE_ADD: float = 20.0
const PHASE_ICONS: Dictionary = {
	enter = 'arrow-right-to-line',
	update = 'refresh-cw',
	exit = 'arrow-left-from-line'
}

const ADD_BT_SIZE: int = 12
const ADD_BT_ICON: float = 12.0
const ADD_BT_PAD: float = 4.0
const ADD_BT_TEXT: String = 'Add Action'
const LOOP_BT_TEXT: String = '+ Add to loop'
const DIM_TEXT: Color = Color(1, 1, 1, 0.45)

# rounded backgrounds repeat across rows and chips, so they are cached by look
static var _style_cache: Dictionary = {}

var save_data: HenSaveData
var state_id: StringName
var is_compound: bool = false

var _host: Control
var _painter: HenCardPainter = HenCardPainter.new()
var _hits: Array[Dictionary] = []
var _items: Array[Dictionary] = []
var _title: String = ''
var _description: String = ''
var _script_type: String = ''
var _is_initial: bool = false
var _intrinsic: Vector2 = Vector2.ZERO
var _content_size: Vector2 = Vector2.ZERO
var _final_size: Vector2 = Vector2.ZERO
var _v_sep: float = 4.0

# only the innermost target lights up, the same way nested controls stole the hover
var _hover_kind: StringName = &''
var _hover_ref: Variant = null
var _drop_kind: StringName = &''
var _drop_ref: Variant = null
var _drop_before: bool = false
var _highlight: StringName = &''
var _detail: int = Detail.FULL
var _needs_emit: bool = false
var _compact_label: CompactLabel = null
var _title_scale: float = 1.0
# action id -> true, for the rows lit by the debug session
var _running: Dictionary = {}
var _row_ids: Dictionary = {}
var _chip_seq: int = 0


# re-emits so the highlight lands under the text; never call this every frame,
# draw_string reshapes on every redraw while a label kept its buffer
func set_hover(_kind: StringName, _ref: Variant) -> bool:
	if _hover_kind == _kind and _hover_ref == _ref:
		return false

	_hover_kind = _kind
	_hover_ref = _ref

	_emit()

	return true


# &'running' while the debug session sits on this state, &'current' while it is
# the route being edited
func set_highlight(_kind: StringName) -> bool:
	if _highlight == _kind:
		return false

	_highlight = _kind

	_emit()

	return true


# an update action re-arms every frame, so this only re-emits when the set of
# running rows actually changes
func set_running(_ids: Dictionary) -> bool:
	if _running == _ids:
		return false

	_running = _ids.duplicate()

	_emit()

	return true


# the debug trace asks this once per action per frame, so it cannot be a scan
func has_row(_action_id: StringName) -> bool:
	return _row_ids.has(str(_action_id))


func set_drop_hint(_kind: StringName, _ref: Variant, _before: bool) -> bool:
	if _drop_kind == _kind and _drop_ref == _ref and _drop_before == _before:
		return false

	_drop_kind = _kind
	_drop_ref = _ref
	_drop_before = _before

	_emit()

	return true


# a row is only draggable at the top level, the same rule the control rows had
func build_row_preview(_action: HenSaveAction) -> Control:
	for item: Dictionary in _items:
		if item.type != &'row' or item.action != _action:
			continue

		var width: float = _final_size.x - (HEADER_PAD_H if is_compound else CARD_PAD) * 2.0
		var size: Vector2 = Vector2(maxf(width, 1.0), item.height)

		# the row is re-emitted into a throwaway painter, so neither the card's
		# draw list nor its hit map is disturbed
		var kept_painter: HenCardPainter = _painter
		var kept_hits: Array[Dictionary] = _hits
		var kept_hover: StringName = _hover_kind
		var kept_drop: StringName = _drop_kind

		_painter = HenCardPainter.new()
		_painter.font = kept_painter.font
		_painter.font_scale = kept_painter.font_scale
		_hits = []
		_hover_kind = &''
		_drop_kind = &''

		_emit_row(item, Rect2(Vector2.ZERO, size))

		var preview: RowPreview = RowPreview.new()
		preview.setup(_painter, size)

		_painter = kept_painter
		_hits = kept_hits
		_hover_kind = kept_hover
		_drop_kind = kept_drop

		return preview

	return null


# holds the name readable while the cam zooms out, by counter-scaling instead of
# redrawing at a bigger size
func set_title_scale(_factor: float) -> void:
	_title_scale = _factor

	if is_instance_valid(_compact_label) and _compact_label.scale.x != _factor:
		_compact_label.scale = Vector2(_factor, _factor)


class CompactLabel extends Node2D:
	var _painter: HenCardPainter


	# everything centered on the origin, so the parent only sets a position
	func build(_source: HenCardPainter, _title: String, _summary: String, _icon: Texture2D, _icon_color: Color) -> void:
		_painter = HenCardPainter.new()
		_painter.font = _source.font
		_painter.font_scale = _source.font_scale

		var title_size: Vector2 = _painter.measure(_title, TITLE_SIZE)
		var title_h: float = _painter.line_height(TITLE_SIZE)
		# oversized on purpose: the type badge is what reads first while navigating
		var icon_size: float = title_h * COMPACT_ICON_RATIO if _icon else 0.0
		var line_w: float = title_size.x + (icon_size + COMPACT_GAP if _icon else 0.0)
		var line_h: float = maxf(title_h, icon_size)
		var total_h: float = line_h
		var summary_size: Vector2 = Vector2.ZERO

		if not _summary.is_empty():
			summary_size = _painter.measure(_summary, DESC_SIZE)
			total_h += COMPACT_GAP + _painter.line_height(DESC_SIZE)

		var y: float = -total_h * 0.5
		var x: float = -line_w * 0.5

		if _icon:
			_painter.add_texture(
				_icon,
				Rect2(Vector2(x, y + (line_h - icon_size) * 0.5), Vector2(icon_size, icon_size)),
				_icon_color
			)
			x += icon_size + COMPACT_GAP

		_painter.add_text(_title, TITLE_SIZE, Vector2(x, y + (line_h - title_h) * 0.5), LABEL_COLOR)

		if not _summary.is_empty():
			_painter.add_text(
				_summary,
				DESC_SIZE,
				Vector2(-summary_size.x * 0.5, y + line_h + COMPACT_GAP),
				LABEL_COLOR.darkened(0.35)
			)

		queue_redraw()


	func _draw() -> void:
		if _painter:
			_painter.replay(self )


class RowPreview extends Control:
	var _painter: HenCardPainter


	func setup(_source: HenCardPainter, _size: Vector2) -> void:
		_painter = _source
		custom_minimum_size = _size
		size = _size
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		modulate = Color(1, 1, 1, 0.8)


	func _draw() -> void:
		if _painter:
			_painter.replay(self )


func setup(_host_control: Control, _save_data: HenSaveData, _data: Dictionary, _title_text: String, _compound: bool, _initial: bool) -> void:
	_host = _host_control
	save_data = _save_data
	state_id = StringName(str(_data.get('state_id', '')))
	is_compound = _compound
	_title = _title_text
	_description = str(_data.get('description', ''))
	_script_type = str(_data.get('script_type', ''))
	_is_initial = _initial

	_painter.bind(_host)
	_v_sep = float(_host.get_theme_constant(&'separation', &'VBoxContainer'))


# --- measure ---

func compute_size() -> Vector2:
	_items.clear()
	_row_ids.clear()
	# dictionaries compare by value in gdscript, so chips are identified by index
	_chip_seq = 0

	var title_w: float = _measure_title_row()
	var list_w: float = _measure_items()
	var desc_w: float = _painter.measure(_description, DESC_SIZE).x if not _description.is_empty() else 0.0

	var content_w: float = maxf(title_w, maxf(list_w, desc_w))
	var content_h: float = _painter.line_height(TITLE_SIZE)

	if not _description.is_empty():
		content_h += _v_sep + _painter.line_height(DESC_SIZE)

	if not _items.is_empty():
		content_h += _v_sep + _items_height()

	_content_size = Vector2(content_w, content_h)

	var pad: float = CARD_PAD if not is_compound else HEADER_PAD_H
	var pad_v: float = CARD_PAD if not is_compound else HEADER_PAD_V

	_intrinsic = Vector2(content_w + pad * 2.0, content_h + pad_v * 2.0)

	return _intrinsic


func get_intrinsic_size() -> Vector2:
	return _intrinsic


# re-reads the actions and re-emits at the current size; a real re-measure only
# happens on the next layout, so an edit does not shove the popup it is anchored to
func refresh_content() -> void:
	compute_size()

	_emit()


func get_hits() -> Array[Dictionary]:
	return _hits


func _measure_title_row() -> float:
	var width: float = _painter.measure(_title, TITLE_SIZE).x
	var sep: float = COMPOUND_TITLE_SEP if is_compound else LEAF_TITLE_SEP

	if is_compound and not _script_type.is_empty():
		width += TYPE_ICON + sep

	if _is_initial:
		width += INITIAL_ICON + sep

	return width


# the visual order codegen runs in: phase header, then its actions
func _measure_items() -> float:
	if not save_data or state_id.is_empty():
		return 0.0

	var actions: Array = save_data.get_state_actions(state_id)

	if actions.is_empty():
		return 0.0

	var width: float = 0.0
	var groups: Dictionary = HenActionsPanel.group_by_phase(actions)

	for phase: StringName in HenSaveAction.PHASE_ORDER:
		var bucket: Array = groups.get(str(phase), [])

		if bucket.is_empty():
			continue

		width = maxf(width, _add_phase_item(phase, bucket.size()))

		for action: HenSaveAction in bucket:
			width = maxf(width, _add_row_item(action, 0))

	width = maxf(width, _add_button_item(&'list_add', ADD_BT_TEXT, true, 0, null))

	return maxf(width, CONTENT_WIDTH)


func _add_phase_item(_phase: StringName, _count: int) -> float:
	var color: Color = Color(str(HenActionVisuals.PHASE_COLORS.get(str(_phase), HenActionVisuals.FALLBACK_COLOR)))
	var name_text: String = str(_phase).to_upper()
	var count_text: String = str(_count) if _count > 0 else 'empty'
	var text_h: float = _painter.line_height(PHASE_TEXT_SIZE)

	var item: Dictionary = {
		type = &'phase',
		phase = _phase,
		color = color,
		name_text = name_text,
		count_text = count_text,
		icon = HenActionVisuals.icon_texture(str(PHASE_ICONS.get(str(_phase), ''))),
		name_w = _painter.measure(name_text, PHASE_TEXT_SIZE).x,
		count_w = _painter.measure(count_text, PHASE_TEXT_SIZE).x,
		height = maxf(PHASE_MIN_H, PHASE_PAD_T + maxf(maxf(PHASE_ICON, text_h), PHASE_ADD) + PHASE_PAD_B)
	}

	_items.append(item)

	return PHASE_PAD_L * 2.0 + PHASE_ICON + PHASE_SEP + item.name_w + PHASE_SEP + item.count_w + PHASE_SEP + PHASE_ADD


func _add_row_item(_action: HenSaveAction, _depth: int) -> float:
	var macro: HenSaveMacro = HenActionsPanel.find_macro(_action.macro_id)
	var accent: String = macro.color if macro and not macro.color.is_empty() else HenActionVisuals.FALLBACK_COLOR
	var title: String = macro.name if macro else _action.name

	var parts: Array = _measure_parts(HenActionsPanel.value_parts(_action, save_data), _depth)
	var title_size: Vector2 = _painter.measure(title, ROW_TITLE_SIZE)

	var inner_w: float = GRIP_SIZE.x + ROW_SEP + ROW_ICON + ROW_SEP + title_size.x
	var inner_h: float = maxf(maxf(GRIP_SIZE.y, ROW_ICON), _painter.line_height(ROW_TITLE_SIZE))

	for part: Dictionary in parts:
		inner_w += ROW_SEP + part.width
		inner_h = maxf(inner_h, part.height)

	var item: Dictionary = {
		type = &'row',
		action = _action,
		depth = _depth,
		title = title,
		icon = HenActionVisuals.icon_texture(macro.icon if macro else ''),
		accent = Color(accent),
		title_w = title_size.x,
		parts = parts,
		inner_h = inner_h,
		height = ROW_PAD_T + inner_h + ROW_PAD_B
	}

	_items.append(item)
	_row_ids[str(_action.id)] = true

	var width: float = ROW_PAD_L + _depth * INDENT_STEP + inner_w + ROW_PAD_R

	if macro and macro.has_body:
		for child: HenSaveAction in _action.body_actions:
			width = maxf(width, _add_row_item(child, _depth + 1))

		width = maxf(width, _add_button_item(&'loop_add', LOOP_BT_TEXT, false, _depth + 1, _action))

	return width


# one entry per value chip, in reading order; a slot fed by another action carries
# a nested capsule instead of a plain value
func _measure_parts(_parts: Array, _depth: int) -> Array:
	var out: Array = []

	for part: Dictionary in _parts:
		var capsule: Dictionary = part.get('capsule', {})

		if capsule.is_empty():
			out.append(_measure_chip(part))
			continue

		var label: String = str(part.get('label', ''))

		if not label.is_empty():
			out.append({
				kind = &'slot_label',
				text = label,
				width = _painter.measure(label, HenActionVisuals.LABEL_SIZE).x,
				height = _painter.line_height(HenActionVisuals.LABEL_SIZE)
			})

		out.append(_measure_capsule(capsule, _depth + 1))

	return out


func _measure_chip(_part: Dictionary) -> Dictionary:
	var name_text: String = str(_part.get('label', ''))
	var value_text: String = str(_part.get('value', ''))
	var color: Color = Color(str(HenActionVisuals.KINDS.get(str(_part.get('kind', 'literal')), HenActionVisuals.KINDS.literal)))

	var name_w: float = _painter.measure(name_text, HenActionVisuals.LABEL_SIZE).x if not name_text.is_empty() else 0.0
	var value_w: float = _painter.measure(value_text, HenActionVisuals.VALUE_SIZE).x
	var box_w: float = value_w + CHIP_PAD_H * 2.0
	var box_h: float = _painter.line_height(HenActionVisuals.VALUE_SIZE) + CHIP_PAD_V * 2.0
	var index: int = _chip_seq

	_chip_seq += 1

	return {
		kind = &'chip',
		part = _part,
		index = index,
		name_text = name_text,
		value_text = value_text,
		color = color,
		name_w = name_w,
		box_w = box_w,
		box_h = box_h,
		width = box_w + (name_w + CHIP_SEP if not name_text.is_empty() else 0.0),
		height = maxf(box_h, _painter.line_height(HenActionVisuals.LABEL_SIZE))
	}


func _measure_capsule(_capsule: Dictionary, _depth: int) -> Dictionary:
	var color: String = str(_capsule.get('color', ''))
	var accent: Color = Color(color) if not color.is_empty() else Color(HenActionVisuals.FALLBACK_COLOR)
	var title: String = str(_capsule.get('title', ''))
	var title_w: float = _painter.measure(title, HenActionVisuals.CAPSULE_TITLE_SIZE).x

	var parts: Array = _measure_parts(_capsule.get('parts', []), _depth)

	var inner_w: float = CAPSULE_ICON + ROW_SEP + title_w
	var inner_h: float = maxf(CAPSULE_ICON, _painter.line_height(HenActionVisuals.CAPSULE_TITLE_SIZE))

	for part: Dictionary in parts:
		inner_w += ROW_SEP + part.width
		inner_h = maxf(inner_h, part.height)

	return {
		kind = &'capsule',
		action = _capsule.get('action'),
		title = title,
		icon = HenActionVisuals.icon_texture(str(_capsule.get('icon', ''))),
		accent = accent,
		depth = _depth,
		title_w = title_w,
		parts = parts,
		inner_h = inner_h,
		width = CAPSULE_PAD_H * 2.0 + inner_w,
		height = CAPSULE_PAD_V * 2.0 + inner_h
	}


func _add_button_item(_type: StringName, _text: String, _has_icon: bool, _depth: int, _loop: HenSaveAction) -> float:
	var text_size: Vector2 = _painter.measure(_text, ADD_BT_SIZE)
	var icon_w: float = (ADD_BT_ICON + ADD_BT_PAD) if _has_icon else 0.0

	_items.append({
		type = _type,
		text = _text,
		has_icon = _has_icon,
		depth = _depth,
		loop = _loop,
		text_w = text_size.x,
		height = maxf(_painter.line_height(ADD_BT_SIZE), ADD_BT_ICON) + ADD_BT_PAD * 2.0
	})

	return ROW_PAD_L + _depth * INDENT_STEP + icon_w + text_size.x + ROW_PAD_R


# the list keeps its rows tight and only breathes before the trailing add button
func _items_height() -> float:
	var total: float = 0.0

	for i: int in range(_items.size()):
		var item: Dictionary = _items[i]

		if i > 0:
			total += LIST_SEP if item.type == &'list_add' else ROWS_SEP

		total += item.height

	return total


# --- emit ---

# the layout engine may widen a card past its intrinsic size, so the draw list is
# only built once the final rect is known
func apply_size(_size: Vector2) -> void:
	_final_size = _size
	_emit()


# offscreen cards keep their measured size but drop their draw list until shown
func set_culled(_culled: bool) -> void:
	if visible != _culled:
		return

	visible = not _culled

	if visible and _needs_emit:
		_emit()


# rows are unreadable long before the minimum zoom, so they stop being drawn and
# the card keeps its footprint, which is what stops the layout jumping on zoom
func set_detail(_level: int) -> bool:
	if _detail == _level:
		return false

	_detail = _level
	_emit()

	return true


func _emit() -> void:
	if _final_size == Vector2.ZERO:
		return

	if not visible:
		_needs_emit = true
		return

	_needs_emit = false
	_painter.clear()
	_hits.clear()

	var rect: Rect2 = Rect2(Vector2.ZERO, _final_size)

	if is_compound:
		_emit_compound(rect)
	else:
		_emit_leaf(rect)

	queue_redraw()


func _emit_leaf(_rect: Rect2) -> void:
	_painter.add_style(_chrome_style({
		bg = LEAF_BG,
		corner = CARD_CORNER,
		border = LEAF_BORDER,
		border_w = 1,
		shadow = 6,
		shadow_alpha = 0.35
	}, 2), _rect)

	# the leaf vbox centers, so a card widened past its content keeps it in the middle
	var top: float = maxf(CARD_PAD, (_rect.size.y - _content_size.y) * 0.5)

	_emit_content(Rect2(
		Vector2(CARD_PAD, top),
		Vector2(_rect.size.x - CARD_PAD * 2.0, _content_size.y)
	), true)


func _emit_compound(_rect: Rect2) -> void:
	_painter.add_style(_chrome_style({
		bg = COMPOUND_BODY_BG,
		corner = CARD_CORNER,
		border = COMPOUND_BORDER,
		border_w = COMPOUND_BORDER_WIDTH,
		shadow = 8,
		shadow_alpha = 0.25
	}, COMPOUND_BORDER_WIDTH), _rect)

	var header_h: float = _content_size.y + HEADER_PAD_V * 2.0
	var header_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(_rect.size.x, header_h))

	_painter.add_style(_flat({
		bg = COMPOUND_HEADER_BG,
		corner_top = HEADER_CORNER,
		border_bottom = COMPOUND_BORDER.lightened(0.2),
		border_bottom_w = int(HEADER_SEPARATOR_WIDTH)
	}), header_rect)

	_emit_content(Rect2(
		Vector2(HEADER_PAD_H, HEADER_PAD_V),
		Vector2(_rect.size.x - HEADER_PAD_H * 2.0, _content_size.y)
	), false)


func _emit_content(_rect: Rect2, _centered: bool) -> void:
	if _detail != Detail.FULL:
		_build_compact_label()
		return

	if is_instance_valid(_compact_label):
		_compact_label.visible = false

	var y: float = _rect.position.y

	y = _emit_title_row(_rect, y, _centered)

	if not _description.is_empty():
		y += _v_sep
		var size: Vector2 = _painter.measure(_description, DESC_SIZE)
		var x: float = _rect.position.x + (_rect.size.x - size.x) * 0.5 if _centered else _rect.position.x
		_painter.add_text(_description, DESC_SIZE, Vector2(x, y), LABEL_COLOR.darkened(0.3))
		y += _painter.line_height(DESC_SIZE)

	if not _items.is_empty():
		y += _v_sep
		_emit_items(Rect2(Vector2(_rect.position.x, y), Vector2(_rect.size.x, 0)))


# the compact name lives in its own node so the zoom counter-scale is a transform,
# never a redraw: draw_string would reshape the text on every zoom step
func _build_compact_label() -> void:
	if _compact_label == null:
		_compact_label = CompactLabel.new()
		add_child(_compact_label)

	var count: int = _row_ids.size()
	var summary: String = ''

	# at NAME the count is just more text to read in a field of names
	if _detail == Detail.COMPACT and count > 0:
		summary = '%d action%s' % [count, '' if count == 1 else 's']

	var icon: Texture2D = null
	var icon_color: Color = Color.WHITE

	if is_compound and not _script_type.is_empty():
		icon = HenUtils.get_icon_texture(StringName(_script_type))
		icon_color = HenUtils.get_type_parent_color(StringName(_script_type), 1.0, Color.WHITE).lightened(0.25)

	_compact_label.build(_painter, _title, summary, icon, icon_color)

	# a machine is mostly its own states, so its name belongs on the header band and
	# not in the middle of them
	var anchor: Vector2 = _final_size * 0.5

	if is_compound:
		anchor.y = (_content_size.y + HEADER_PAD_V * 2.0) * 0.5

	_compact_label.position = anchor
	_compact_label.scale = Vector2(_title_scale, _title_scale)
	_compact_label.visible = true


func _emit_title_row(_rect: Rect2, _y: float, _centered: bool) -> float:
	var height: float = _painter.line_height(TITLE_SIZE)
	var sep: float = COMPOUND_TITLE_SEP if is_compound else LEAF_TITLE_SEP
	var width: float = _measure_title_row()
	var x: float = _rect.position.x + (_rect.size.x - width) * 0.5 if _centered else _rect.position.x

	if is_compound and not _script_type.is_empty():
		_painter.add_texture(
			HenUtils.get_icon_texture(StringName(_script_type)),
			Rect2(Vector2(x, _y + (height - TYPE_ICON) * 0.5), Vector2(TYPE_ICON, TYPE_ICON)),
			HenUtils.get_type_parent_color(StringName(_script_type), 1.0, Color.WHITE).lightened(0.25)
		)
		x += TYPE_ICON + sep

	if _is_initial:
		_painter.add_texture(
			INITIAL_TEXTURE,
			Rect2(Vector2(x, _y + (height - INITIAL_ICON) * 0.5), Vector2(INITIAL_ICON, INITIAL_ICON)),
			INITIAL_COLOR
		)
		x += INITIAL_ICON + sep

	_painter.add_text(_title, TITLE_SIZE, Vector2(x, _y), LABEL_COLOR)

	return _y + height


func _emit_items(_rect: Rect2) -> void:
	var y: float = _rect.position.y

	for i: int in range(_items.size()):
		var item: Dictionary = _items[i]

		if i > 0:
			y += LIST_SEP if item.type == &'list_add' else ROWS_SEP

		var item_rect: Rect2 = Rect2(Vector2(_rect.position.x, y), Vector2(_rect.size.x, item.height))

		match item.type:
			&'phase':
				_emit_phase(item, item_rect)
			&'row':
				_emit_row(item, item_rect)
			_:
				_emit_button(item, item_rect)

		y += item.height


func _emit_phase(_item: Dictionary, _rect: Rect2) -> void:
	var faded: bool = _item.count_text == 'empty'
	var text_h: float = _painter.line_height(PHASE_TEXT_SIZE)
	var inner_y: float = _rect.position.y + PHASE_PAD_T
	var x: float = _rect.position.x + PHASE_PAD_L
	var center: float = inner_y + (maxf(maxf(PHASE_ICON, text_h), PHASE_ADD) - PHASE_ICON) * 0.5

	_painter.add_texture(
		_item.icon,
		Rect2(Vector2(x, center), Vector2(PHASE_ICON, PHASE_ICON)),
		Color(_item.color, 0.4 if faded else 0.85)
	)
	x += PHASE_ICON + PHASE_SEP

	var text_y: float = inner_y + (maxf(maxf(PHASE_ICON, text_h), PHASE_ADD) - text_h) * 0.5

	_painter.add_text(_item.name_text, PHASE_TEXT_SIZE, Vector2(x, text_y), Color(_item.color, 0.4 if faded else 0.75))
	x += _item.name_w + PHASE_SEP

	_painter.add_text(_item.count_text, PHASE_TEXT_SIZE, Vector2(x, text_y), Color(1, 1, 1, 0.35))

	var add_rect: Rect2 = Rect2(
		Vector2(_rect.position.x + _rect.size.x - PHASE_PAD_L - PHASE_ADD, inner_y),
		Vector2(PHASE_ADD, PHASE_ADD)
	)

	_painter.add_texture(
		HenActionVisuals.icon_texture('plus'),
		Rect2(add_rect.position + Vector2((PHASE_ADD - ADD_BT_ICON) * 0.5, (PHASE_ADD - ADD_BT_ICON) * 0.5), Vector2(ADD_BT_ICON, ADD_BT_ICON)),
		DIM_TEXT
	)

	if _drop_kind == &'phase' and _drop_ref == _item.phase:
		var y: float = _rect.position.y + _rect.size.y - 1.0
		_painter.add_line(Vector2(_rect.position.x, y), Vector2(_rect.position.x + _rect.size.x, y), _item.color, 2.0)

	# the button is inside the header, so it has to resolve first
	_hit(add_rect, &'phase_add', {phase = _item.phase})
	_hit(_rect, &'phase', {phase = _item.phase})


func _emit_row(_item: Dictionary, _rect: Rect2) -> void:
	var hovered: bool = _hover_kind == &'row' and _hover_ref == _item.action

	if _running.has(str((_item.action as HenSaveAction).id)):
		_painter.add_style(_flat({
			bg = Color(RUNNING_BORDER, 0.18),
			corner = ROW_CORNER,
			border = RUNNING_BORDER,
			border_w = RUN_BORDER_WIDTH
		}), _rect)
	else:
		_painter.add_style(_flat({bg = Color(_item.accent, 0.17 if hovered else 0.1), corner = ROW_CORNER}), _rect)

	var inner_y: float = _rect.position.y + ROW_PAD_T
	var x: float = _rect.position.x + ROW_PAD_L + _item.depth * INDENT_STEP

	if hovered:
		_painter.add_texture(
			GRIP_TEXTURE,
			Rect2(Vector2(x, inner_y + (_item.inner_h - GRIP_SIZE.y) * 0.5), GRIP_SIZE),
			GRIP_COLOR
		)

	x += GRIP_SIZE.x + ROW_SEP

	_painter.add_texture(
		_item.icon,
		Rect2(Vector2(x, inner_y + (_item.inner_h - ROW_ICON) * 0.5), Vector2(ROW_ICON, ROW_ICON)),
		_item.accent
	)
	x += ROW_ICON + ROW_SEP

	var title_h: float = _painter.line_height(ROW_TITLE_SIZE)
	_painter.add_text(_item.title, ROW_TITLE_SIZE, Vector2(x, inner_y + (_item.inner_h - title_h) * 0.5), ROW_TITLE_COLOR)
	x += _item.title_w

	x = _emit_parts(_item.parts, x, inner_y, _item.inner_h)

	if _drop_kind == &'row' and _drop_ref == _item.action:
		var y: float = _rect.position.y + (1.0 if _drop_before else _rect.size.y - 1.0)
		_painter.add_line(Vector2(_rect.position.x, y), Vector2(_rect.position.x + _rect.size.x, y), _item.accent, 2.0)

	_hit(_rect, &'row', {action = _item.action, depth = _item.depth})


func _emit_parts(_parts: Array, _x: float, _y: float, _inner_h: float) -> float:
	var x: float = _x

	for part: Dictionary in _parts:
		x += ROW_SEP

		match part.kind:
			&'slot_label':
				_painter.add_text(
					part.text,
					HenActionVisuals.LABEL_SIZE,
					Vector2(x, _y + (_inner_h - part.height) * 0.5),
					HenActionVisuals.SLOT_LABEL_COLOR
				)
			&'chip':
				_emit_chip(part, x, _y, _inner_h)
			&'capsule':
				_emit_capsule(part, x, _y, _inner_h)

		x += part.width

	return x


func _emit_chip(_part: Dictionary, _x: float, _y: float, _inner_h: float) -> void:
	var x: float = _x

	if not _part.name_text.is_empty():
		var name_h: float = _painter.line_height(HenActionVisuals.LABEL_SIZE)
		_painter.add_text(
			_part.name_text,
			HenActionVisuals.LABEL_SIZE,
			Vector2(x, _y + (_inner_h - name_h) * 0.5),
			HenActionVisuals.NAME_COLOR
		)
		x += _part.name_w + CHIP_SEP

	var box: Rect2 = Rect2(
		Vector2(x, _y + (_inner_h - _part.box_h) * 0.5),
		Vector2(_part.box_w, _part.box_h)
	)

	if _hover_kind == &'chip' and _hover_ref == _part.index:
		_painter.add_style(_flat({bg = Color(_part.color, 0.13), corner = CHIP_CORNER}), box)

	_painter.add_text(
		_part.value_text,
		HenActionVisuals.VALUE_SIZE,
		box.position + Vector2(CHIP_PAD_H, CHIP_PAD_V),
		_part.color
	)

	_hit(box, &'chip', {part = _part.part, index = _part.index})


func _emit_capsule(_part: Dictionary, _x: float, _y: float, _inner_h: float) -> void:
	var rect: Rect2 = Rect2(
		Vector2(_x, _y + (_inner_h - _part.height) * 0.5),
		Vector2(_part.width, _part.height)
	)

	_painter.add_style(_flat({
		bg = HenActionVisuals.CAPSULE_BASE_BG.lerp(_part.accent, HenActionVisuals.CAPSULE_TINT).darkened(HenActionVisuals.CAPSULE_DEPTH_DARKEN * _part.depth),
		corner = CAPSULE_CORNER
	}), rect)

	var inner_y: float = rect.position.y + CAPSULE_PAD_V
	var x: float = rect.position.x + CAPSULE_PAD_H

	_painter.add_texture(
		_part.icon,
		Rect2(Vector2(x, inner_y + (_part.inner_h - CAPSULE_ICON) * 0.5), Vector2(CAPSULE_ICON, CAPSULE_ICON)),
		_part.accent
	)
	x += CAPSULE_ICON + ROW_SEP

	var title_h: float = _painter.line_height(HenActionVisuals.CAPSULE_TITLE_SIZE)
	_painter.add_text(
		_part.title,
		HenActionVisuals.CAPSULE_TITLE_SIZE,
		Vector2(x, inner_y + (_part.inner_h - title_h) * 0.5),
		HenActionVisuals.TITLE_COLOR
	)
	x += _part.title_w

	_emit_parts(_part.parts, x, inner_y, _part.inner_h)

	_hit(rect, &'capsule', {action = _part.action})


func _emit_button(_item: Dictionary, _rect: Rect2) -> void:
	var x: float = _rect.position.x + ROW_PAD_L + _item.depth * INDENT_STEP
	var text_h: float = _painter.line_height(ADD_BT_SIZE)
	var center_y: float = _rect.position.y + (_rect.size.y - text_h) * 0.5

	if _item.has_icon:
		_painter.add_texture(
			HenActionVisuals.icon_texture('plus'),
			Rect2(Vector2(x, _rect.position.y + (_rect.size.y - ADD_BT_ICON) * 0.5), Vector2(ADD_BT_ICON, ADD_BT_ICON)),
			DIM_TEXT
		)
		x += ADD_BT_ICON + ADD_BT_PAD

	_painter.add_text(_item.text, ADD_BT_SIZE, Vector2(x, center_y), DIM_TEXT)

	_hit(
		Rect2(_rect.position, Vector2(x + _item.text_w - _rect.position.x, _rect.size.y)),
		_item.type,
		{loop = _item.loop}
	)


func _hit(_rect: Rect2, _kind: StringName, _data: Dictionary) -> void:
	_data.rect = _rect
	_data.kind = _kind
	_hits.append(_data)


# the resting chrome, or the debug and route colors painted over its border
func _chrome_style(_spec: Dictionary, _width: int) -> StyleBoxFlat:
	match _highlight:
		&'running':
			_spec.border = RUNNING_BORDER
			_spec.border_w = _width
			_spec.shadow = 10
			_spec.shadow_color = RUNNING_SHADOW
			_spec.shadow_offset = Vector2.ZERO
		&'current':
			_spec.border = CURRENT_BORDER
			_spec.border_w = _width
			_spec.shadow = 10
			_spec.shadow_color = CURRENT_SHADOW
			_spec.shadow_offset = Vector2.ZERO

	return _flat(_spec)


# a look is reused across every row and chip that shares it
func _flat(_spec: Dictionary) -> StyleBoxFlat:
	# packed exactly: Color.to_string() rounds, so near accents would share a box
	var key: String = '%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%s' % [
		(_spec.get('bg', Color.TRANSPARENT) as Color).to_rgba32(),
		int(_spec.get('corner', -1)),
		int(_spec.get('corner_top', -1)),
		(_spec.get('border', Color.TRANSPARENT) as Color).to_rgba32(),
		int(_spec.get('border_w', 0)),
		(_spec.get('border_bottom', Color.TRANSPARENT) as Color).to_rgba32(),
		int(_spec.get('border_bottom_w', 0)),
		int(_spec.get('shadow', 0)),
		roundi(float(_spec.get('shadow_alpha', 0.0)) * 255.0),
		(_spec.get('shadow_color', Color.TRANSPARENT) as Color).to_rgba32(),
		_spec.get('shadow_offset', Vector2.ZERO)
	]

	if _style_cache.has(key):
		return _style_cache[key]

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = _spec.get('bg', Color.TRANSPARENT)

	if _spec.has('corner'):
		style.set_corner_radius_all(int(_spec.corner))

	if _spec.has('corner_top'):
		style.corner_radius_top_left = int(_spec.corner_top)
		style.corner_radius_top_right = int(_spec.corner_top)

	if _spec.has('border'):
		style.border_color = _spec.border
		style.set_border_width_all(int(_spec.get('border_w', 1)))

	if _spec.has('border_bottom'):
		style.border_color = _spec.border_bottom
		style.border_width_bottom = int(_spec.get('border_bottom_w', 1))

	if _spec.has('shadow'):
		style.shadow_size = int(_spec.shadow)
		style.shadow_color = _spec.get('shadow_color', Color(0.0, 0.0, 0.0, float(_spec.get('shadow_alpha', 0.3))))
		style.shadow_offset = _spec.get('shadow_offset', Vector2(0, 2))

	_style_cache[key] = style

	return style


func _draw() -> void:
	_painter.replay(self)
