@tool
class_name HenCNodeActionBar extends HBoxContainer

@export var dashboard: Button

func _ready() -> void:
    dashboard.pressed.connect(_on_dashboard)


func _on_dashboard() -> void:
    HenGlobal.CAM.can_scroll = false

    var dashboard_scene: HenDashboard = preload('res://addons/hengo/scenes/dashboard.tscn').instantiate()

    HenGlobal.GENERAL_POPUP.get_parent().show_content(
        dashboard_scene,
        'Dashboard',
        dashboard.global_position
    )