@tool
class_name HenPropArrayItem extends PanelContainer

enum ArrayMove {UP, DOWN}

var prop: HenPropEditor.Prop

func _ready() -> void:
    %Add.pressed.connect(_on_add)


func _on_add() -> void:
    if prop.on_item_create:
        prop.on_item_create.call()
        HenPropEditor.get_singleton().start()


func start(_prop: HenPropEditor.Prop) -> HenPropArrayItem:
    prop = _prop
    return self