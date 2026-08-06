@tool
class_name HenActionCapsule extends PanelContainer

const BASE_BG: Color = Color('#151a22')
const TINT: float = 0.2
const DEPTH_DARKEN: float = 0.14
const TITLE_COLOR: Color = Color('#dde4ed')
const TITLE_SIZE: int = 16

var action: HenSaveAction

var _on_pressed: Callable = Callable()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


# data is HenActionsPanel.capsule_data: the nested action, its accent and its own
# parts, which may hold capsules of their own
func setup(_data: Dictionary, _depth: int, _sink: Array, _on_chip: Callable) -> void:
	action = _data.get('action')
	_on_pressed = _on_chip

	var color: String = str(_data.get('color', ''))
	var accent: Color = Color(color) if not color.is_empty() else Color(HenActionRow.FALLBACK_COLOR)

	var icon: TextureRect = get_node('Margin/Line/Icon')
	icon.texture = HenActionRow.icon_texture(str(_data.get('icon', '')))
	icon.modulate = accent

	var title: Label = get_node('Margin/Line/Title')
	title.text = str(_data.get('title', ''))
	ThemeUtils.apply_font_size(title, TITLE_SIZE)
	title.add_theme_color_override('font_color', TITLE_COLOR)

	_apply_style(accent, _depth)

	# an HBox, not a flow: the capsule moves to the next line whole instead of
	# being split in half by the wrap
	HenActionLine.fill(get_node('Margin/Line'), _data.get('parts', []), _depth, _sink, _on_chip)


func _apply_style(_accent: Color, _depth: int) -> void:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(10)
	style.bg_color = BASE_BG.lerp(_accent, TINT).darkened(DEPTH_DARKEN * _depth)

	add_theme_stylebox_override('panel', style)


func _gui_input(_event: InputEvent) -> void:
	if not _event is InputEventMouseButton or not _on_pressed.is_valid():
		return

	var mb := _event as InputEventMouseButton

	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return

	accept_event()
	_on_pressed.call({kind = &'action', slot = {action = action, inline = true}}, self)
