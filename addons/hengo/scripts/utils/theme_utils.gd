@tool
class_name ThemeUtils
extends RefCounted


# creates a dynamic copy of the theme scaled by the editor's scale factor
static func create_scaled_theme(base_theme: Theme, scale: float) -> Theme:
	if scale <= 1.0:
		return base_theme

	scale = min(scale, 1.2)

	var new_theme: Theme = base_theme.duplicate(true)

	for type in new_theme.get_type_list():
		_scale_theme_items(new_theme, type, scale)

	return new_theme


# scales fonts, constants and styleboxes for a specific type
static func _scale_theme_items(theme: Theme, type: String, scale: float) -> void:
	for size_name in theme.get_font_size_list(type):
		var font_size: int = theme.get_font_size(size_name, type)
		theme.set_font_size(size_name, type, int(font_size * scale))

	for const_name in theme.get_constant_list(type):
		var constant_value: int = theme.get_constant(const_name, type)
		theme.set_constant(const_name, type, int(constant_value * scale))

	for style_name in theme.get_stylebox_list(type):
		var style: StyleBox = theme.get_stylebox(style_name, type)
		_scale_stylebox(style, scale)


# updates stylebox properties based on scale
static func _scale_stylebox(style_box: StyleBox, scale: float) -> void:
	if style_box is StyleBoxFlat:
		var style: StyleBoxFlat = style_box
		style.content_margin_left *= scale
		style.content_margin_top *= scale
		style.content_margin_right *= scale
		style.content_margin_bottom *= scale
		
		style.corner_radius_top_left = int(style.corner_radius_top_left * scale)
		style.corner_radius_top_right = int(style.corner_radius_top_right * scale)
		style.corner_radius_bottom_right = int(style.corner_radius_bottom_right * scale)
		style.corner_radius_bottom_left = int(style.corner_radius_bottom_left * scale)
		
		style.expand_margin_left *= scale
		style.expand_margin_top *= scale
		style.expand_margin_right *= scale
		style.expand_margin_bottom *= scale
		
		style.shadow_size = int(style.shadow_size * scale)
		style.shadow_offset *= scale

	elif style_box is StyleBoxTexture:
		var style: StyleBoxTexture = style_box
		style.content_margin_left *= scale
		style.content_margin_right *= scale
		style.content_margin_top *= scale
		style.content_margin_bottom *= scale
		
		style.expand_margin_left *= scale
		style.expand_margin_right *= scale
		style.expand_margin_top *= scale
		style.expand_margin_bottom *= scale