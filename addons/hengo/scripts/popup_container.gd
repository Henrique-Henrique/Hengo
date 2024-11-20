@tool
extends CanvasLayer

func _ready() -> void:
    get_child(0).gui_input.connect(_on_gui)

func _on_gui(_event: InputEvent) -> void:
    if _event is InputEventMouseButton:
        if _event.pressed:
            if _event.button_index == MOUSE_BUTTON_LEFT or _event.button_index == MOUSE_BUTTON_RIGHT:
                hide()

# public
func show_content(_content: Node, _name: String, _pos: Vector2 = Vector2.INF) -> void:
    var gp = get_node('%GeneralPopUp')
    var container = gp.get_child(0)

    # cleaning other controls of popup
    for node in container.get_children().slice(1):
        container.remove_child(node)
        node.queue_free()
    
    container.add_child(_content)
    container.get_child(0).text = _name
    
    if _pos == Vector2.INF:
        # center
        gp.position = (get_window().size / 2) - (Vector2i(_content.size) / 2)
    else:
        gp.position = _pos
    
    gp.size = Vector2.ZERO
    show()