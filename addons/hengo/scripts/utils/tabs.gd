@tool
class_name HenTabs extends VBoxContainer

# vertical list showing the currently open script as a single row. visual only;
# multi-document logic is intentionally out of scope for now.

var _is_collapsed: bool = false


func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self):
		return

	add_theme_constant_override('separation', 2)

	var global: HenGlobal = Engine.get_singleton(&'Global')
	if global:
		global.TABS = self

	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	if signal_bus:
		signal_bus.request_list_update.connect(refresh)

	refresh()


# rebuilds the row list from the active script (global.SAVE_DATA)
func refresh() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	for child: Node in get_children():
		child.queue_free()

	if not global or not global.SAVE_DATA:
		return

	var row: HenScriptTabRow = HenScriptTabRow.new()
	add_child(row)
	row.setup(global.SAVE_DATA.identity.name, global.SAVE_DATA.identity.type)
	row.set_collapsed(_is_collapsed)
	row.set_active(true)


func set_collapsed(_collapsed: bool) -> void:
	_is_collapsed = _collapsed
	for child: Node in get_children():
		if child is HenScriptTabRow:
			(child as HenScriptTabRow).set_collapsed(_collapsed)
