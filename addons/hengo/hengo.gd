@tool
class_name HenHengo extends EditorPlugin

const PLUGIN_NAME = 'Hengo'

var main_scene
var gd_previewer: CodeEdit

# debug
var debug_plugin: EditorDebuggerPlugin

class DockConfig:
	var id: EditorPlugin.DockSlot
	var ref: TabContainer
	var tab_control: Control

	func _init(_id: EditorPlugin.DockSlot, _ref: TabContainer) -> void:
		id = _id
		ref = _ref

func _enter_tree():
	debug_plugin = preload('res://addons/hengo/scripts/debug/debug_plugin.gd').new()
	add_debugger_plugin(debug_plugin)

	if not FileAccess.file_exists(HenEnums.NATIVE_API_PATH):
		HenApiGenerator.generate_native_api()

	# getting native api like String, float... methods.
	var native_api_file: FileAccess = FileAccess.open(HenEnums.NATIVE_API_PATH, FileAccess.READ)

	if native_api_file:
		var api_json: Dictionary = JSON.parse_string(native_api_file.get_as_text())

		HenEnums.NATIVE_API_LIST = api_json.native_api
		HenEnums.CONST_API_LIST = api_json.const_api
		HenEnums.SINGLETON_API_LIST = api_json.singleton_api
		HenEnums.NATIVE_PROPS_LIST = api_json.native_props
		HenEnums.MATH_UTILITY_NAME_LIST = api_json.math_utility_names

		native_api_file.close()
	else:
		print('NATIVE LIST JSON -> ', FileAccess.get_open_error())

	# creating hengo folder
	if not DirAccess.dir_exists_absolute('res://hengo'):
		DirAccess.make_dir_absolute('res://hengo')
		EditorInterface.get_resource_filesystem().scan()

	# setting scene reference here to prevent crash on development when reload scripts on editor :)
	HenAssets.ConnectionLineScene = load('res://addons/hengo/scenes/connection_line.tscn')
	HenAssets.FlowConnectionLineScene = load('res://addons/hengo/scenes/flow_connection_line.tscn')
	HenAssets.HengoRootScene = load('res://addons/hengo/scenes/hengo_root.tscn')
	HenAssets.CNodeInputScene = load('res://addons/hengo/scenes/cnode_input.tscn')
	HenAssets.CNodeOutputScene = load('res://addons/hengo/scenes/cnode_output.tscn')
	HenAssets.CNodeScene = load('res://addons/hengo/scenes/cnode.tscn')
	HenAssets.CNodeFlowScene = load('res://addons/hengo/scenes/cnode_flow.tscn')
	HenAssets.CNodeIfFlowScene = load('res://addons/hengo/scenes/cnode_if_flow.tscn')
	HenAssets.EventScene = load('res://addons/hengo/scenes/event.tscn')
	HenAssets.EventStructScene = load('res://addons/hengo/scenes/event_structure.tscn')
	HenAssets.PropContainerScene = load('res://addons/hengo/scenes/prop_container.tscn')
	HenAssets.CNodeInputLabel = load('res://addons/hengo/scenes/cnode_input_label.tscn')
	HenAssets.CNodeCenterImage = load('res://addons/hengo/scenes/cnode_center_image.tscn')

	main_scene = HenAssets.HengoRootScene.instantiate()

	HenGlobal.GENERAL_POPUP = main_scene.get_node('%GeneralPopUp')

	EditorInterface.get_editor_main_screen().add_child(main_scene)
	_make_visible(false)


	# getting tabs
	if HenGlobal.DOCKS.is_empty():
		var docks: Array[int] = [
			EditorPlugin.DOCK_SLOT_LEFT_UL,
			EditorPlugin.DOCK_SLOT_LEFT_UR,
			EditorPlugin.DOCK_SLOT_LEFT_BL,
			EditorPlugin.DOCK_SLOT_LEFT_BR,
			EditorPlugin.DOCK_SLOT_RIGHT_UL,
			EditorPlugin.DOCK_SLOT_RIGHT_UR,
			EditorPlugin.DOCK_SLOT_RIGHT_BL,
			EditorPlugin.DOCK_SLOT_RIGHT_BR,
		]

		for dock in docks:
			var c: Control = Control.new()
			add_control_to_dock(dock, c)
			var parent: TabContainer = c.get_parent()
			HenGlobal.DOCKS[dock] = DockConfig.new(dock, parent)
			parent.remove_child(c)

	main_screen_changed.connect(_on_change_main_screen)
	set_docks()

	add_autoload_singleton('HengoDebugger', 'res://addons/hengo/scripts/debug/hengo_debugger.gd')
	HenGlobal.HENGO_EDITOR_PLUGIN = self

	HenGlobal.cnode_pool.clear()
	HenGlobal.state_pool.clear()
	HenGlobal.connection_line_pool.clear()
	HenGlobal.flow_connection_line_pool.clear()
	HenGlobal.state_connection_line_pool.clear()
	HenGlobal.script_config = null

	# creating cnode pool
	HenCnode.instantiate_and_add_pool()

	# creates referencs types
	if FileAccess.file_exists(HenEnums.SCRIPT_REF_PATH):
		var file: FileAccess = FileAccess.open(HenEnums.SCRIPT_REF_PATH, FileAccess.READ)
		var data_str = file.get_as_text()
		file.close()
		var data = JSON.parse_string(data_str)
		if data and typeof(data) == TYPE_DICTIONARY: HenGlobal.SCRIPT_REF_CACHE = data

	
