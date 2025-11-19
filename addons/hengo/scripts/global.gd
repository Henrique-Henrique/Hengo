@tool
class_name HenGlobal extends Node

# nodes referencs
var CAM: HenCam
var CNODE_CONTAINER: Control
var COMMENT_CONTAINER: Control
var SIDE_MENU_POPUP: PanelContainer
var DROPDOWN_MENU: HenDropDownMenu
var POPUP_CONTAINER: CanvasLayer
var GENERAL_POPUP: HenPopupContainer
var DOCS_TOOLTIP: HenDocsToolTip
var ERROR_BT: HenErrorBt
var CONNECTION_GUIDE: HenConnectionGuide
var HENGO_ROOT: HenHengoRoot
var BASE_ROUTE: HenRouteData
var SIDE_BAR_LIST: HenSideBarList
var SIDE_BAR: HenSideBar
var SIDE_PANEL: PanelContainer
var SIDE_BAR_LIST_CACHE: Dictionary = {}
var TOOLTIP: HenTooltip
var DOCKS: Dictionary = {}
var ACTION_BAR: HenCNodeActionBar
var CODE_PREVIEWER: HenCodePreview
var GENERATE_PREVIEW_CODE: bool = false
var SCRIPT_REF_CACHE: Dictionary = {}
var TABS: HenTabs
var BASE_ROUTE_REF: HenLoader.BaseRouteRef
var SELECTED_VIRTUAL_CNODE: Array[HenVirtualCNode]
var CNODE_UI: Panel
var DASHBOARD: HenDashboard

# cnodes
var can_make_connection: bool = false
var connection_to_data: HenVCInOutData.CNodeInOutConnectionData
var can_make_flow_connection: bool = false
var flow_connection_to_data: Dictionary = {}
var flow_cnode_from: PanelContainer = null
var can_format_again: bool = true

# cam
var mouse_on_cnode_ui: bool = false

# states
var can_make_state_connection: bool = false
var state_connection_to_date: Dictionary = {}

# history
var history: UndoRedo

# cam
enum UI_STATE {
    ONLY_STATE,
    ONLY_CNODE,
    BOTH
}

var ui_mode: UI_STATE = UI_STATE.BOTH

# name generator
var unique_id: int = 0


class ScriptData:
    var id: int
    var path: StringName
    var type: StringName

# save load
var current_script_path: StringName = ''
var script_config: ScriptData

# parser
var SCRIPTS_INFO: Dictionary = {}
var SCRIPTS_STATES: Dictionary = {}

# debug
var node_references: Dictionary = {}
var state_references: Dictionary = {}

# counter
var node_counter: int = 0

func get_new_node_counter() -> int:
    node_counter += 1
    return node_counter


# debug
var HENGO_EDITOR_PLUGIN: HenHengo
var HENGO_DEBUGGER_PLUGIN
const DEBUG_TOKEN: String = '#hen_dbg#'
const DEBUG_VAR_NAME: String = '__hen_id__'
var current_script_debug_symbols: Dictionary = {}


# pool
var cnode_pool: Array = []
var state_pool: Array = []
var connection_line_pool: Array = []
var flow_connection_line_pool: Array = []
var state_connection_line_pool: Array = []
# virtual state list
var vs_list: Array = []
var can_instantiate_pool: bool = true


# macro
var USE_MACRO_USE_SELF: bool = false
var MACRO_REF: HenTypeCnode
var USE_MACRO_REF: bool = false
var MACRO_USE_SELF: bool = false
