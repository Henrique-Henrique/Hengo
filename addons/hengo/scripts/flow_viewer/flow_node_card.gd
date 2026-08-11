@tool
class_name HenFlowNodeCard
extends Node2D

# one drawn node of the flow graph, laid out like the cnode it stands for: icon
# and title over a rule, the slots in the middle, the flow outs as cells along the
# bottom. same split the state card uses: compute_size is analytic and never
# touches a control, apply_size emits the draw list

# FULL draws the slots, COMPACT keeps the icon and the name
enum Detail {FULL, COMPACT}

const BASE_BG: Color = Color('#12151b')
const BODY_BG: Color = Color(0, 0, 0, 0.22)
# how far each surface travels from the neutral card toward the action's colour
const BG_TINT: float = 0.17
const BORDER_TINT: float = 0.70
const RULE_TINT: float = 0.44
const TITLE_MIX: float = 0.82
const LABEL_MIX: float = 0.62
const LABEL_ALPHA: float = 0.74
const COMPACT_ICON_RATIO: float = 1.5
const COMPACT_GAP: float = 7.0
# lifts the card off the frame it sits in, at the cost of one stylebox parameter
const SHADOW_SIZE: int = 7
const SHADOW_COLOR: Color = Color(0, 0, 0, 0.42)
const HOVER_ALPHA: float = 0.20
# the debug green the whole plugin already uses for a running node
const RUN_COLOR: Color = HenActionVisuals.RUN_COLOR
const RUN_SHADOW: Color = Color(0.39, 1.0, 0.57, 0.30)
const RUN_BORDER_WIDTH: int = 2
const RUN_SHADOW_SIZE: int = 10

const CORNER: int = 8
const PAD: float = 11.0
const HEADER_PAD_V: float = 7.0
const ICON: float = 21.0
const ICON_CORNER: int = 5
const ICON_GLYPH: float = 14.0
const ICON_GAP: float = 8.0
const TITLE_SIZE: int = 16
const LABEL_SIZE: int = 14
const FLOW_SIZE: int = 14
const SLOT_DOT: float = 13.0
const SLOT_GAP: float = 9.0
const ROW_GAP: float = 9.0
const COLUMN_GAP: float = 26.0
const FLOW_PAD_H: float = 12.0
const FLOW_PAD_V: float = 7.0
const SEPARATOR_WIDTH: float = 2.0
const CHIP_CORNER: int = 4
const CHIP_PAD_H: float = 6.0
const MIN_WIDTH: float = 150.0
const MIN_FLOW_CELL: float = 62.0
const BODY_PAD: float = HenFlowFormatter.BODY_PAD

static var _style_cache: Dictionary = {}

var node: HenFlowGraphTypes.FlowNode

var _host: Control
var _painter: HenCardPainter = HenCardPainter.new()
var _hits: Array[Dictionary] = []
var _rows: Array[Dictionary] = []
var _flow_outs: Array[HenFlowGraphTypes.FlowPin] = []
var _header_h: float = 0.0
var _rows_h: float = 0.0
var _flow_h: float = 0.0
var _base_size: Vector2 = Vector2.ZERO
var _final_size: Vector2 = Vector2.ZERO
var _detail: int = Detail.FULL
var _title_scale: float = 1.0
var _compact_label: CompactLabel = null
var _hover_kind: StringName = &''
var _hover_ref: Variant = null
var _chip_seq: int = 0
var _running: bool = false


func setup(_host_control: Control, _node: HenFlowGraphTypes.FlowNode) -> void:
	_host = _host_control
	node = _node

	_painter.bind(_host)


func get_hits() -> Array[Dictionary]:
	return _hits


# the rect never changes with the level, so dropping the slots costs no layout
func set_detail(_level: int) -> void:
	if _detail == _level:
		return

	_detail = _level

	if _final_size != Vector2.ZERO:
		apply_size(_final_size)


# offscreen the draw list is dead weight, but the pin rects are not: the wires of
# a visible node can end on a culled one, so only the drawing goes
func set_culled(_culled: bool) -> void:
	if visible != _culled:
		return

	visible = not _culled

	if is_instance_valid(_compact_label):
		_compact_label.visible = visible and _detail != Detail.FULL


