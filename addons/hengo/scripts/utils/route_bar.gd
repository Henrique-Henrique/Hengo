@tool
class_name HenRouteBar extends HBoxContainer

# the path of definitions open in the canvas, drawn beside the script name. the
# script itself is already named there, so the bar only shows what is nested in it

const SEPARATOR_ICON: String = 'chevron-right'
const CRUMB_FONT_SIZE: int = 13


func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self ):
		return

	(get_node('%RouteBaseBt') as Button).pressed.connect(HenRoute.go_base)

	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')

	if signal_bus:
		for signal_name: StringName in [&'route_changed', &'request_list_update', &'request_structural_update']:
			if not signal_bus.get(signal_name).is_connected(refresh):
				signal_bus.get(signal_name).connect(refresh)

	refresh()


func refresh(_a: Variant = null, _b: Variant = null) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var crumbs: Array[Dictionary] = HenRoute.crumbs(global.SAVE_DATA if global else null)
	var container: HBoxContainer = get_node('%RouteCrumbs')

	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()

	# the script crumb is the status bar label itself, so only what nests in it shows
	visible = crumbs.size() > 1

	if not visible:
		return

	for index: int in range(1, crumbs.size()):
		container.add_child(_separator())
		container.add_child(_crumb(crumbs[index], index == crumbs.size() - 1))


func _separator() -> TextureRect:
	var icon: TextureRect = TextureRect.new()

	icon.texture = HenActionVisuals.icon_texture(SEPARATOR_ICON)
	icon.custom_minimum_size = Vector2(12, 12)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.modulate = Color(1, 1, 1, 0.35)

	return icon


func _crumb(_data: Dictionary, _last: bool) -> Button:
	var bt: Button = Button.new()
	var color: Color = HenUtils.UI_COLORS.state if str(_data.kind) == str(HenRoute.KIND_MACRO) else HenUtils.UI_COLORS.code

	bt.text = str(_data.name)
	bt.icon = HenActionVisuals.icon_texture(str(HenRoute.ICONS.get(str(_data.kind), '')))
	bt.flat = true
	bt.focus_mode = Control.FOCUS_NONE
	bt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	bt.modulate = Color(1, 1, 1, 1 if _last else 0.65)

	ThemeUtils.apply_font_size(bt, CRUMB_FONT_SIZE)
	HenUtils.tint_button(bt, color)

	if _last:
		bt.mouse_default_cursor_shape = Control.CURSOR_ARROW
	else:
		bt.pressed.connect(HenRoute.go_to.bind(int(_data.index)))

	return bt
