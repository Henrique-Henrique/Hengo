@tool
class_name HenFlowStateFrame
extends Node2D

# the box a state's node graph lives in. the outer layout engine treats it as one
# leaf, so it only has to answer compute_size

const CANVAS_BG: Color = Color('#0f1116')
const BORDER: Color = Color(0.19, 0.19, 0.232, 1)
const NAME_COLOR: Color = Color(0.9, 0.9, 0.9, 1)
const META_COLOR: Color = Color('#9aa4b4')
# how far each tint travels from the canvas toward the state's own colour
const BODY_TINT: float = 0.10
const HEADER_TINT: float = 0.30
const BORDER_TINT: float = 0.55

# the state palette already holds greens, so a running frame cannot be told apart
# by hue alone: it takes the border width and the glow, which nothing else uses
const RUN_COLOR: Color = HenActionVisuals.RUN_COLOR
const RUN_SHADOW: Color = Color(0.39, 1.0, 0.57, 0.26)
const RUN_BORDER_WIDTH: int = 5
const RUN_SHADOW_SIZE: int = 12

# the header buttons, laid out like the ones a node card carries
const BT_SIZE: float = 22.0
const BT_GAP: float = 3.0
const BT_ICON: float = 14.0
const BT_COLOR: Color = Color('#c3ccdb')
const BT_OFF_ALPHA: float = 0.3
const BT_HOVER_ALPHA: float = 0.22
const BT_CORNER: int = 4
const MENU_DOT: float = 3.0
const MENU_DOT_GAP: float = 6.0
const DELETE_COLOR: Color = Color('#c16460')
const START_COLOR: Color = Color('#63ff92')
const START_BG: Color = Color('#26482f')
const REENTER_COLOR: Color = Color('#7fb4ff')
const REENTER_BG: Color = Color('#1e2c45')
const REENTER_TEXT: String = 'REENTER'
const BADGE_SIZE: int = 11
const BADGE_PAD_H: float = 6.0
const ERROR_COLOR: Color = HenActionVisuals.ERROR_COLOR
const ERROR_BG: Color = Color('#3d1c1c')

const ICON_MOVE: Texture2D = preload('res://addons/hengo/assets/new_icons/move.svg')
const ICON_ADD_SUB: Texture2D = preload('res://addons/hengo/assets/new_icons/circle-plus.svg')
const ICON_TRASH: Texture2D = preload('res://addons/hengo/assets/new_icons/trash-2.svg')
const ICON_START: Texture2D = preload('res://addons/hengo/assets/new_icons/flag.svg')
const ICON_ENTER: Texture2D = preload('res://addons/hengo/assets/new_icons/chevrons-right.svg')

const CORNER: int = 8
const HEADER_CORNER: int = 6
const BORDER_WIDTH: int = 3
const HEADER_PAD_H: float = 8.0
const HEADER_PAD_V: float = 5.0
const PAD: float = 28.0
const GAP: float = 10.0
const NAME_SIZE: int = 18
const META_SIZE: int = 14

static var _style_cache: Dictionary = {}

var state_name: String = ''

var _host: Control
var _painter: HenCardPainter = HenCardPainter.new()
var _meta: String = ''
var _accent: Color = BORDER
var _content: Vector2 = Vector2.ZERO
var _header_h: float = 0.0
var _final_size: Vector2 = Vector2.ZERO
var _running: bool = false
var _is_start: bool = false
var _is_base: bool = false
var _can_reenter: bool = false
# the state chrome, dropped on a frame that stands for something else
var _chrome: bool = true
# a use of a macro: it keeps the state chrome but opens the definition instead of
# growing a machine of its own
var _is_macro_use: bool = false
var _errors: int = 0
var _hover_kind: StringName = &''
var _hits: Array[Dictionary] = []


# a frame that is not a state of the machine wears no state chrome: a function
# body has nothing to start, nest, move or delete
func hide_chrome() -> void:
	_chrome = false


func mark_macro_use() -> void:
	_is_macro_use = true


func setup(_host_control: Control, _name: String, _description: String, _nodes: int, _accent_color: Color, _start: bool = false, _base: bool = false, _reenter: bool = false) -> void:
	_host = _host_control
	state_name = _name
	_accent = _accent_color
	_is_start = _start
	_is_base = _base
	_can_reenter = _reenter

	_painter.bind(_host)

	_meta = '%d node%s' % [_nodes, '' if _nodes == 1 else 's']

	if not _description.is_empty():
		_meta += '  ·  ' + _description


# the bounding of the graph inside, handed over before the outer layout measures
func set_content_size(_size: Vector2) -> void:
	_content = _size


# how many steps the codegen drops inside this state, which the header wears so a
# broken action is findable without opening every frame
func set_error_count(_count: int) -> bool:
	if _errors == _count:
		return false

	_errors = _count

	if _final_size != Vector2.ZERO:
		apply_size(_final_size)

	return true


