@tool
class_name HenArrayItem extends HBoxContainer

var prop: HenPropEditor.Prop

func _ready() -> void:
    (get_node('%Options') as MenuButton).get_popup().id_pressed.connect(_on_item_config_select)


func _on_item_config_select(_id: int) -> void:
    match _id:
        # delete
        0:
            if prop.on_item_delete:
                prop.on_item_delete.call()
        # up
        1:
            if prop.on_item_move:
                prop.on_item_move.call(HenPropArray.ArrayMove.UP)
        # down
        2:
            if prop.on_item_move:
                prop.on_item_move.call(HenPropArray.ArrayMove.DOWN)
    
    HenPropEditor.get_singleton().start()


func start(_prop: HenPropEditor.Prop) -> HenArrayItem:
    prop = _prop
    return self