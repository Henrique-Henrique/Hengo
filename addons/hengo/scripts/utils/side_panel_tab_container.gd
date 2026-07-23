@tool
extends TabContainer

const DEBUG_TAB_INDEX = 3

const CONFIG = {
    0: {
        title = 'Dashboard',
        icon = preload('res://addons/hengo/assets/new_icons/layout-dashboard.svg')
    },
    1: {
        title = 'Props',
        icon = preload('res://addons/hengo/assets/icons/settings.svg')
    },
    2: {
        title = 'Code Preview',
        icon = preload('res://addons/hengo/assets/icons/menu/text.svg')
    },
    3: {
        title = 'Debug',
        icon = preload('res://addons/hengo/assets/new_icons/bug.svg')
    },
    4: {
        title = 'Actions',
        icon = preload('res://addons/hengo/assets/new_icons/list-todo.svg')
    }
}


func _ready() -> void:
    for id in CONFIG:
        set_tab_title(id, CONFIG[id].title)
        set_tab_icon(id, CONFIG[id].icon)

    # debug tab is only visible while a debug session is running
    set_tab_hidden(DEBUG_TAB_INDEX, true)

    var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
    if signal_bus:
        signal_bus.debug_session_started.connect(_on_debug_started)
        signal_bus.debug_session_stopped.connect(_on_debug_stopped)


func _on_debug_started() -> void:
    set_tab_hidden(DEBUG_TAB_INDEX, false)
    current_tab = DEBUG_TAB_INDEX


func _on_debug_stopped() -> void:
    if current_tab == DEBUG_TAB_INDEX:
        current_tab = 0
    set_tab_hidden(DEBUG_TAB_INDEX, true)
