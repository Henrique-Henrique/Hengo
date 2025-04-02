@tool
class_name HenCNodeActionBar extends HBoxContainer


func _ready() -> void:
    $Left/DashBoard.pressed.connect(_on_dashboard)


func _on_dashboard() -> void:
    HenGlobal.CAM.can_scroll = false
    HenGlobal.DASHBOARD.show_dashboard(true)