# the part under the cursor lights up. returns whether anything changed, so the
# viewer can skip the redraw of a card that was already showing this
func set_hover(_kind: StringName, _ref: Variant) -> bool:
	if _hover_kind == _kind and _hover_ref == _ref:
		return false

	_hover_kind = _kind
	_hover_ref = _ref

	if _final_size != Vector2.ZERO:
		apply_size(_final_size)

	return true


# the debugger saw this action run. it outlives the trace throttle on purpose, so
# an action running every frame glows instead of strobing
func set_running(_on: bool) -> bool:
	if _running == _on:
		return false

	_running = _on

	if _final_size != Vector2.ZERO:
		apply_size(_final_size)

	return true


func is_running() -> bool:
	return _running


# holds the name readable while the cam zooms out, by counter-scaling instead of
# redrawing at a bigger size
func set_title_scale(_factor: float) -> void:
	_title_scale = _factor

	if is_instance_valid(_compact_label) and _compact_label.scale.x != _factor:
		_compact_label.scale = Vector2(_factor, _factor)


# re-reads the action and redraws inside the rect it already occupies. returns
# whether the size it would ask for changed, which is the only case that has to
# move the graph around it
func refresh_content() -> bool:
	var before: Vector2 = _base_size
	var applied: Vector2 = _final_size
	# a loop carries the size the formatter inflated it to, and measuring resets it
	var inflated: Vector2 = node.size

	compute_size()
	node.size = inflated
	apply_size(applied)

	return not _base_size.is_equal_approx(before)


func intrinsic_size() -> Vector2:
	return _base_size


func accent() -> Color:
	return Color(node.accent) if node.accent.is_valid_html_color() else Color(HenActionVisuals.FALLBACK_COLOR)


func _title_color() -> Color:
	return accent().lerp(Color.WHITE, TITLE_MIX)


func _label_color() -> Color:
	return Color(accent().lerp(Color.WHITE, LABEL_MIX), LABEL_ALPHA)


# --- measure ---

# the size the node needs on its own; a loop grows later, when the formatter folds
# its body in, and apply_size is what sees that final rect
func compute_size() -> Vector2:
	_rows.clear()
	_flow_outs.clear()

	var inputs: Array[HenFlowGraphTypes.FlowPin] = node.pins_of(&'data_in')
	var outputs: Array[HenFlowGraphTypes.FlowPin] = node.pins_of(&'data_out')
	var row_h: float = maxf(_painter.line_height(LABEL_SIZE), SLOT_DOT)
	var left_w: float = 0.0
	var right_w: float = 0.0

	for i: int in range(maxi(inputs.size(), outputs.size())):
		var entry: Dictionary = {height = row_h}

		if i < inputs.size():
			var pin: HenFlowGraphTypes.FlowPin = inputs[i]
			var chip: String = _chip_text(pin)
			var chip_w: float = _painter.measure(chip, LABEL_SIZE).x + CHIP_PAD_H * 2.0 if not chip.is_empty() else 0.0

			entry.input = pin
			entry.label_w = _painter.measure(pin.label, LABEL_SIZE).x
			entry.chip = chip
			entry.chip_w = chip_w

			left_w = maxf(left_w, SLOT_DOT + SLOT_GAP + entry.label_w + (SLOT_GAP + chip_w if chip_w > 0.0 else 0.0))

		if i < outputs.size():
			var pin: HenFlowGraphTypes.FlowPin = outputs[i]

			entry.output = pin
			entry.output_w = _painter.measure(pin.label, LABEL_SIZE).x
			right_w = maxf(right_w, entry.output_w + SLOT_GAP + SLOT_DOT)

		_rows.append(entry)

	for pin: HenFlowGraphTypes.FlowPin in node.pins_of(&'exec_out'):
		# the body is a frame, not a cell, and `then` is the plain sequence
		if pin.id != HenFlowGraphTypes.BODY_PIN and not pin.label.is_empty():
			_flow_outs.append(pin)

	_header_h = maxf(ICON, _painter.line_height(TITLE_SIZE, true)) + HEADER_PAD_V * 2.0
	_rows_h = 0.0

	for entry: Dictionary in _rows:
		_rows_h += entry.height + ROW_GAP

	if _rows_h > 0.0:
		_rows_h += PAD * 2.0 - ROW_GAP

	_flow_h = _painter.line_height(FLOW_SIZE) + FLOW_PAD_V * 2.0 if not _flow_outs.is_empty() else 0.0

	_base_size = Vector2(
		maxf(maxf(MIN_WIDTH, _header_width()), maxf(PAD * 2.0 + left_w + (COLUMN_GAP + right_w if right_w > 0.0 else 0.0), _flow_width())),
		_header_h + _rows_h + _flow_h
	)

	node.size = _base_size

	# the formatter orders a fan by the exec anchors, and it runs before apply_size
	_emit_enter(_base_size)
	_emit_anchors(_base_size)

	return _base_size


