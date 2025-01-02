@tool
extends HBoxContainer

const _Global = preload('res://addons/hengo/scripts/global.gd')


func _ready() -> void:
    $Left/DashBoard.pressed.connect(_on_dashboard)


func _on_dashboard() -> void:
    _Global.CNODE_CAM.can_scroll = false
    _Global.STATE_CAM.can_scroll = false

    _Global.DASHBOARD.show_dashboard(true)