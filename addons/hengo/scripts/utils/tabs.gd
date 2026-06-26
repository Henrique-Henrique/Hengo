@tool
class_name HenTabs extends VBoxContainer

# vertical list of the scripts open in the active collection. clicking a row
# switches the active script.

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


# rebuilds the row list from the open scripts of the active collection
func refresh() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	for child: Node in get_children():
		child.queue_free()

	if not global:
		return

	for save_data: HenSaveData in global.OPEN_SCRIPTS:
		if not save_data:
			continue

		var row: HenScriptTabRow = HenScriptTabRow.new()
		add_child(row)
		row.setup(save_data)
		row.set_collapsed(_is_collapsed)
		row.set_active(save_data == global.SAVE_DATA)
		row.pressed.connect(_on_row_pressed)


func _on_row_pressed(_save_data: HenSaveData) -> void:
	(Engine.get_singleton(&'Loader') as HenLoader).set_active_script(_save_data)


func set_collapsed(_collapsed: bool) -> void:
	_is_collapsed = _collapsed
	for child: Node in get_children():
		if child is HenScriptTabRow:
			(child as HenScriptTabRow).set_collapsed(_collapsed)
