@tool
extends PanelContainer

var list_container: ItemList
var search_bar: LineEdit
var list: Array = []
var search_list: Array = []
var type: String = ''

var select_callable


func _ready() -> void:
    search_bar = (get_node('%SearchBar') as LineEdit)

    search_bar.text_changed.connect(_on_search)
    list_container = get_node('%List')
    list_container.item_clicked.connect(_on_item_click)


func _on_item_click(_index: int, _pos: Vector2, _mouse_index: int) -> void:
    if not _mouse_index == MOUSE_BUTTON_LEFT:
        return

    (select_callable as Callable).call(search_list[_index])
    select_callable = null
    get_parent().hide()


func _on_search(_text: String) -> void:
    if _text.is_empty():
        search_list = list
        _remount()
        return

    var names = list.map(func(x: Dictionary): return (x.name as String).to_lower())
    var search = _text.to_lower()
    search_list = []
    
    var id = 0
    for name in names:
        if name.contains(search):
            search_list.append(list[id])
        id += 1

    _remount()


func _remount() -> void:
    list_container.clear()

    match type:
        'item_type':
            for obj: Dictionary in search_list:
                # TODO show icons
                list_container.add_item(obj.name)
        _:
            for obj: Dictionary in search_list:
                list_container.add_item(obj.name, load(obj.icon) if obj.has('icon') else null)


# public
func mount(_list: Array, _call: Callable, _type: String) -> void:
    search_bar.text = ''

    list = _list
    search_list = list
    select_callable = _call
    type = _type
    _remount()
