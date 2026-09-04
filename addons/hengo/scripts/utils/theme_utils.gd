@tool
class_name ThemeUtils
extends RefCounted

const BASE_DEFAULT_FONT_SIZE: int = 16
const _FS_BASE_META: String = 'hen_fs_base_'


# reads the user's ui font scale factor from settings
static func get_font_scale() -> float:
	return ProjectSettings.get_setting(HenSettings.FONT_SCALE_PATH, 0.85)


# scales a base font size by the ui factor, clamped to a readable minimum
static func fs(base: int) -> int:
	return maxi(1, roundi(base * get_font_scale()))


# sets a scaled font-size override and records the unscaled base in meta, so a
# later apply_font_scale re-scales from base instead of compounding
static func apply_font_size(control: Control, base: int, key: String = 'font_size') -> void:
	control.set_meta(_FS_BASE_META + key, base)
	control.add_theme_font_size_override(key, maxi(1, roundi(base * get_font_scale())))


# recursively re-scales every font-size override under a chrome node from its
# recorded base (first pass records the current value); skips the zoom-controlled
# canvas (Cam). safe to re-run on factor changes
static func apply_font_scale(node: Node, scale: float = -1.0) -> void:
	if node is HenCam:
		return

	if scale < 0.0:
		scale = get_font_scale()

	if node is Control:
		var control: Control = node
		for prop in control.get_property_list():
			var prop_name: String = prop.name
			if prop_name.begins_with('theme_override_font_sizes/'):
				var key: String = prop_name.trim_prefix('theme_override_font_sizes/')
				if control.has_theme_font_size_override(key):
					var meta_key: String = _FS_BASE_META + key
					var base: int
					if control.has_meta(meta_key):
						base = control.get_meta(meta_key)
					else:
						base = control.get(prop_name)
						control.set_meta(meta_key, base)
					control.set(prop_name, maxi(1, roundi(base * scale)))

	for child in node.get_children():
		apply_font_scale(child, scale)


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