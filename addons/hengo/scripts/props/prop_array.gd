@tool
extends VBoxContainer

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


func start(_field: Dictionary, _arr: Array, _item_create_callback: Callable) -> void:
    field = _field
    array_ref = _arr
    item_create_callback = _item_create_callback

    create_inspector()

    inspector.item_changed.connect(on_value_changed)

    get_node('Container').add_child(inspector)


func on_value_changed() -> void:
    value_changed.emit(null)


func create_inspector(_inspector: HenInspector = null) -> void:
    var items: Array = []

    for item_data in array_ref:
        items.append(HenInspector.InspectorItem.new({
            name = field.name,
            type = field.type,
            value = item_data.name,
            ref = item_data
        }))

    inspector = HenInspector.start(items, _inspector)