@tool
class_name HenHengo extends EditorPlugin

const HENGO_ROOT = preload('res://addons/hengo/scenes/hengo_root.tscn')
const PLUGIN_NAME = 'Hengo'
const MAIN_THEME = preload('res://addons/hengo/references/theme/main.tres')

var main_scene: HenHengoRoot
var last_scene: StringName
# debug
var debug_plugin: EditorDebuggerPlugin


class DockConfig:
	var id: EditorPlugin.DockSlot
	var ref: TabContainer
	var tab_control: Control

	func _init(_id: EditorPlugin.DockSlot, _ref: TabContainer) -> void:
		id = _id
		ref = _ref


func scale_theme_to_editor_scale() -> void:
	var current_scale: float = EditorInterface.get_editor_scale()
	var stored_scale: float = MAIN_THEME.get_meta('hengo_theme_scale', 1.0)
	
	if not is_equal_approx(current_scale, stored_scale):
		var scale_factor: float = current_scale / stored_scale
		
		for type in MAIN_THEME.get_type_list():
			for constant in MAIN_THEME.get_constant_list(type):
				var value = MAIN_THEME.get_constant(constant, type)
				MAIN_THEME.set_constant(constant, type, int(value * scale_factor))
			
			for font_size in MAIN_THEME.get_font_size_list(type):
				var value = MAIN_THEME.get_font_size(font_size, type)
				MAIN_THEME.set_font_size(font_size, type, int(value * scale_factor))
		
		MAIN_THEME.set_meta('hengo_theme_scale', current_scale)

	var visited_styleboxes: Dictionary = {}
	
	for type in MAIN_THEME.get_type_list():
		for stylebox_name in MAIN_THEME.get_stylebox_list(type):
			var stylebox: StyleBox = MAIN_THEME.get_stylebox(stylebox_name, type)
			
			if not stylebox or visited_styleboxes.has(stylebox):
				continue
				
			visited_styleboxes[stylebox] = true
			_scale_stylebox(stylebox, current_scale)


func _scale_stylebox(stylebox: StyleBox, target_scale: float) -> void:
	var stored_scale: float = stylebox.get_meta('hengo_theme_scale', 1.0)
	
	if is_equal_approx(target_scale, stored_scale):
		return
		
	var scale_factor: float = target_scale / stored_scale

	if stylebox is StyleBoxFlat:
		var sb_flat = stylebox as StyleBoxFlat
		sb_flat.border_width_left = int(sb_flat.border_width_left * scale_factor)
		sb_flat.border_width_top = int(sb_flat.border_width_top * scale_factor)
		sb_flat.border_width_right = int(sb_flat.border_width_right * scale_factor)
		sb_flat.border_width_bottom = int(sb_flat.border_width_bottom * scale_factor)
		
		sb_flat.corner_radius_top_left = int(sb_flat.corner_radius_top_left * scale_factor)
		sb_flat.corner_radius_top_right = int(sb_flat.corner_radius_top_right * scale_factor)
		sb_flat.corner_radius_bottom_right = int(sb_flat.corner_radius_bottom_right * scale_factor)
		sb_flat.corner_radius_bottom_left = int(sb_flat.corner_radius_bottom_left * scale_factor)
		
		sb_flat.expand_margin_left = sb_flat.expand_margin_left * scale_factor
		sb_flat.expand_margin_top = sb_flat.expand_margin_top * scale_factor
		sb_flat.expand_margin_right = sb_flat.expand_margin_right * scale_factor
		sb_flat.expand_margin_bottom = sb_flat.expand_margin_bottom * scale_factor
	
	stylebox.set_meta('hengo_theme_scale', target_scale)


func _enter_tree():
	scale_theme_to_editor_scale()
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
	global.TABS = main_scene.get_node('%Tabs')
	global.GENERAL_POPUP = main_scene.get_node('%GeneralPopUpContainer')
	global.CNODE_UI = cnode_ui
	global.DASHBOARD = main_scene.get_node('%DashBoard')

	EditorInterface.get_editor_main_screen().add_child(main_scene)
	_make_visible(false)

	# getting tabs
	if global.DOCKS.is_empty():
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
			global.DOCKS[dock] = DockConfig.new(dock, parent)
			parent.remove_child(c)

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
		(main_scene.get_node('%DashboardCanvas') as CanvasLayer).visible = _visible


func _get_plugin_name():
	return PLUGIN_NAME


func _has_main_screen() -> bool:
	return true


func _handles(object: Object) -> bool:
	var toast: HenToast = Engine.get_singleton(&'ToastContainer')
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var loader: HenLoader = Engine.get_singleton(&'Loader')

	# if object is GDScript and (object as GDScript).resource_path.begins_with('res://hengo/'):
	# 	if not await loader.load((object as GDScript).resource_path):
	# 		toast.notify.call_deferred("Failed to load script: " + (object as GDScript).resource_path, HenToast.MessageType.ERROR)
	# 		return true
		
	# 	global.CAM.can_scroll = true
	# 	return true

	# if object is Resource and (object as Resource).resource_path.begins_with(HenEnums.HENGO_SAVE_PATH):
	# 	if not await loader.load((object as Resource).resource_path):
	# 		toast.notify.call_deferred("Failed to load save file: " + (object as Resource).resource_path, HenToast.MessageType.ERROR)
	# 		return true
		
	# 	global.CAM.can_scroll = true
	# 	return true

	return false