func compute_size() -> Vector2:
	_header_h = _painter.line_height(NAME_SIZE) + HEADER_PAD_V * 2.0

	return Vector2(
		maxf(_content.x + PAD * 2.0, _header_width() + HEADER_PAD_H * 2.0),
		_header_h + GAP + _content.y + PAD
	)


# where the graph starts, in frame space
func content_origin() -> Vector2:
	return Vector2(PAD, _header_h + GAP)


# the band that carries the name, in frame space: the only part of a frame that
# answers the mouse, since the rest is the graph inside it
func header_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(_final_size.x, _header_h))


func frame_size() -> Vector2:
	return _final_size


# the button strip answers the mouse the same way a card's own parts do
func get_hits() -> Array[Dictionary]:
	return _hits


func set_hover(_kind: StringName) -> bool:
	if _hover_kind == _kind:
		return false

	_hover_kind = _kind

	if _final_size != Vector2.ZERO:
		apply_size(_final_size)

	return true


func _header_width() -> float:
	return _text_end() - HEADER_PAD_H + _strip_width()


# where the name, the node count and the start badge stop, in frame space
func _text_end() -> float:
	var end: float = HEADER_PAD_H \
		+ _painter.measure(state_name.to_upper(), NAME_SIZE).x + GAP \
		+ _painter.measure(_meta, META_SIZE).x + GAP

	end += (_badge_width('START') + GAP) if _is_start else 0.0
	end += (_badge_width(REENTER_TEXT) + GAP) if _can_reenter else 0.0

	return end


func _strip_width() -> float:
	return BT_SIZE * 5.0 + BT_GAP * 4.0


func _badge_width(_text: String) -> float:
	return _painter.measure(_text, BADGE_SIZE).x + BADGE_PAD_H * 2.0


func _error_badge_text() -> String:
	return '%d ERROR%s' % [_errors, '' if _errors == 1 else 'S']


func _error_badge_width() -> float:
	return _painter.measure(_error_badge_text(), BADGE_SIZE).x + BADGE_PAD_H * 2.0


func apply_size(_size: Vector2) -> void:
	_final_size = _size
	_painter.clear()
	_hits.clear()

	_painter.add_style(_body(), Rect2(Vector2.ZERO, _size))
	_emit_header(_size)

	queue_redraw()


# a band across the top, same chrome the state viewer gives a script container
func _emit_header(_size: Vector2) -> void:
	_painter.add_style(_header(), Rect2(Vector2.ZERO, Vector2(_size.x, _header_h)))

	var centre: float = _header_h * 0.5
	var x: float = HEADER_PAD_H
	var name_h: float = _painter.line_height(NAME_SIZE)
	var upper: String = state_name.to_upper()

	_painter.add_text(upper, NAME_SIZE, Vector2(x, centre - name_h * 0.5), NAME_COLOR)
	x += _painter.measure(upper, NAME_SIZE).x + GAP

	_painter.add_text(_meta, META_SIZE, Vector2(x, centre - _painter.line_height(META_SIZE) * 0.5), META_COLOR)
	x += _painter.measure(_meta, META_SIZE).x + GAP

	if _is_start:
		_emit_badge(Vector2(x, centre), 'START', START_BG, START_COLOR)
		x += _badge_width('START') + GAP

	if _can_reenter:
		_emit_badge(Vector2(x, centre), REENTER_TEXT, REENTER_BG, REENTER_COLOR)
		x += _badge_width(REENTER_TEXT) + GAP

	# the count arrives after the layout measured the header, so it takes the free
	# space before the buttons and is dropped when there is none
	if _errors > 0:
		var at: float = _size.x - HEADER_PAD_H - _strip_width() - GAP - _error_badge_width()

		if at > x:
			_emit_error_badge(Vector2(at, centre))

	_emit_buttons(_size, centre)


# the same badge the sidebar puts on a start row, so the two views read alike
func _emit_badge(_at: Vector2, _text: String, _bg: Color, _color: Color) -> void:
	var text_h: float = _painter.line_height(BADGE_SIZE)
	var rect := Rect2(Vector2(_at.x, _at.y - text_h * 0.5), Vector2(_badge_width(_text), text_h))

	_painter.add_style(_chip(_bg, BT_CORNER), rect)
	_painter.add_text(_text, BADGE_SIZE, rect.position + Vector2(BADGE_PAD_H, 0.0), _color)


func _emit_error_badge(_at: Vector2) -> void:
	var text_h: float = _painter.line_height(BADGE_SIZE)
	var rect := Rect2(Vector2(_at.x, _at.y - text_h * 0.5), Vector2(_error_badge_width(), text_h))

	_painter.add_style(_chip(ERROR_BG, BT_CORNER), rect)
	_painter.add_text(_error_badge_text(), BADGE_SIZE, rect.position + Vector2(BADGE_PAD_H, 0.0), ERROR_COLOR)


