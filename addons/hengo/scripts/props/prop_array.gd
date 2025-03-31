@tool
class_name HenPropArray extends VBoxContainer


enum ArrayMove {UP, DOWN, DELETE}

signal value_changed

var array_ref: Array
var inspector: HenInspector
var field: Dictionary
var item_create_callback: Callable

func _ready() -> void:
    (get_node('%Add') as Button).pressed.connect(_add)


func _add() -> void:
    item_create_callback.call()
    create_inspector(inspector)
    value_changed.emit(null)


func on_item_delete(_ref) -> void:
    #TODO make undo redo with callbacks like the item creation
    array_ref.erase(_ref)
    create_inspector(inspector)
    value_changed.emit(null)


func on_item_move(_direction: ArrayMove, _ref) -> void:
    match _direction:
        ArrayMove.UP:
            _move_item(_ref, 1)
        ArrayMove.DOWN:
            _move_item(_ref, -1)
    
    create_inspector(inspector)
    value_changed.emit(null)


func _move_item(_ref, _factor: int) -> void:
    var target_idx: int = array_ref.find(_ref) - _factor
    var can_move: bool = false

    match _factor:
        1:
            can_move = target_idx >= 0
        (-1):
            can_move = target_idx < array_ref.size()

    if can_move:
        var value_to_change = array_ref[target_idx]
        array_ref[target_idx] = _ref
        array_ref[target_idx + _factor] = value_to_change


func start(_field: Dictionary, _arr: Array, _item_create_callback: Callable) -> void:
    field = _field
    array_ref = _arr
    item_create_callback = _item_create_callback

    create_inspector()

    inspector.item_changed.connect(on_value_changed)

    get_node('%Container').add_child(inspector)


func on_value_changed() -> void:
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