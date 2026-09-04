@tool
class_name HenHengo extends EditorPlugin

const PLUGIN_NAME = 'Hengo'
const HENGO_ROOT_PATH = 'res://addons/hengo/scenes/hengo_root.tscn'
const BASE_THEME_PATH = 'res://addons/hengo/references/theme/hengo.tres'
const DEBUG_PLUGIN_PATH = 'res://addons/hengo/scripts/debug/debug_plugin.gd'

const DOCK_BOTTOM = 0
const DOCK_LEFT = 1
const DOCK_RIGHT = 2

var main_scene: HenHengoRoot
var bottom_panel_button: Button
var _dock_location: int = DOCK_BOTTOM
var _did_first_show: bool = false
var _fullscreen: bool = false
# debug
var debug_plugin: EditorDebuggerPlugin


func _enter_tree():
	debug_plugin = (load(DEBUG_PLUGIN_PATH) as GDScript).new()
	add_debugger_plugin(debug_plugin)

	# creating hengo folder
	if not DirAccess.dir_exists_absolute(HenEnums.HENGO_PATH):
		DirAccess.make_dir_absolute(HenEnums.HENGO_PATH)

	if not DirAccess.dir_exists_absolute(HenEnums.HENGO_COLLECTION_PATH):
		DirAccess.make_dir_absolute(HenEnums.HENGO_COLLECTION_PATH)

	var ignore_path: String = HenEnums.HENGO_COLLECTION_PATH.path_join('.gdignore')
	var dev_mode: bool = ProjectSettings.get_setting(HenSettings.DEVELOPMENT_MODE_PATH, false)

	# handling .gdignore based on development setting
	if dev_mode and FileAccess.file_exists(ignore_path):
		DirAccess.remove_absolute(ignore_path)
	elif not dev_mode and not FileAccess.file_exists(ignore_path):
		FileAccess.open(ignore_path, FileAccess.WRITE)

	if not DirAccess.dir_exists_absolute(HenEnums.HENGO_SCRIPTS_PATH):
		DirAccess.make_dir_absolute(HenEnums.HENGO_SCRIPTS_PATH)

	main_scene = (load(HENGO_ROOT_PATH) as PackedScene).instantiate()

	var ui_base: Control = main_scene.get_node('%UIBase')
	ui_base.theme = load(BASE_THEME_PATH) as Theme

	# shrinks chrome fonts for the user's 1080p factor before the tree enters (runs
	# before child _ready, so code overrides scaled via ThemeUtils.fs don't double)
	var theme: Theme = ui_base.theme
	theme.default_font_size = ThemeUtils.fs(ThemeUtils.BASE_DEFAULT_FONT_SIZE)
	ThemeUtils.apply_font_scale(ui_base)

	register_singletons()

	var thread_helper: HenThreadHelper = Engine.get_singleton(&'ThreadHelper')
	var map_deps: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
	var enums: HenEnums = Engine.get_singleton(&'Enums')
	var global: HenGlobal = Engine.get_singleton(&'Global')

	# map dependencies
	thread_helper.add_task(map_deps.start_map)

	# getting native api like String, float... methods.
	var native_api_file: FileAccess = FileAccess.open(enums.NATIVE_API_PATH, FileAccess.READ)

	if native_api_file:
		var api_json: Dictionary = JSON.parse_string(native_api_file.get_as_text())

		enums.NATIVE_API_LIST = api_json.native_api
		enums.CONST_API_LIST = api_json.const_api
		enums.SINGLETON_API_LIST = api_json.singleton_api
		enums.NATIVE_PROPS_LIST = api_json.native_props
		enums.MATH_UTILITY_NAME_LIST = api_json.math_utility_names

		native_api_file.close()
	else:
		print('NATIVE LIST JSON -> ', FileAccess.get_open_error())

	# setting globals
	global.HENGO_ROOT = main_scene
	global.TOOLTIP = main_scene.get_node('%Tooltip')
	global.SIDE_PANEL = main_scene.get_node('%SidePanel')
	global.DASHBOARD = main_scene.get_node('%DashBoard')

	var general_popup: HenGeneralPopup = Engine.get_singleton(&'GeneralPopup')
	general_popup.setup(main_scene.get_node('%UIBase'))

	# tab title used by both the bottom panel and the side docks
	main_scene.name = PLUGIN_NAME
	main_scene.visibility_changed.connect(_on_hengo_visibility_changed)

	# docks where the setting points (bottom panel by default)
	_dock_main_scene(ProjectSettings.get_setting(HenSettings.DOCK_LOCATION_PATH, DOCK_BOTTOM))
	add_autoload_singleton('HengoDebuggerInit', 'res://addons/hengo/scripts/debug/hengo_debugger_init.gd')
	global.HENGO_EDITOR_PLUGIN = self

	global.state_pool.clear()

	# syncs cam input to the initial (hidden) panel state
	_on_hengo_visibility_changed()


