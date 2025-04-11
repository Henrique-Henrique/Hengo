@tool
class_name HenHengo extends EditorPlugin

const PLUGIN_NAME = 'Hengo'
const MENU_NATIVE_API_NAME = "Hengo Generate Native Api"

var main_scene
var gd_previewer: CodeEdit
var tabs_hide_helper
var tabs_container

# docks
#
var dock_container
# left docks
var dock_left_1
var dock_left_2
# right docks
var dock_right_1
var dock_right_2
# scene tabs
var scene_tabs
var docks_references: Array = []

# file system tree
var file_system_tree: Tree
var file_tree_signals: Array = []

# debug
var debug_plugin: EditorDebuggerPlugin

func _enter_tree():
	debug_plugin = preload('res://addons/hengo/scripts/debug/debug_plugin.gd').new()
	add_debugger_plugin(debug_plugin)

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

	HenGlobal.editor_interface = get_editor_interface()
	print('setted')

	main_scene = HenAssets.HengoRootScene.instantiate()

	HenGlobal.GENERAL_POPUP = main_scene.get_node('%GeneralPopUp')

	EditorInterface.get_editor_main_screen().add_child(main_scene)
	_make_visible(false)

	var root = get_node('/root')

	# setting tabs references
	dock_container = root.find_child('DockHSplitLeftL', true, false)
	dock_left_1 = dock_container.find_child('DockVSplitLeftL', true, false)
	dock_left_2 = dock_container.find_child('DockVSplitLeftR', true, false)
	dock_right_1 = dock_container.find_child('DockVSplitRightL', true, false)
	dock_right_2 = dock_container.find_child('DockVSplitRightR', true, false)
	scene_tabs = EditorInterface.get_editor_main_screen().get_node('../..').get_child(0)
	
	add_tool_menu_item(MENU_NATIVE_API_NAME, HenApiGenerator._generate_native_api)

	main_screen_changed.connect(_on_change_main_screen)
	set_docks()

	add_autoload_singleton('HengoDebugger', 'res://addons/hengo/scripts/debug/hengo_debugger.gd')
	HenGlobal.HENGO_EDITOR_PLUGIN = self

	HenGlobal.cnode_pool.clear()
	HenGlobal.state_pool.clear()
	HenGlobal.connection_line_pool.clear()
	HenGlobal.flow_connection_line_pool.clear()
	HenGlobal.state_connection_line_pool.clear()

	# creating cnode pool
	HenCnode.instantiate_and_add_pool()

	# adding gdscript editor
	gd_previewer = (preload('res://addons/hengo/scenes/gd_editor.tscn') as PackedScene).instantiate()
	gd_previewer.code_completion_enabled = false
	gd_previewer.editable = false

	var highlighter: CodeHighlighter = gd_previewer.syntax_highlighter
	highlighter.clear_color_regions()
	highlighter.add_color_region('\"', '\"', Color('#9ece6a'))
	highlighter.add_color_region('#', '', Color('#565f89'), true)
	for kw in [
		"and", "as", "assert", "break", "class", "class_name", "continue", "extends",
		"elif", "else", "enum", "export", "for", "func", "if", "in", "is", "match",
		"not", "onready", "or", "pass", "return", "setget", "signal", "static", "tool",
		"var", "while", "yield"
	]:
		highlighter.add_keyword_color(kw, Color('#bb9af7'))

	add_control_to_bottom_panel(gd_previewer, 'Hengo Code')
	HenGlobal.GD_PREVIEWER = gd_previewer


func _get_window_layout(_configuration: ConfigFile) -> void:
	if main_scene.visible:
		hide_docks()
	else:
		set_docks()


func _on_change_main_screen(_name: String) -> void:
	if _name == PLUGIN_NAME:
		hide_docks()
		change_colors()
	else:
		show_docks()


func _exit_tree():
	HenGlobal.can_instantiate_pool = false
	
	remove_debugger_plugin(debug_plugin)
	remove_tool_menu_item(MENU_NATIVE_API_NAME)
	remove_control_from_bottom_panel(gd_previewer)

	# reseting file system tree signals
	for signal_config: Dictionary in file_tree_signals:
		file_system_tree.connect('item_activated', signal_config.callable)

	if main_scene:
		main_scene.queue_free()
	
	remove_autoload_singleton('HengoDebugger')
	HenGlobal.HENGO_EDITOR_PLUGIN = null
	print('Done')

func _make_visible(_visible: bool):
	if main_scene:
		if _visible: hide_docks()
		else: show_docks()

		main_scene.visible = _visible

func _get_plugin_name():
	return PLUGIN_NAME

func _has_main_screen() -> bool:
	return true

# public
#
func set_docks() -> void:
	docks_references = []

	# hiding left docks
	for dock in dock_left_1.get_children():
		docks_references.append({
			dock = dock,
			old_visibility = dock.visible
		})

	for dock in dock_left_2.get_children():
		docks_references.append({
			dock = dock,
			old_visibility = dock.visible
		})

	# hiding right docks
	for dock in dock_right_1.get_children():
		docks_references.append({
			dock = dock,
			old_visibility = dock.visible
		})
	
	for dock in dock_right_2.get_children():
		docks_references.append({
			dock = dock,
			old_visibility = dock.visible
		})

func hide_docks() -> void:
	scene_tabs.visible = false

	# hiding all docks
	for obj in docks_references:
		obj.dock.visible = false

func show_docks() -> void:
	if scene_tabs:
		scene_tabs.visible = true

	# backuping docks visibility
	for obj in docks_references:
		obj.dock.visible = obj.old_visibility
	

func change_colors() -> void:
	# colors
	var base_color: Color = EditorInterface.get_editor_settings().get_setting('interface/theme/base_color')
	var color_factor: float = .55
	var cnode_style_box: StyleBoxFlat = preload('res://addons/hengo/resources/style_box/cnode.tres')
	var event_style_box: StyleBoxFlat = preload('res://addons/hengo/resources/style_box/event.tres')

	HenGlobal.HENGO_ROOT.get_node('%MenuBar').get_theme_stylebox('panel').bg_color = base_color
	cnode_style_box.bg_color = base_color.lightened(.07)
	cnode_style_box.border_color = cnode_style_box.bg_color.darkened(.3)
	event_style_box.bg_color = base_color.lightened(.05)
	event_style_box.border_color = base_color.lightened(.2)