func _get_window_layout(_configuration: ConfigFile) -> void:
	if main_scene.visible:
		if HenGlobal.ACTION_BAR.filesystem_parent:
			return

		hide_docks()
	else:
		set_docks()


func _on_change_main_screen(_name: String) -> void:
	if _name == PLUGIN_NAME:
		hide_docks()


func _exit_tree():
	HenGlobal.can_instantiate_pool = false
	HenGlobal.script_config = null
	
	remove_debugger_plugin(debug_plugin)
	remove_control_from_bottom_panel(gd_previewer)

	if main_scene:
		main_scene.queue_free()
	
	remove_autoload_singleton('HengoDebugger')
	HenGlobal.HENGO_EDITOR_PLUGIN = null
	print('Done')


func _make_visible(_visible: bool):
	if main_scene:
		if _visible: hide_docks()
		else:
			HenGlobal.ACTION_BAR.filesystem_dock()
			show_docks()

		main_scene.visible = _visible

func _get_plugin_name():
	return PLUGIN_NAME

func _has_main_screen() -> bool:
	return true

func _handles(object: Object) -> bool:
	if object is GDScript and (object as GDScript).resource_path.begins_with('res://hengo/'):
		HenLoader.load((object as GDScript).resource_path)
		HenGlobal.CAM.can_scroll = true
		return true

	if object is Resource and (object as Resource).resource_path.begins_with('res://hengo/save/'):
		HenLoader.load((object as Resource).resource_path)
		HenGlobal.CAM.can_scroll = true
		return true

	return false

# public
#
func set_docks() -> void:
	for dock: DockConfig in HenGlobal.DOCKS.values():
		dock.tab_control = dock.ref.get_current_tab_control()

func hide_docks() -> void:
	tab_visibility(false)
	bottom_panel_visibility(false)

	for dock: DockConfig in HenGlobal.DOCKS.values():
		dock.ref.visible = false

func show_docks() -> void:
	tab_visibility(true)
	bottom_panel_visibility(true)
	
	for dock: DockConfig in HenGlobal.DOCKS.values():
		if dock.tab_control:
			dock.ref.visible = true
			dock.tab_control.visible = true


func tab_visibility(_show: bool) -> void:
	var tabs_container = EditorInterface.get_editor_main_screen().get_node_or_null('../..')
	
	if tabs_container:
		var tab = tabs_container.get_child(0) if tabs_container.get_child_count() > 0 else null

		if tab: tab.visible = _show


func bottom_panel_visibility(_show: bool) -> void:
	var bottom_panel = get_tree().root.find_child('*EditorBottomPanel*', true, false)

	if bottom_panel:
		bottom_panel.visible = _show