@tool
class_name HenStateEdgePill extends PanelContainer

const FONT_SIZE: int = 14
const ICON_SIZE: float = 12.0
const GAP: float = 4.0
const PAD_X: float = 7.0
const PAD_Y: float = 3.0
const BG_COLOR: Color = Color(0.13, 0.13, 0.16, 0.95)
const TEXT_COLOR: Color = Color(0.9, 0.9, 0.9, 1.0)

var _style: StyleBoxFlat


# size the overlay needs before the pill is laid out, so labels can be spread apart
static func measure(_text: String, _has_icon: bool) -> Vector2:
	var text_size: Vector2 = ThemeDB.fallback_font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var icon_w: float = (ICON_SIZE + GAP) if _has_icon else 0.0

	return Vector2(text_size.x + icon_w + PAD_X * 2.0, maxf(text_size.y, ICON_SIZE) + PAD_Y * 2.0)


# transition name tinted by its kind; a null icon collapses the slot
func setup(_text: String, _icon: Texture2D, _color: Color) -> void:
	if _style == null:
		_build_style()

	var icon_rect: TextureRect = get_node('Box/Icon')
	icon_rect.visible = _icon != null
	icon_rect.texture = _icon
	icon_rect.modulate = _color

	(get_node('Box/Text') as Label).text = _text
	_style.border_color = Color(_color.r, _color.g, _color.b, 0.55)


func _build_style() -> void:
	_style = StyleBoxFlat.new()
	_style.bg_color = BG_COLOR
	_style.set_border_width_all(1)
	_style.set_corner_radius_all(8)
	_style.content_margin_left = PAD_X
	_style.content_margin_right = PAD_X
	_style.content_margin_top = PAD_Y
	_style.content_margin_bottom = PAD_Y
	add_theme_stylebox_override('panel', _style)

	var label: Label = get_node('Box/Text')
	label.add_theme_font_size_override('font_size', FONT_SIZE)
	label.add_theme_color_override('font_color', TEXT_COLOR)
