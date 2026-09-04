@tool
class_name HenDropDownMenu extends PanelContainer

var list_container: ItemList
var search_bar: LineEdit
var list: Array = []
var search_list: Array = []
var type: String = ''

var select_callable


func _ready() -> void:
    _ensure_refs()


func _on_item_click(_index: int, _pos: Vector2, _mouse_index: int) -> void:
    if not _mouse_index == MOUSE_BUTTON_LEFT:
        return

    _pick(_index)


# a callback that opens a popup has to defer it, the hide below closes the topmost
func _pick(_index: int) -> void:
    if not select_callable is Callable or _index < 0 or _index >= search_list.size():
        return

    (select_callable as Callable).call(search_list[_index])
    select_callable = null
    (Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).hide_popup()


# typing filters, so enter takes the top match and down hands the list the arrows
func _on_search_input(_event: InputEvent) -> void:
    var key := _event as InputEventKey

    if not key or not key.pressed or search_list.is_empty():
        return

    match key.keycode:
        KEY_ENTER, KEY_KP_ENTER:
            search_bar.accept_event()

            # enter takes what the typing narrowed down to; with no query the top row
            # is whatever the list opened with, and a bind picker opens on "None"
            if not search_bar.text.strip_edges().is_empty():
                _pick(0)
        KEY_DOWN:
            search_bar.accept_event()
            list_container.select(0)
            list_container.grab_focus()


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
    if not list_container:
        return

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
    _ensure_refs()
    if not search_bar:
        push_error('DropDownMenu is missing %SearchBar node.')
        return

    search_bar.text = ''

    list = _list
    search_list = list
    select_callable = _call
    type = _type
    _remount()
    # deferred because the popup places itself deferred too, and focus taken on the
    # frame the container jumps is dropped
    search_bar.grab_focus.call_deferred()


func _ensure_refs() -> void:
    if not search_bar:
        search_bar = get_node_or_null('%SearchBar') as LineEdit
        if search_bar and not search_bar.text_changed.is_connected(_on_search):
            search_bar.text_changed.connect(_on_search)
            search_bar.gui_input.connect(_on_search_input)

    if not list_container:
        list_container = get_node_or_null('%List') as ItemList
        if list_container and not list_container.item_clicked.is_connected(_on_item_click):
            list_container.item_clicked.connect(_on_item_click)
            list_container.item_activated.connect(_pick)