func _header_width() -> float:
	return PAD * 2.0 + ICON + ICON_GAP + _painter.measure(node.title, TITLE_SIZE, true).x


func _flow_width() -> float:
	var total: float = 0.0

	for pin: HenFlowGraphTypes.FlowPin in _flow_outs:
		total += maxf(MIN_FLOW_CELL, _painter.measure(pin.label, FLOW_SIZE).x + FLOW_PAD_H * 2.0)

	return total


# a wired input shows no chip: the wire is the value
func _chip_text(_pin: HenFlowGraphTypes.FlowPin) -> String:
	if _pin.part.is_empty():
		return ''

	return str(_pin.part.get('value', ''))


# --- emit ---

func apply_size(_size: Vector2) -> void:
	_final_size = _size
	_chip_seq = 0
	_painter.clear()
	_hits.clear()

	var rect: Rect2 = Rect2(Vector2.ZERO, _size)
	var bg: Color = BASE_BG.lerp(accent(), BG_TINT)
	var border: Color = BASE_BG.lerp(accent(), BORDER_TINT)

	if node.body.is_empty() or _detail != Detail.FULL:
		_painter.add_style(_flat(bg, CORNER, border, true), rect)
	else:
		# the opaque plate stops at the rows: over the body it would bury the wires
		# of the chain nested inside, which are drawn under every card
		_painter.add_style(_flat(bg, CORNER, Color.TRANSPARENT, true), Rect2(Vector2.ZERO, Vector2(_size.x, _header_h + _rows_h)))
		# after the plate, or it would paint over the outline along the rows
		_painter.add_style(_flat(Color.TRANSPARENT, CORNER, border), rect)

	_emit_enter(_size)
	_emit_anchors(_size)

	if _detail != Detail.FULL:
		_build_compact_label(_size)
		_hit(rect, &'node', {})
		queue_redraw()
		return

	if is_instance_valid(_compact_label):
		_compact_label.visible = false

	_emit_header(_size)
	_emit_rows(_size)
	_emit_flow_outs(_size)

	if not node.body.is_empty():
		_emit_body_frame(_size)

	_hit(rect, &'node', {})
	_emit_hover()
	_emit_running(rect)

	queue_redraw()


# last, over everything: set_detail, set_hover and refresh_content all rebuild the
# whole list, and a highlight painted anywhere else is wiped by an unrelated hover
func _emit_running(_rect: Rect2) -> void:
	if not _running:
		return

	_painter.add_style(_run_style(), _rect)


func _run_style() -> StyleBoxFlat:
	if _style_cache.has('running'):
		return _style_cache['running']

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.set_corner_radius_all(CORNER)
	style.border_color = RUN_COLOR
	style.set_border_width_all(RUN_BORDER_WIDTH)
	style.shadow_color = RUN_SHADOW
	style.shadow_size = RUN_SHADOW_SIZE

	_style_cache['running'] = style

	return style


