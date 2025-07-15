@tool
class_name HenTooltip extends RichTextLabel

func go_to(_pos: Vector2, _content: String, _self_pos: Vector2 = Vector2.ZERO) -> void:
    if not visible:
        visible = true
        scale = Vector2.ZERO

        var tween: Tween = get_tree().create_tween()
        tween.tween_property(self, 'scale', Vector2.ONE, .1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

    if text == _content:
        global_position = _pos + (size * _self_pos)
        return

    text = _content
    reset_size()

    global_position = _pos + (size * _self_pos)


func close() -> void:
    text = ''
    visible = false