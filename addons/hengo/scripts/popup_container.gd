@tool
class_name HenPopupContainer extends CanvasLayer

signal closed

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
    for node in container.get_children():
        container.remove_child(node)
        node.queue_free()

# public
func show_content(_content: Control, _name: String, _pos: Vector2 = Vector2.INF, _lod: float = 1) -> HenPopupContainer:
    var gp: PanelContainer = get_node('%GeneralPopUp')
    var container = gp.get_child(0)
    var global: HenGlobal = Engine.get_singleton(&'Global')

    clean()
    
    container.add_child(_content)
    
    # HenUtils.reposition_control_inside(gp)

    if _lod > 0:
        (get_node('%Background') as Panel).modulate = Color.WHITE
        # ((get_node('%Background') as Panel).material as ShaderMaterial).set_shader_parameter('lod', _lod)
    else:
        (get_node('%Background') as Panel).modulate = Color.TRANSPARENT

    show()

    gp.pivot_offset = gp.size / 2.0
    var tween: Tween = get_tree().create_tween()

    gp.scale = Vector2(.95, .95)
    gp.modulate.a = 0.0 # Começa invisível

    tween.set_parallel(true)
    tween.tween_property(gp, 'scale', Vector2.ONE, .4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    tween.tween_property(gp, 'modulate:a', 1.0, .4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    
    global.CAM.can_scroll = false

    return self


func move(_pos: Vector2) -> void:
    var gp = get_node('%GeneralPopUp')
    gp.position += _pos
    HenUtils.reposition_control_inside(gp)


func reset_size() -> void:
    var gp = get_node('%GeneralPopUp')
    gp.reset_size()


func show_container() -> void:
    (Engine.get_singleton(&'Global') as HenGlobal).CAM.can_scroll = false
    show()


func hide_popup() -> void:
    (Engine.get_singleton(&'Global') as HenGlobal).CAM.can_scroll = true
    hide()
    closed.emit()