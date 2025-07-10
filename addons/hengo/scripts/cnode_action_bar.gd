@tool
class_name HenCNodeActionBar extends HBoxContainer

@export var dashboard: Button

var filesystem_parent: Control

func _ready() -> void:
	if EditorInterface.get_edited_scene_root() == self or EditorInterface.get_edited_scene_root() == owner:
		set_process(false)
		set_physics_process(false)
		set_process_input(false)
		set_process_unhandled_input(false)
		set_process_unhandled_key_input(false)
		return
	
	HenGlobal.ACTION_BAR = self
	dashboard.pressed.connect(_on_dashboard)


func filesystem_dock(_hide_docks: bool = false) -> void:
	if filesystem_parent:
		var filesystem: FileSystemDock = EditorInterface.get_file_system_dock()
		
		filesystem.get_parent().remove_child(filesystem)
		filesystem_parent.add_child(filesystem)
	
	filesystem_parent = null
	
	if _hide_docks:
		HenGlobal.CAM.can_scroll = true
		HenGlobal.HENGO_EDITOR_PLUGIN.hide_docks()


func _on_dashboard() -> void:
	HenGlobal.CAM.can_scroll = false
	
	var filesystem: FileSystemDock = EditorInterface.get_file_system_dock()
	var right_dock: TabContainer = HenGlobal.DOCKS[EditorPlugin.DOCK_SLOT_RIGHT_UR].ref

	if not filesystem_parent:
		filesystem_parent = filesystem.get_parent()
		filesystem_parent.remove_child(filesystem)

		right_dock.add_child(filesystem)
		right_dock.visible = true
		filesystem.visible = true
		return
	
	filesystem.get_parent().remove_child(filesystem)
	filesystem_parent.add_child(filesystem)
	
	HenGlobal.HENGO_EDITOR_PLUGIN.hide_docks()
	filesystem_parent = null

	HenGlobal.CAM.can_scroll = true