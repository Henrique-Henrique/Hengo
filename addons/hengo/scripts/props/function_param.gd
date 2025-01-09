@tool
extends HBoxContainer


enum {
    DELETE,
    MOVE_UP,
    MOVE_DOWN
}

@warning_ignore('unused_signal')
signal removed_pressed
@warning_ignore('unused_signal')
signal move_up_pressed
@warning_ignore('unused_signal')
signal move_down_pressed
@warning_ignore('unused_signal')
signal type_changed


# private
#
func _ready() -> void:
    get_node('%MenuButton').get_popup().id_pressed.connect(_on_id_pressed)
    var type_picker = get_node('%TypePick')
    type_picker.options = HenEnums.DROPDOWN_ALL_CLASSES
    type_picker.connect('value_changed', _on_type_change)


func _on_type_change(_value: String):
    emit_signal('type_changed', _value)


func _on_id_pressed(_id: int) -> void:
    match _id:
        DELETE:
            emit_signal('removed_pressed')
        MOVE_UP:
            emit_signal('move_up_pressed')
        MOVE_DOWN:
            emit_signal('move_down_pressed')