func _exit_tree():
	var global: HenGlobal = Engine.get_singleton(&'Global')

	global.can_instantiate_pool = false

	remove_debugger_plugin(debug_plugin)

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).force_close_all()

	if main_scene:
		_undock_main_scene()
		main_scene.queue_free()

	remove_autoload_singleton('HengoDebuggerInit')
	global.HENGO_EDITOR_PLUGIN = null
	unregister_singletons()


# adds main_scene to the bottom panel or a side dock
func _dock_main_scene(location: int) -> void:
	match location:
		DOCK_LEFT:
			add_control_to_dock(DOCK_SLOT_LEFT_UL, main_scene)
		DOCK_RIGHT:
			add_control_to_dock(DOCK_SLOT_RIGHT_UL, main_scene)
		_:
			bottom_panel_button = add_control_to_bottom_panel(main_scene, PLUGIN_NAME)

	_dock_location = location


# removes main_scene from its current editor area
func _undock_main_scene() -> void:
	if _fullscreen:
		EditorInterface.get_base_control().remove_child(main_scene)
		_fullscreen = false
		return

	if _dock_location == DOCK_BOTTOM:
		remove_control_from_bottom_panel(main_scene)
		bottom_panel_button = null
	else:
		remove_control_from_docks(main_scene)


# re-docks live when the setting changes
func apply_dock_location(location: int) -> void:
	if not main_scene or location == _dock_location:
		return

	# closes floating popups so none stays with stale coords after re-dock
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).force_close_all()

	_undock_main_scene()
	_dock_main_scene(location)

	if location == DOCK_BOTTOM:
		make_bottom_panel_item_visible(main_scene)


# moves the scene root: an inner node loses its owner and every '%Name' under it
func toggle_fullscreen() -> void:
	if not main_scene:
		return

	# an open popup holds window coords from before the move
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).force_close_all()

	if _fullscreen:
		EditorInterface.get_base_control().remove_child(main_scene)
		_dock_main_scene(_dock_location)

		if _dock_location == DOCK_BOTTOM:
			make_bottom_panel_item_visible(main_scene)
	else:
		_undock_main_scene()
		EditorInterface.get_base_control().add_child(main_scene)

	main_scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fullscreen = not _fullscreen


func register_singletons() -> void:
	if not main_scene:
		return
	
	for singleton_name: StringName in HenEnums.SINGLETON_LIST:
		Engine.register_singleton(singleton_name, (main_scene as HenHengoRoot).get_node(NodePath(StringName('%'+ singleton_name))))


func unregister_singletons() -> void:
	for singleton_name: StringName in HenEnums.SINGLETON_LIST:
		if Engine.has_singleton(singleton_name):
			Engine.unregister_singleton(singleton_name)


func _on_hengo_visibility_changed() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var vis: bool = main_scene.visible if main_scene else false

	HenCam.set_all_input_enabled(main_scene.get_tree() if main_scene else null, vis)

	# defers dashboard to first show so it lays out with a real size
	if vis and not _did_first_show:
		_did_first_show = true
		if global and global.DASHBOARD:
			global.DASHBOARD.show_dashboard()


func _get_plugin_name():
	return PLUGIN_NAME


func _has_main_screen() -> bool:
	return false