# drawn last, over whatever it covers, so no part has to know it can be hovered
func _emit_hover() -> void:
	if _hover_kind.is_empty() or _hover_kind == &'node':
		return

	for hit: Dictionary in _hits:
		if hit.kind != _hover_kind or hit.get('pin', null) != _hover_ref:
			continue

		_painter.add_style(
			_flat(Color(accent(), HOVER_ALPHA), CHIP_CORNER if _hover_kind == &'chip' else 0),
			hit.rect
		)
		return


func _emit_header(_size: Vector2) -> void:
	var centre: float = _header_h * 0.5

	_emit_icon(Rect2(Vector2(PAD, centre - ICON * 0.5), Vector2(ICON, ICON)))

	var title_h: float = _painter.line_height(TITLE_SIZE, true)

	_painter.add_text(
		node.title,
		TITLE_SIZE,
		Vector2(PAD + ICON + ICON_GAP, centre - title_h * 0.5),
		_title_color(),
		true
	)

	_rule(_header_h, _size.x)
	_hit(Rect2(Vector2.ZERO, Vector2(_size.x, _header_h)), &'header', {})


func _emit_icon(_rect: Rect2) -> void:
	var glyph: float = _rect.size.x * (ICON_GLYPH / ICON)

	_painter.add_style(_flat(accent(), int(_rect.size.x * (float(ICON_CORNER) / ICON))), _rect)
	_painter.add_texture(
		HenActionVisuals.icon_texture(node.icon),
		Rect2(_rect.position + Vector2.ONE * (_rect.size.x - glyph) * 0.5, Vector2(glyph, glyph)),
		Color.WHITE
	)


# far out the slots are noise: only the badge and the name still say anything, and
# they live in their own node so the zoom counter-scale is a transform, not a redraw
func _build_compact_label(_size: Vector2) -> void:
	if _compact_label == null:
		_compact_label = CompactLabel.new()
		add_child(_compact_label)

	_compact_label.build(_painter, node.title, HenActionVisuals.icon_texture(node.icon), accent(), _title_color())
	_compact_label.position = _size * 0.5
	_compact_label.scale = Vector2(_title_scale, _title_scale)
	_compact_label.visible = true


func _emit_rows(_size: Vector2) -> void:
	var y: float = _header_h + PAD

	for entry: Dictionary in _rows:
		var centre: float = y + entry.height * 0.5

		if entry.has('input'):
			_emit_input(entry, centre)

		if entry.has('output'):
			_emit_output(entry, centre, _size.x)

		y += entry.height + ROW_GAP


# the dot sits inside the card, the way the cnode connector does, so the line
# lands on the slot instead of on the outline
func _emit_input(_entry: Dictionary, _centre: float) -> void:
	var pin: HenFlowGraphTypes.FlowPin = _entry.input
	var color: Color = _pin_color(pin)

	_painter.add_style(_flat(color, int(SLOT_DOT * 0.5)), pin.rect)

	var label_h: float = _painter.line_height(LABEL_SIZE)
	var x: float = PAD + SLOT_DOT + SLOT_GAP

	_painter.add_text(pin.label, LABEL_SIZE, Vector2(x, _centre - label_h * 0.5), _label_color())

	if _entry.chip_w <= 0.0:
		return

	var box: Rect2 = Rect2(
		Vector2(x + _entry.label_w + SLOT_GAP, _centre - (label_h + 4.0) * 0.5),
		Vector2(_entry.chip_w, label_h + 4.0)
	)

	_painter.add_style(_flat(Color(color, 0.16), CHIP_CORNER), box)
	_painter.add_text(_entry.chip, LABEL_SIZE, Vector2(box.position.x + CHIP_PAD_H, _centre - label_h * 0.5), color)

	# the editor addresses a chip by its place in the card, not by the pin
	_hit(box, &'chip', {pin = pin, part = pin.part, index = _chip_seq})
	_chip_seq += 1


func _emit_output(_entry: Dictionary, _centre: float, _width: float) -> void:
	var pin: HenFlowGraphTypes.FlowPin = _entry.output
	var label_h: float = _painter.line_height(LABEL_SIZE)

	_painter.add_style(_flat(_pin_color(pin), int(SLOT_DOT * 0.5)), pin.rect)

	_painter.add_text(
		pin.label,
		LABEL_SIZE,
		Vector2(_width - PAD - SLOT_DOT - SLOT_GAP - _entry.output_w, _centre - label_h * 0.5),
		_label_color()
	)


