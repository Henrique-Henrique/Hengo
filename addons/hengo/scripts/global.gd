@tool
class_name HenGlobal extends Node

# nodes referencs
static var CAM: HenCam
static var CNODE_CONTAINER: Control
static var COMMENT_CONTAINER: Control
static var SIDE_MENU_POPUP: PanelContainer
static var DROPDOWN_MENU: HenDropDownMenu
static var POPUP_CONTAINER: CanvasLayer
static var GENERAL_POPUP: PanelContainer
static var DOCS_TOOLTIP: HenDocsToolTip
static var ERROR_BT: HenErrorBt
static var CONNECTION_GUIDE: HenConnectionGuide
static var HENGO_ROOT: HenHengoRoot
static var GD_PREVIEWER: CodeEdit
static var DASHBOARD: HenDashboard
static var BASE_ROUTE: Dictionary
static var SIDE_BAR_LIST: HenSideBar.SideBarList
static var SIDE_BAR: HenSideBar
static var SIDE_BAR_LIST_CACHE: Dictionary = {}
static var TOOLTIP: HenTooltip
static var DOCKS: Dictionary = {}
static var ACTION_BAR: HenCNodeActionBar
static var FROM_REFERENCES: HenSideBarReferences

# cnodes
static var can_make_connection: bool = false
static var connection_to_data: Dictionary = {} # type, from, from_cn
static var can_make_flow_connection: bool = false
static var flow_connection_to_data: Dictionary = {}
static var flow_cnode_from: PanelContainer = null
static var connection_first_data: Dictionary = {}

# cam
static var mouse_on_cnode_ui: bool = false

# states
static var can_make_state_connection: bool = false
static var state_connection_to_date: Dictionary = {}

# history
static var history: UndoRedo

# cam
enum UI_STATE {
    ONLY_STATE,
    ONLY_CNODE,
    BOTH
}

static var ui_mode: UI_STATE = UI_STATE.BOTH

# name generator
static var unique_id: int = 0


class ScriptData:
    var id: int
    var path: StringName
    var type: StringName

# save load
static var current_script_path: StringName = ''
static var script_config: ScriptData
static var reparent_data: Dictionary = {}

# parser
static var SCRIPTS_INFO: Dictionary = {}
static var SCRIPTS_STATES: Dictionary = {}

# debug
static var node_references: Dictionary = {}
static var state_references: Dictionary = {}

# counter
static var node_counter: int = 0
static var prop_counter: int = 0

static func get_new_node_counter() -> int:
    node_counter += 1
    return node_counter

static func get_new_prop_counter() -> int:
    prop_counter += 1
    return prop_counter

# debug
static var HENGO_EDITOR_PLUGIN: HenHengo
static var HENGO_DEBUGGER_PLUGIN
const DEBUG_TOKEN: String = '#hen_dbg#'
const DEBUG_VAR_NAME: String = '__hen_id__'
static var current_script_debug_symbols: Dictionary = {}


# pool
static var cnode_pool: Array = []
static var state_pool: Array = []
static var connection_line_pool: Array = []
static var flow_connection_line_pool: Array = []
static var state_connection_line_pool: Array = []
# virtual state list
static var vs_list: Array = []
static var can_instantiate_pool: bool = true


# macro
static var USE_MACRO_USE_SELF: bool = false
static var MACRO_REF: HenCodeGeneration.CNode
static var USE_MACRO_REF: bool = false
static var MACRO_USE_SELF: bool = false