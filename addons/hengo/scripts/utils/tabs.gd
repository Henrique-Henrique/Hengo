@tool
class_name HenTabs extends TabBar

class TabData:
	var path: StringName
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
	var meta = get_tab_metadata(_index)

	if meta:
		HenLoader.load(meta.path)


func add_script_tab(_path: StringName) -> void:
	var tab: TabData = TabData.new()

	tab.path = _path
	tab.name = _path.get_basename().get_file()

	for idx in tab_count:
		var meta = get_tab_metadata(idx)
		if meta and meta.path == _path:
			current_tab = idx
			return

	add_tab(tab.name)
	set_tab_metadata(tab_count - 1, tab)