# a branch is a cell along the bottom, split by a rule, the way the cnode does it.
# `then` is the plain sequence and gets no cell, only an anchor
func _emit_flow_outs(_size: Vector2) -> void:
	if _flow_outs.is_empty():
		return

	var top: float = _size.y - _flow_h
	var label_h: float = _painter.line_height(FLOW_SIZE)
	var step: float = _size.x / float(_flow_outs.size())
	var x: float = 0.0

	for index: int in range(_flow_outs.size()):
		var pin: HenFlowGraphTypes.FlowPin = _flow_outs[index]
		var label_w: float = _painter.measure(pin.label, FLOW_SIZE).x
		var color: Color = HenActionVisuals.phase_color(pin.id) if node.kind == &'state_entry' \
			else HenActionVisuals.branch_color(pin.id, pin.label, _label_color())

		# the rule over the cell is the branch, the card keeps its own background
		_painter.add_line(Vector2(x, top), Vector2(x + step, top), color, SEPARATOR_WIDTH)

		if index > 0:
			_painter.add_line(Vector2(x, top), Vector2(x, _size.y), _rule_color(), SEPARATOR_WIDTH)

		_painter.add_text(
			pin.label,
			FLOW_SIZE,
			Vector2(x + (step - label_w) * 0.5, top + (_flow_h - label_h) * 0.5),
			color
		)

		_hit(Rect2(Vector2(x, top), Vector2(step, _flow_h)), &'exec_out', {pin = pin})

		x += step


# the exec ports are anchors for the wires and nothing else, so they are placed
# whatever the detail level is
func _emit_anchors(_size: Vector2) -> void:
	var then: HenFlowGraphTypes.FlowPin = node.pin(HenFlowGraphTypes.THEN_PIN)

	if then and then.kind == &'exec_out':
		then.rect = Rect2(Vector2(_size.x * 0.5 - 1.0, _size.y - 2.0), Vector2(2, 2))

	var y: float = _header_h + PAD

	for entry: Dictionary in _rows:
		var centre: float = y + entry.height * 0.5

		if entry.has('input'):
			(entry.input as HenFlowGraphTypes.FlowPin).rect = Rect2(
				Vector2(PAD, centre - SLOT_DOT * 0.5),
				Vector2(SLOT_DOT, SLOT_DOT)
			)

		if entry.has('output'):
			(entry.output as HenFlowGraphTypes.FlowPin).rect = Rect2(
				Vector2(_size.x - PAD - SLOT_DOT, centre - SLOT_DOT * 0.5),
				Vector2(SLOT_DOT, SLOT_DOT)
			)

		y += entry.height + ROW_GAP

	if _flow_outs.is_empty():
		return

	var step: float = _size.x / float(_flow_outs.size())

	for index: int in range(_flow_outs.size()):
		_flow_outs[index].rect = Rect2(
			Vector2(step * (float(index) + 0.5) - 1.0, _size.y - 2.0),
			Vector2(2, 2)
		)


# the sequence arrives at the header, so the anchor is the top edge and there is
# nothing to draw for it
func _emit_enter(_size: Vector2) -> void:
	var enter: HenFlowGraphTypes.FlowPin = node.pin(HenFlowGraphTypes.ENTER_PIN)

	if enter and enter.kind == &'exec_in':
		enter.rect = Rect2(Vector2(_size.x * 0.5 - 1.0, 0.0), Vector2(2, 2))


# the loop's chain lives in the space the formatter added at the bottom
func _emit_body_frame(_size: Vector2) -> void:
	var top: float = _header_h + _rows_h

	_painter.add_style(
		_flat(BODY_BG, CORNER),
		Rect2(Vector2(BODY_PAD * 0.5, top), Vector2(_size.x - BODY_PAD, _size.y - top - BODY_PAD * 0.5))
	)

	# the body port is not drawn as a slot, only anchored: over the first nested
	# action's centre, so the wire into the body drops straight instead of hooking
	var body: HenFlowGraphTypes.FlowPin = node.pin(HenFlowGraphTypes.BODY_PIN)

	if body:
		var first: HenFlowGraphTypes.FlowNode = node.body[0]

		body.rect = Rect2(
			Vector2(first.position.x - node.position.x + first.size.x * 0.5 - 1.0, top - 1.0),
			Vector2(2, 2)
		)


