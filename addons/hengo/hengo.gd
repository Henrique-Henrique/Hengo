@tool
class_name HenHengo extends EditorPlugin

const PLUGIN_NAME = 'Hengo'
const MENU_NATIVE_API_NAME = "Hengo Generate Native Api"

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
		# change_colors()


func _exit_tree():
	HenGlobal.can_instantiate_pool = false
	
	remove_debugger_plugin(debug_plugin)
	remove_tool_menu_item(MENU_NATIVE_API_NAME)
	remove_control_from_bottom_panel(gd_previewer)

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
	for dock: DockConfig in HenGlobal.DOCKS.values():
		dock.tab_control = dock.ref.get_current_tab_control()

func hide_docks() -> void:
	tab_visibility(false)

	for dock: DockConfig in HenGlobal.DOCKS.values():
		dock.ref.visible = false

func show_docks() -> void:
	tab_visibility(true)
	
	for dock: DockConfig in HenGlobal.DOCKS.values():
		if dock.tab_control:
			dock.ref.visible = true
			dock.tab_control.visible = true

func tab_visibility(_show: bool) -> void:
	var tabs_container = EditorInterface.get_editor_main_screen().get_node_or_null('../..')
	
	if tabs_container:
		var tab = tabs_container.get_child(0) if tabs_container.get_child_count() > 0 else null

		if tab: tab.visible = _show