# right aligned: start, new sub-state, move, delete, then the menu the sidebar
# popup opens from
func _emit_buttons(_size: Vector2, _centre: float) -> void:
	if not _chrome:
		return

	var y: float = _centre - BT_SIZE * 0.5
	var x: float = _size.x - HEADER_PAD_H - BT_SIZE

	_emit_menu(Rect2(Vector2(x, y), Vector2(BT_SIZE, BT_SIZE)))
	x -= BT_SIZE + BT_GAP

	# the script always keeps its base state, so it neither goes nor moves away
	_emit_button(Rect2(Vector2(x, y), Vector2(BT_SIZE, BT_SIZE)), ICON_TRASH, DELETE_COLOR, &'state_delete', not _is_base)
	x -= BT_SIZE + BT_GAP

	_emit_button(Rect2(Vector2(x, y), Vector2(BT_SIZE, BT_SIZE)), ICON_MOVE, BT_COLOR, &'state_move', not _is_base)
	x -= BT_SIZE + BT_GAP

	# a use runs the machine of its definition, so it opens it instead of nesting
	if _is_macro_use:
		_emit_button(Rect2(Vector2(x, y), Vector2(BT_SIZE, BT_SIZE)), ICON_ENTER, BT_COLOR, &'state_enter')
	else:
		_emit_button(Rect2(Vector2(x, y), Vector2(BT_SIZE, BT_SIZE)), ICON_ADD_SUB, BT_COLOR, &'state_add_sub')

	x -= BT_SIZE + BT_GAP

	# a state that already runs first has nothing to set, so the button only shows
	_emit_button(Rect2(Vector2(x, y), Vector2(BT_SIZE, BT_SIZE)), ICON_START, START_COLOR, &'state_start', not _is_start)


func _emit_button(_rect: Rect2, _icon: Texture2D, _color: Color, _kind: StringName, _enabled: bool = true) -> void:
	if _enabled:
		_emit_hover(_rect, _kind)

	_painter.add_texture(
		_icon,
		Rect2(_rect.position + Vector2.ONE * (BT_SIZE - BT_ICON) * 0.5, Vector2(BT_ICON, BT_ICON)),
		_color if _enabled else Color(_color, BT_OFF_ALPHA)
	)

	if _enabled:
		_hit(_rect, _kind)


func _emit_menu(_rect: Rect2) -> void:
	_emit_hover(_rect, &'state_menu')

	var top: float = _rect.position.y + BT_SIZE * 0.5 - MENU_DOT_GAP - MENU_DOT * 0.5

	for i: int in range(3):
		_painter.add_style(
			_chip(BT_COLOR, 1),
			Rect2(Vector2(_rect.position.x + (BT_SIZE - MENU_DOT) * 0.5, top + i * MENU_DOT_GAP), Vector2(MENU_DOT, MENU_DOT))
		)

	_hit(_rect, &'state_menu')


# behind the glyph and not over it: a wash on top mutes the red and the green the
# two coloured buttons are read by
func _emit_hover(_rect: Rect2, _kind: StringName) -> void:
	if _hover_kind != _kind:
		return

	_painter.add_style(_chip(Color(BT_COLOR, BT_HOVER_ALPHA), BT_CORNER), _rect)


func _hit(_rect: Rect2, _kind: StringName) -> void:
	_hits.append({rect = _rect, kind = _kind})


func _chip(_color: Color, _corner: int) -> StyleBoxFlat:
	return _cached('chip|%d|%d' % [_color.to_rgba32(), _corner], func() -> StyleBoxFlat:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = _color
		style.set_corner_radius_all(_corner)

		return style
	)


# the state the debugger says is running right now
func set_running(_on: bool) -> bool:
	if _running == _on:
		return false

	_running = _on

	if _final_size != Vector2.ZERO:
		apply_size(_final_size)

	return true


func is_running() -> bool:
	return _running


func _body() -> StyleBoxFlat:
	if _running:
		return _cached('running', func() -> StyleBoxFlat:
			var style: StyleBoxFlat = StyleBoxFlat.new()
			style.bg_color = CANVAS_BG.lerp(RUN_COLOR, BODY_TINT)
			style.set_corner_radius_all(CORNER)
			style.border_color = RUN_COLOR
			style.set_border_width_all(RUN_BORDER_WIDTH)
			style.shadow_color = RUN_SHADOW
			style.shadow_size = RUN_SHADOW_SIZE

			return style
		)

	return _cached('body|%d' % _accent.to_rgba32(), func() -> StyleBoxFlat:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = CANVAS_BG.lerp(_accent, BODY_TINT)
		style.set_corner_radius_all(CORNER)
		style.border_color = CANVAS_BG.lerp(_accent, BORDER_TINT)
		style.set_border_width_all(BORDER_WIDTH)

		return style
	)


func _header() -> StyleBoxFlat:
	return _cached('header|%d' % _accent.to_rgba32(), func() -> StyleBoxFlat:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = CANVAS_BG.lerp(_accent, HEADER_TINT)
		style.corner_radius_top_left = HEADER_CORNER
		style.corner_radius_top_right = HEADER_CORNER

		return style
	)



func _cached(_key: String, _build: Callable) -> StyleBoxFlat:
	if not _style_cache.has(_key):
		_style_cache[_key] = _build.call()

	return _style_cache[_key]


func _draw() -> void:
	_painter.replay(self )
