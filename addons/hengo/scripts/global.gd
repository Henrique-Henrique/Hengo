@tool
class_name HenGlobal extends Node

# nodes referencs
var SIDE_MENU_POPUP: PanelContainer
var HENGO_ROOT: HenHengoRoot
var SIDE_BAR: HenSideBar
var SIDE_PANEL: PanelContainer
var TOOLTIP: HenTooltip
var GENERATE_PREVIEW_CODE: bool = false
var SCRIPT_REF_CACHE: Dictionary = {}
var TABS: HenTabs
var DASHBOARD: HenDashboard
var SAVE_DATA: HenSaveData
# all scripts of the active collection kept in memory
var OPEN_SCRIPTS: Array[HenSaveData] = []
var ACTIVE_COLLECTION: HenSaveCollection
var CURRENT_INSPECTOR: HenInspector
# script id -> { origin: Vector2, zoom: float } of the flow canvas
var CAM_VIEWS: Dictionary = {}
# the definition stack the canvas is editing, empty while it draws the script.
# entries are { kind: StringName, id: StringName }, read through HenRoute
var ROUTE: Array[Dictionary] = []
# script id -> the route stack it had when its tab was left
var ROUTE_VIEWS: Dictionary = {}
# script the current stack belongs to, so leaving a tab knows where to park it
var ROUTE_OWNER: String = ''
var CODE_SEARCH: HenCodeSearch

# CONFIG
var SETTINGS: HenSettings = HenSettings.new()
var IS_HEADLESS: bool = false

# cnodes
var can_make_connection: bool = false
var can_make_flow_connection: bool = false
var flow_connection_to_data: Dictionary = {}
var flow_cnode_from: PanelContainer = null
var can_format_again: bool = true

# cam
var mouse_on_cnode_ui: bool = false

# states
var can_make_state_connection: bool = false
var state_connection_to_date: Dictionary = {}

# the stack ctrl+z drains: every view that edits a script records into it
var flow_history: HenFlowHistory = HenFlowHistory.new()

# cam
enum UI_STATE {
	ONLY_STATE,
	ONLY_CNODE,
	BOTH
}

var ui_mode: UI_STATE = UI_STATE.BOTH

# name generator
var unique_id: int = 0

# parser
var SCRIPTS_INFO: Dictionary = {}
var SCRIPTS_STATES: Dictionary = {}

# counter
var node_counter: int = 0

func get_new_node_counter() -> StringName:
	if not SAVE_DATA:
		return ""

	SAVE_DATA.counter += 1
	return StringName(str(SAVE_DATA.counter))


# debug
var HENGO_EDITOR_PLUGIN: HenHengo
var HENGO_DEBUGGER_PLUGIN
const DEBUG_TOKEN: String = '#hen_dbg#'
const DEBUG_VAR_NAME: String = '__hen_id__'
var current_script_debug_symbols: Dictionary = {}


# pool
var state_pool: Array = []
# skeleton placeholders shown at a vcnode's spot while it waits in
# pending_show_queue; grabbed on enqueue, released when show() runs
var placeholder_pool: Array = []
var placeholder_pool_free: Array = []
# vcnodes that crossed into the viewport with configure_cnode_to_show deferred;
# cam._process drains this under a per-frame usec budget
var pending_show_queue: Array = []
# virtual state list
var vs_list: Array = []
var can_instantiate_pool: bool = true


# macro
var USE_MACRO_USE_SELF: bool = false
var USE_MACRO_REF: bool = false
var MACRO_USE_SELF: bool = false
var script_macros: Array[HenSaveMacro] = []
# native action macros shipped with the plugin (res://addons/hengo/actions)
var action_macros: Array[HenSaveMacro] = []


# terminal
var terminal_content: String = ''

# clipboard for copy/paste
var clipboard: Dictionary = {}


func _ready() -> void:
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	signal_bus.set_terminal_text.connect(_on_terminal_msg)


func _on_terminal_msg(_msg: String) -> void:
	terminal_content += _msg
