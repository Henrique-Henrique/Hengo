@tool
class_name HenTabs extends TabBar

class TabData:
	var id: int
	var name: StringName


func _ready() -> void:
	tab_clicked.connect(_on_tab_selected)
	HenGlobal.SIGNAL_BUS.scripts_generation_started.connect(_on_scripts_generation_started)
	HenGlobal.SIGNAL_BUS.scripts_generation_finished.connect(_on_scripts_generation_finished)


func _on_scripts_generation_started() -> void:
	for idx in tab_count:
		set_tab_disabled(idx, true)

	
func _on_scripts_generation_finished(_script_list: PackedStringArray) -> void:
	for idx in tab_count:
		set_tab_disabled(idx, false)


func _on_tab_selected(_index: int) -> void:
	var meta: TabData = get_tab_metadata(_index)

	if meta:
		if not await HenLoader.load(ResourceUID.get_id_path(meta.id)):
			HenGlobal.SIGNAL_BUS.set_terminal_text.emit.call_deferred(HenUtils.get_error_text("Failed to load script: " + ResourceUID.get_id_path(meta.id)))


func add_script_tab(id: int) -> void:
	var tab: TabData = TabData.new()

	tab.id = id
	tab.name = ResourceUID.get_id_path(id).get_basename()

	for idx in tab_count:
		var meta = get_tab_metadata(idx)
		if meta and meta.id == id:
			current_tab = idx
			return

	add_tab(tab.name)
	set_tab_metadata(tab_count - 1, tab)
	select_next_available()
