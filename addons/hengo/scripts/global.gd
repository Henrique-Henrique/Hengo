@tool
extends Node

# imports
const _Cam = preload('res://addons/hengo/scripts/cam.gd')
const _State = preload('res://addons/hengo/scripts/state.gd')
const _ConnectionGuide = preload('res://addons/hengo/scripts/connection_guide.gd')
const _Hengo = preload('res://addons/hengo/hengo.gd')
const _StateTransition = preload('res://addons/hengo/scripts/state_transition.gd')

# plugin
static var editor_interface: EditorInterface

# nodes referencs
static var CAM: _Cam
static var STATE_CAM: _Cam
static var CNODE_CAM: _Cam
static var CNODE_CONTAINER: Control
static var GENERAL_CONTAINER: Control
static var COMMENT_CONTAINER: Control
static var STATE_CONTAINER: Control
static var SIDE_BAR: PanelContainer
static var DROP_PROP_MENU: PopupMenu
static var SIDE_MENU_POPUP: PanelContainer
static var DROPDOWN_MENU: PanelContainer
static var POPUP_CONTAINER: CanvasLayer
static var LOCAL_VAR_SECTION
static var SIGNAL_SECTION
static var GENERAL_POPUP: PanelContainer
static var CODE_TOOLTIP: PanelContainer
static var ERROR_BT: Button
static var CONNECTION_GUIDE: _ConnectionGuide
static var STATE_CONNECTION_GUIDE: _ConnectionGuide

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
static var current_state_transition: _StateTransition

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

# code flow
static var start_state: _State

# save load
static var current_script_path: StringName = ''
static var script_config: Dictionary = {}
static var reparent_data: Dictionary = {}

# parser
static var SCRIPTS_INFO: Array = []
static var SCRIPTS_STATES: Dictionary = {}

# debug
static var node_references: Dictionary = {}
static var state_references: Dictionary = {}
static var old_state_debug: _State = null

# counter
static var node_counter: int = 0

static func get_new_node_counter() -> int:
    node_counter += 1

    return node_counter


# debug
static var HENGO_EDITOR_PLUGIN: _Hengo
static var HENGO_DEBUGGER_PLUGIN
const DEBUG_TOKEN: String = '#hen_dbg#'
const DEBUG_VAR_NAME: String = '__hen_id__'
static var current_script_debug_symbols: Dictionary = {}