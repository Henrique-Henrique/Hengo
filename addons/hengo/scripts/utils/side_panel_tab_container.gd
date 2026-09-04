@tool
extends TabContainer

const DEBUG_TAB_INDEX = 2

const CONFIG = {
    0: {
        title = 'Dashboard',
        icon = preload('res://addons/hengo/assets/new_icons/layout-dashboard.svg'),
        button = '%DashboardIconBt'
    },
    1: {
        title = 'Props',
        icon = preload('res://addons/hengo/assets/icons/settings.svg'),
        button = '%PropsIconBt'
    },
    2: {
        title = 'Debug',
        icon = preload('res://addons/hengo/assets/new_icons/bug.svg'),
        button = '%DebugIconBt'
    }
}


var _tab_before_debug: int = 1


func _ready() -> void:
    for id in CONFIG:
        set_tab_title(id, CONFIG[id].title)
        set_tab_icon(id, CONFIG[id].icon)

    # debug tab is only visible while a debug session is running
    set_tab_hidden(DEBUG_TAB_INDEX, true)
    _setup_tab_buttons()

    tab_changed.connect(_on_tab_changed)

    var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
    if signal_bus:
        signal_bus.debug_session_started.connect(_on_debug_started)
        signal_bus.debug_session_stopped.connect(_on_debug_stopped)


func _on_debug_started() -> void:
    if current_tab != DEBUG_TAB_INDEX:
        _tab_before_debug = current_tab

    set_tab_hidden(DEBUG_TAB_INDEX, false)
    _set_tab_button_visible(DEBUG_TAB_INDEX, true)
    current_tab = DEBUG_TAB_INDEX
    _sync_tab_buttons()


func _on_debug_stopped() -> void:
    if current_tab == DEBUG_TAB_INDEX:
        current_tab = _tab_before_debug
    set_tab_hidden(DEBUG_TAB_INDEX, true)
    _set_tab_button_visible(DEBUG_TAB_INDEX, false)
    _sync_tab_buttons()


func _on_tab_changed(_idx: int) -> void:
    _sync_tab_buttons()


func _setup_tab_buttons() -> void:
    for id: int in CONFIG:
        var bt: Button = _get_tab_button(id)
        if bt:
            bt.tooltip_text = CONFIG[id].title
            bt.pressed.connect(_on_tab_button_pressed.bind(id))

    _sync_tab_buttons()


func _on_tab_button_pressed(id: int) -> void:
    if is_tab_disabled(id):
        _sync_tab_buttons()
        return

    var global: HenGlobal = Engine.get_singleton(&'Global')
    if global and global.HENGO_ROOT:
        global.HENGO_ROOT.expand_sidebar()

    current_tab = id
    _sync_tab_buttons()


func _sync_tab_buttons() -> void:
    for id: int in CONFIG:
        var bt: Button = _get_tab_button(id)
        if bt:
            bt.set_pressed_no_signal(id == current_tab)


func _set_tab_button_visible(id: int, is_visible: bool) -> void:
    var bt: Button = _get_tab_button(id)
    if bt:
        bt.visible = is_visible


func _get_tab_button(id: int) -> Button:
    return get_node_or_null(CONFIG[id].button) as Button
