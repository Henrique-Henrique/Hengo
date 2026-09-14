@tool
class_name HenTabs extends VBoxContainer

# vertical list of the scripts open in the active collection. clicking a row
# switches the active script.

const DROPDOWN_SCENE = preload('res://addons/hengo/scenes/drop_down_menu.tscn')

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
		row.menu_request.connect(_on_menu_request)


func _on_row_pressed(_save_data: HenSaveData) -> void:
	(Engine.get_singleton(&'Loader') as HenLoader).set_active_script(_save_data)


func menu_entries(_save_data: HenSaveData, _source: Control) -> Array[Dictionary]:
	return [
		{name = 'Change Base Type', callable = _on_change_type_request.bind(_save_data, _source)},
		{name = 'Delete Script', callable = _on_delete_request.bind(_save_data)},
	]


func _on_menu_request(_save_data: HenSaveData, _source: Control) -> void:
	var entries: Array[Dictionary] = menu_entries(_save_data, _source)
	var menu: HenDropDownMenu = DROPDOWN_SCENE.instantiate()
	var by_name: Dictionary = {}
	var items: Array = []

	for entry: Dictionary in entries:
		by_name[str(entry.name)] = entry.callable
		items.append({name = str(entry.name)})

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(menu, {
		layout = HenGeneralPopup.Layout.ANCHORED,
		anchor_to = _source,
		side = SIDE_RIGHT,
		blur = false,
		min_size = Vector2(200, minf(280.0, 56.0 + items.size() * 30.0))
	})

	menu.mount(items, func(_item: Dictionary) -> void:
		var call: Variant = by_name.get(str(_item.name))

		# the menu closes itself on click, which would also close a popup opened in the same frame
		if call is Callable:
			(call as Callable).call_deferred()
	, 'item_type')


func _on_change_type_request(_save_data: HenSaveData, _source: Control) -> void:
	var popup: HenChangeScriptType = (load('res://addons/hengo/scenes/utils/change_script_type.tscn') as PackedScene).instantiate()

	popup.setup(_save_data)
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(popup, {
		layout = HenGeneralPopup.Layout.ANCHORED,
		anchor_to = _source,
		side = SIDE_RIGHT,
		min_size = Vector2(380, 0)
	})


func _on_delete_request(_save_data: HenSaveData) -> void:
	var name: String = _save_data.identity.name
	var message: String = "Delete the script '%s'? Its compiled file goes to the trash too." % name
	var referencing: Array[String] = HenCollectionManager.scripts_referencing(_save_data.identity.id)

	if not referencing.is_empty():
		message += '\n\nVariables in these scripts point at it and will break: ' + ', '.join(referencing)

	HenConfirmPopup.show_confirm(
		message,
		HenCollectionManager.delete_script.bind(_save_data.identity.id),
		'Delete Script',
		'Delete',
		'Cancel'
	)


func set_collapsed(_collapsed: bool) -> void:
	_is_collapsed = _collapsed
	for child: Node in get_children():
		if child is HenScriptTabRow:
			(child as HenScriptTabRow).set_collapsed(_collapsed)
