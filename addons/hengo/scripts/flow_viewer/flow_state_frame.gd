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


func setup(_host_control: Control, _name: String, _description: String, _nodes: int, _accent_color: Color) -> void:
	_host = _host_control
	state_name = _name
	_accent = _accent_color

	_painter.bind(_host)

	_meta = '%d node%s' % [_nodes, '' if _nodes == 1 else 's']

	if not _description.is_empty():
		_meta += '  ·  ' + _description


# the bounding of the graph inside, handed over before the outer layout measures
func set_content_size(_size: Vector2) -> void:
	_content = _size


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


func _header_width() -> float:
	return _painter.measure(state_name.to_upper(), NAME_SIZE).x \
		+ GAP + _painter.measure(_meta, META_SIZE).x


func apply_size(_size: Vector2) -> void:
	_final_size = _size
	_painter.clear()

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


func _body() -> StyleBoxFlat:
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
