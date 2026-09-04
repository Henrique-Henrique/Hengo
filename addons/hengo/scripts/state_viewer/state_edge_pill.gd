@tool
class_name HenStateEdgePill extends Node2D

# node2d, not a panel scene: at collection scale there is one of these per edge
# label, and the overlay animates their alpha through modulate, which a drawn
# item takes for free without ever redrawing

const FONT_SIZE: int = 14
const ICON_SIZE: float = 12.0
const GAP: float = 4.0
const PAD_X: float = 7.0
const PAD_Y: float = 3.0
const BG_COLOR: Color = Color(0.13, 0.13, 0.16, 0.95)
const TEXT_COLOR: Color = Color(0.9, 0.9, 0.9, 1.0)
const CORNER: int = 8

# border tint -> box, shared across every pill of the same kind
static var _style_cache: Dictionary = {}

var size: Vector2 = Vector2.ZERO

var _text: String = ''
var _icon: Texture2D = null
var _color: Color = Color.WHITE


static func font() -> Font:
	return ThemeDB.fallback_font


# size the overlay needs before the pill is placed, so labels can be spread apart
static func measure(_text: String, _has_icon: bool) -> Vector2:
	var text_size: Vector2 = font().get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var icon_w: float = (ICON_SIZE + GAP) if _has_icon else 0.0

	return Vector2(text_size.x + icon_w + PAD_X * 2.0, maxf(text_size.y, ICON_SIZE) + PAD_Y * 2.0)


# transition name tinted by its kind; a null icon collapses the slot
func setup(_new_text: String, _new_icon: Texture2D, _new_color: Color) -> void:
	if _text == _new_text and _icon == _new_icon and _color == _new_color:
		return

	_text = _new_text
	_icon = _new_icon
	_color = _new_color

	queue_redraw()


static func _style_for(_color: Color) -> StyleBoxFlat:
	var key: int = Color(_color.r, _color.g, _color.b, 0.55).to_rgba32()

	if _style_cache.has(key):
		return _style_cache[key]

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = BG_COLOR
	style.border_color = Color(_color.r, _color.g, _color.b, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(CORNER)

	_style_cache[key] = style

	return style


func _draw() -> void:
	if _text.is_empty():
		return

	var rect: Rect2 = Rect2(Vector2.ZERO, size)

	_style_for(_color).draw(get_canvas_item(), rect)

	var pill_font: Font = font()
	var x: float = PAD_X

	if _icon:
		draw_texture_rect(
			_icon,
			Rect2(Vector2(x, (size.y - ICON_SIZE) * 0.5), Vector2(ICON_SIZE, ICON_SIZE)),
			false,
			_color
		)
		x += ICON_SIZE + GAP

	var ascent: float = pill_font.get_ascent(FONT_SIZE)
	var text_h: float = pill_font.get_height(FONT_SIZE)

	draw_string(
		pill_font,
		Vector2(x, (size.y - text_h) * 0.5 + ascent),
		_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		FONT_SIZE,
		TEXT_COLOR
	)