func _rule(_y: float, _width: float) -> void:
	_painter.add_line(Vector2(0.0, _y), Vector2(_width, _y), _rule_color(), SEPARATOR_WIDTH)


func _rule_color() -> Color:
	return BASE_BG.lerp(accent(), RULE_TINT)


func _pin_color(_pin: HenFlowGraphTypes.FlowPin) -> Color:
	if _pin.part.is_empty():
		return Color(HenActionVisuals.KINDS.get('action', '#ff9e64'))

	return HenActionVisuals.kind_color(str(_pin.part.get('kind', 'literal')))


func _hit(_rect: Rect2, _kind: StringName, _data: Dictionary) -> void:
	_data.rect = _rect
	_data.kind = _kind
	_hits.append(_data)


func _flat(
	_bg: Color,
	_corner: int,
	_border: Color = Color.TRANSPARENT,
	_shadow: bool = false
) -> StyleBoxFlat:
	var key: String = '%d|%d|%d|%d' % [_bg.to_rgba32(), _corner, _border.to_rgba32(), 1 if _shadow else 0]

	if _style_cache.has(key):
		return _style_cache[key]

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = _bg
	style.set_corner_radius_all(_corner)

	if _border.a > 0.0:
		style.border_color = _border
		style.set_border_width_all(1)

	if _shadow:
		style.shadow_size = SHADOW_SIZE
		style.shadow_color = SHADOW_COLOR

	_style_cache[key] = style

	return style


func _draw() -> void:
	_painter.replay(self )


class CompactLabel extends Node2D:
	static var _chips: Dictionary = {}

	var _painter: HenCardPainter


	# everything centred on the origin, so the parent only sets a position
	func build(_source: HenCardPainter, _title: String, _icon: Texture2D, _accent: Color, _color: Color) -> void:
		var size: int = HenFlowNodeCard.TITLE_SIZE
		var ratio: float = float(HenFlowNodeCard.ICON_CORNER) / HenFlowNodeCard.ICON
		var gap: float = HenFlowNodeCard.COMPACT_GAP

		_painter = HenCardPainter.new()
		_painter.font = _source.font
		_painter.bold = _source.bold
		_painter.font_scale = _source.font_scale

		var title_h: float = _painter.line_height(size, true)
		var title_w: float = _painter.measure(_title, size, true).x
		var badge: float = title_h * HenFlowNodeCard.COMPACT_ICON_RATIO
		var line_h: float = maxf(title_h, badge)
		var x: float = -(badge + gap + title_w) * 0.5
		var y: float = -line_h * 0.5

		_painter.add_style(
			_chip(_accent, int(badge * ratio)),
			Rect2(Vector2(x, y + (line_h - badge) * 0.5), Vector2(badge, badge))
		)

		var glyph: float = badge * (HenFlowNodeCard.ICON_GLYPH / HenFlowNodeCard.ICON)

		_painter.add_texture(
			_icon,
			Rect2(Vector2(x + (badge - glyph) * 0.5, y + (line_h - glyph) * 0.5), Vector2(glyph, glyph)),
			Color.WHITE
		)

		_painter.add_text(_title, size, Vector2(x + badge + gap, y + (line_h - title_h) * 0.5), _color, true)

		queue_redraw()


	static func _chip(_color: Color, _corner: int) -> StyleBoxFlat:
		var key: String = '%d|%d' % [_color.to_rgba32(), _corner]

		if not _chips.has(key):
			var style: StyleBoxFlat = StyleBoxFlat.new()
			style.bg_color = _color
			style.set_corner_radius_all(_corner)
			_chips[key] = style

		return _chips[key]


	func _draw() -> void:
		if _painter:
			_painter.replay(self )
