@tool
extends TabContainer

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
    }
}


func _ready() -> void:
    for id in CONFIG:
        set_tab_title(id, CONFIG[id].title)
        set_tab_icon(id, CONFIG[id].icon)