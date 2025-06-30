@tool
class_name HenPopupContainer extends CanvasLayer


func _ready() -> void:
    get_child(0).gui_input.connect(_on_gui)

func _on_gui(_event: InputEvent) -> void:
    if _event is InputEventMouseButton:
        if _event.pressed:
            if _event.button_index == MOUSE_BUTTON_LEFT or _event.button_index == MOUSE_BUTTON_RIGHT:
                hide_popup()

func clean() -> void:
    var container = get_node('%GeneralPopUp').get_child(0)
    # cleaning other controls of popup
    for node in container.get_children().slice(1):
        container.remove_child(node)
        node.queue_free()

# public
func show_content(_content: Node, _name: String, _pos: Vector2 = Vector2.INF, _lod: float = 0.8) -> void:
    var gp = get_node('%GeneralPopUp')
    var container = gp.get_child(0)

    clean()
    
    container.add_child(_content)
    container.get_child(0).text = _name
    
    if _pos == Vector2.INF:
        # center
        gp.position = (get_window().size / 2) - (Vector2i(_content.size) / 2)
    else:
        gp.position = _pos
    
    gp.reset_size()

    HenUtils.reposition_control_inside(gp)

    if _lod > 0:
        (get_node('%Background') as Panel).modulate = Color.WHITE
        ((get_node('%Background') as Panel).material as ShaderMaterial).set_shader_parameter('lod', _lod)
    else:
        (get_node('%Background') as Panel).modulate = Color.TRANSPARENT

    show()

    # animations
    var tween: Tween = get_tree().create_tween()

    gp.scale = Vector2(.95, .95)
    tween.tween_property(gp, 'scale', Vector2.ONE, .5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
    HenGlobal.CAM.can_scroll = false


func reset_size() -> void:
    var gp = get_node('%GeneralPopUp')
    gp.reset_size()


func show_container() -> void:
    HenGlobal.CAM.can_scroll = false
    show()


func hide_popup() -> void:
    HenGlobal.CAM.can_scroll = true
    hide()