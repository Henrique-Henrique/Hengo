@tool
class_name HenPropArray extends VBoxContainer


enum ArrayMove {UP, DOWN, DELETE}

signal value_changed

var array_ref: Array
var inspector: HenInspector
var field: Dictionary
var item_create_callback: Callable
var item_move_callback: Callable
var item_delete_callback: Callable

func _ready() -> void:
    (get_node('%Add') as Button).pressed.connect(_add)


func _add() -> void:
    item_create_callback.call()
    create_inspector(inspector)
    value_changed.emit(null)


func on_item_delete(_ref) -> void:
    #TODO make undo redo with callbacks like the item creation
    array_ref.erase(_ref)
    if item_delete_callback: item_delete_callback.call(_ref)

    create_inspector(inspector)
    value_changed.emit(null)


func on_item_move(_direction: ArrayMove, _ref) -> void:
    var can_move: bool = false


    match _direction:
        ArrayMove.UP:
            can_move = HenUtils.move_array_item(array_ref, _ref, 1)
        ArrayMove.DOWN:
            can_move = HenUtils.move_array_item(array_ref, _ref, -1)
    
    if not can_move: return
    if item_move_callback: item_move_callback.call(_ref)

    create_inspector(inspector)
    value_changed.emit(null)


func start(_field: Dictionary, _arr: Array, _item_create_callback: Callable, _item_move_callback: Callable, _item_delete_callback: Callable) -> void:
    field = _field
    array_ref = _arr
    item_create_callback = _item_create_callback
    item_move_callback = _item_move_callback
    item_delete_callback = _item_delete_callback

    create_inspector()

    inspector.item_changed.connect(on_value_changed)

    get_node('%Container').add_child(inspector)


func on_value_changed(_name: StringName, _ref, _inspector: HenInspector) -> void:
    value_changed.emit(null)


func create_inspector(_inspector: HenInspector = null) -> void:
    var items: Array = []

    for item_data in array_ref:
        items.append(HenInspector.InspectorItem.new({
            name = field.name,
            type = field.type,
            value = item_data.name,
            ref = item_data,
            prop_array_ref = self
        }))

    inspector = HenInspector.start(items, _inspector)