@tool
class_name HenHengo extends EditorPlugin

const HENGO_ROOT = preload('res://addons/hengo/scenes/hengo_root.tscn')
const PLUGIN_NAME = 'Hengo'
const BASE_THEME = preload('res://addons/hengo/references/theme/hengo.tres')

var main_scene: HenHengoRoot
var last_scene: StringName
# debug
var debug_plugin: EditorDebuggerPlugin


func _enter_tree():
	debug_plugin = preload('res://addons/hengo/scripts/debug/debug_plugin.gd').new()
	add_debugger_plugin(debug_plugin)

	# creating hengo folder
	if not DirAccess.dir_exists_absolute(HenEnums.HENGO_PATH):
		DirAccess.make_dir_absolute(HenEnums.HENGO_PATH)
		 
	if not DirAccess.dir_exists_absolute(HenEnums.HENGO_SAVE_PATH):
		DirAccess.make_dir_absolute(HenEnums.HENGO_SAVE_PATH)
	
	# var ignore_path: String = HenEnums.HENGO_SAVE_PATH.path_join('.gdignore')

	# if not FileAccess.file_exists(ignore_path):
	# 	FileAccess.open(ignore_path, FileAccess.WRITE)

	if not DirAccess.dir_exists_absolute(HenEnums.HENGO_SCRIPTS_PATH):
		DirAccess.make_dir_absolute(HenEnums.HENGO_SCRIPTS_PATH)

	main_scene = HENGO_ROOT.instantiate()

	(main_scene.get_node('%UIBase') as Control).theme = ThemeUtils.create_scaled_theme(BASE_THEME, EditorInterface.get_editor_scale())

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
	var cnode_ui = main_scene.get_node('%CNodeUI') as Panel

	global.history = UndoRedo.new()
	global.HENGO_ROOT = main_scene
	global.CAM = main_scene.get_node('%Cam')
	global.CNODE_CONTAINER = main_scene.get_node('%CnodeContainer')
	global.COMMENT_CONTAINER = main_scene.get_node('%CommentContainer')
	global.DROPDOWN_MENU = main_scene.get_node('%DropDownMenu')
	global.POPUP_CONTAINER = main_scene.get_node('%PopupContainer')
	global.DOCS_TOOLTIP = main_scene.get_node('%DocsToolTip')
	global.CONNECTION_GUIDE = cnode_ui.get_node('%ConnectionGuide')
	global.TOOLTIP = main_scene.get_node('%Tooltip')
	global.CODE_PREVIEWER = main_scene.get_node('%CodePreview')
	global.SIDE_PANEL = main_scene.get_node('%SidePanel')
	global.GENERAL_POPUP = main_scene.get_node('%GeneralPopUpContainer')
	global.CNODE_UI = cnode_ui
	global.DASHBOARD = main_scene.get_node('%DashBoard')
	global.RIGHT_SIDE_BAR = main_scene.get_node('%RightSideBar')

	EditorInterface.get_editor_main_screen().add_child(main_scene)
	_make_visible(false)
	add_autoload_singleton('HengoDebugger', 'res://addons/hengo/scripts/debug/hengo_debugger.gd')
	global.HENGO_EDITOR_PLUGIN = self

	global.cnode_pool.clear()
	global.state_pool.clear()
	global.connection_line_pool.clear()
	global.flow_connection_line_pool.clear()
	global.state_connection_line_pool.clear()

	main_screen_changed.connect(_on_main_changed)

	# creating cnode pool
	HenCnode.instantiate_and_add_pool()
	global.DASHBOARD.show_dashboard()

func _exit_tree():
	var global: HenGlobal = Engine.get_singleton(&'Global')

	global.can_instantiate_pool = false
	global.SELECTED_VIRTUAL_CNODE.clear()

	remove_debugger_plugin(debug_plugin)

	if main_scene:
		main_scene.queue_free()
	
	remove_autoload_singleton('HengoDebugger')
	global.HENGO_EDITOR_PLUGIN = null
	unregister_singletons()


func _on_main_changed(_screen_name: String) -> void:
	if _screen_name == PLUGIN_NAME:
		return
	
	last_scene = _screen_name


func hide_plugin() -> void:
	_make_visible(false)
	EditorInterface.set_main_screen_editor(
		last_scene if not last_scene.is_empty() else &'2D'
	)

func show_plugin() -> void:
	_make_visible(true)
	EditorInterface.set_main_screen_editor(PLUGIN_NAME)


func register_singletons() -> void:
	if not main_scene:
		return
	
	for singleton_name: StringName in HenEnums.SINGLETON_LIST:
		Engine.register_singleton(singleton_name, (main_scene as HenHengoRoot).get_node(NodePath(StringName('%'+ singleton_name))))


func unregister_singletons() -> void:
	for singleton_name: StringName in HenEnums.SINGLETON_LIST:
		if Engine.has_singleton(singleton_name):
			Engine.unregister_singleton(singleton_name)


func _make_visible(_visible: bool):
	if main_scene:
		main_scene.visible = _visible
		(main_scene.get_node('%Content') as CanvasLayer).visible = _visible
		(main_scene.get_node('%DashBoard') as HenDashboard).show_dashboard()

	var global: HenGlobal = Engine.get_singleton(&'Global')
	
	if global and global.CAM:
		global.CAM.set_process_input(_visible)

		if not _visible:
			global.CAM.set_physics_process(false)


func _get_plugin_name():
	return PLUGIN_NAME


func _has_main_screen() -> bool:
	return true
