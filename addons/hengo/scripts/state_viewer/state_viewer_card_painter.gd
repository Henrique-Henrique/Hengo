@tool
class_name HenCardPainter
extends RefCounted

# builds a flat draw list during layout and replays it inside _draw, so measuring
# never depends on anything having been rendered

var font: Font
var font_scale: float = 1.0

var _ops: Array[Dictionary] = []


# the host is what resolves the theme: a label parented under it would pick the
# same font, so drawn text can never drift from the controls it replaces
func bind(host: Control) -> void:
	font = host.get_theme_font(&'font', &'Label')
	font_scale = ThemeUtils.get_font_scale()


func clear() -> void:
	_ops.clear()


func fs(base: int) -> int:
	return maxi(1, roundi(base * font_scale))


func measure(text: String, base_size: int) -> Vector2:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs(base_size))


func line_height(base_size: int) -> float:
	return font.get_height(fs(base_size))


func add_style(style: StyleBox, rect: Rect2) -> void:
	_ops.append({op = &'style', style = style, rect = rect})


# pos is the top-left of the text box; draw_string wants the baseline
func add_text(text: String, base_size: int, pos: Vector2, color: Color) -> void:
	var size: int = fs(base_size)

	_ops.append({
		op = &'text',
		text = text,
		size = size,
		pos = pos + Vector2(0, font.get_ascent(size)),
		color = color
	})


func add_texture(texture: Texture2D, rect: Rect2, modulate: Color) -> void:
	if texture == null:
		return

	_ops.append({op = &'texture', texture = texture, rect = rect, modulate = modulate})


func add_line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	_ops.append({op = &'line', from = from, to = to, color = color, width = width})


func replay(canvas: CanvasItem) -> void:
	var item: RID = canvas.get_canvas_item()

	for op: Dictionary in _ops:
		match op.op:
			&'style':
				(op.style as StyleBox).draw(item, op.rect)
			&'text':
				canvas.draw_string(font, op.pos, op.text, HORIZONTAL_ALIGNMENT_LEFT, -1, op.size, op.color)
			&'texture':
				canvas.draw_texture_rect(op.texture, op.rect, false, op.modulate)
			&'line':
				canvas.draw_line(op.from, op.to, op.color, op.width)
