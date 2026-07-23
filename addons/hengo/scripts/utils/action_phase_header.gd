@tool
class_name HenActionPhaseHeader extends MarginContainer

const PHASE_ICONS = {
	enter = 'arrow-right-to-line',
	update = 'refresh-cw',
	exit = 'arrow-left-from-line'
}

signal add_pressed(phase: StringName)
signal action_dropped(action: HenSaveAction, phase: StringName)

var phase: StringName = &'update'

var _color: Color = Color(HenActionRow.FALLBACK_COLOR)
var _drop_hint: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	get_node('%AddBt').pressed.connect(func() -> void: add_pressed.emit(phase))
	ThemeUtils.apply_font_scale(self )


func setup(_phase: StringName, _count: int) -> void:
	phase = _phase
	_color = Color(str(HenActionRow.PHASE_COLORS.get(str(_phase), HenActionRow.FALLBACK_COLOR)))

	var name_label: Label = get_node('%Name')
	name_label.text = str(_phase).to_upper()
	name_label.add_theme_color_override('font_color', Color(_color, 0.75 if _count > 0 else 0.4))

	var count_label: Label = get_node('%Count')
	count_label.text = str(_count) if _count > 0 else 'empty'
	count_label.add_theme_color_override('font_color', Color(1, 1, 1, 0.35))

	var icon_rect: TextureRect = get_node('Row/Icon')
	icon_rect.texture = HenActionRow.icon_texture(str(PHASE_ICONS.get(str(_phase), '')))
	icon_rect.modulate = Color(_color, 0.85 if _count > 0 else 0.4)


# dropping on a header sends the action to the top of that phase
func _can_drop_data(_pos: Vector2, _data: Variant) -> bool:
	var action: HenSaveAction = HenActionsPanel.dragged_action(_data)

	if not action or not HenActionsPanel.can_use_phase(action, phase):
		return false

	_set_drop_hint(true)
	return true


func _drop_data(_pos: Vector2, _data: Variant) -> void:
	_set_drop_hint(false)
	action_dropped.emit(HenActionsPanel.dragged_action(_data), phase)


func _notification(_what: int) -> void:
	if _what == NOTIFICATION_DRAG_END or _what == NOTIFICATION_MOUSE_EXIT:
		_set_drop_hint(false)


func _set_drop_hint(_on: bool) -> void:
	if _drop_hint == _on:
		return

	_drop_hint = _on
	queue_redraw()


func _draw() -> void:
	if _drop_hint:
		draw_line(Vector2(0, size.y - 1), Vector2(size.x, size.y - 1), _color, 2.0)
