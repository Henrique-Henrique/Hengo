@tool
extends HBoxContainer

const Global = preload('res://addons/hengo/scripts/global.gd')
const SaveLoad = preload('res://addons/hengo/scripts/save_load.gd')
const Enums = preload('res://addons/hengo/references/enums.gd')

func _ready() -> void:
    get_node('Right/Open').pressed.connect(_on_open_press)
    get_node('Right/Create').pressed.connect(_on_create_press)


func _on_create_press() -> void:
    var script_dialog: ScriptCreateDialog = ScriptCreateDialog.new()
    script_dialog.script_created.connect(_on_script_created.bind(script_dialog))
    script_dialog.config('Node', 'res://hengo/', false, false)

    add_child(script_dialog)

    script_dialog.popup_centered()


func _on_script_created(_script: Script, _dialog: ScriptCreateDialog) -> void:
    _dialog.queue_free()


func _on_open_press() -> void:
    var list: ItemList = ItemList.new()

    list.size_flags_vertical = Control.SIZE_EXPAND
    list.custom_minimum_size = Vector2(300, 500)

    # parsing scripts
    var script_paths: Array[Array] = get_script_list(DirAccess.open('res://hengo'))
    var script_id_path: Array = []

    for arr: Array in script_paths:
        if arr[2] == '':
            arr[2] = 'Variant'
        
        # TODO make general icons endpoint
        var icon_path: String = 'res://addons/hengo/assets/.editor_icons/' + arr[2] + '.svg'

        var icon: Image = Image.load_from_file(icon_path)
        list.add_item(arr[0], ImageTexture.create_from_image(icon))
        
        script_id_path.append(arr[1])

    Global.GENERAL_POPUP.get_parent().show_content(list, 'Open Script', get_node('Right/Open').global_position)
    Global.GENERAL_POPUP.size.y = 200

    list.item_selected.connect(_on_script_list_selected.bind(script_id_path))


func _on_script_list_selected(_id: int, _path_arr: Array) -> void:
    print(_path_arr[_id])
    SaveLoad.load_and_edit(_path_arr[_id])
    Global.GENERAL_POPUP.get_parent().hide()


func get_script_list(_dir: DirAccess, _list: Array[Array] = []) -> Array[Array]: # [name, path, type]
    # parsing scripts
    _dir.list_dir_begin()

    var file_name: String = _dir.get_next()

    # TODO cache script that don't changed
    while file_name != '':
        if _dir.current_is_dir():
            get_script_list(DirAccess.open('res://hengo/' + file_name), _list)
        else:
            var script: GDScript = ResourceLoader.load(_dir.get_current_dir() + '/' + file_name, '', ResourceLoader.CACHE_MODE_IGNORE)

            if script.source_code.begins_with('#[hengo] '):
                var data: Dictionary = SaveLoad.parse_hengo_json(script.source_code)

                _list.append([file_name.get_basename(), _dir.get_current_dir() + '/' + file_name, data.type])
            else:
                _list.append([file_name.get_basename(), _dir.get_current_dir() + '/' + file_name, ''])
        
        file_name = _dir.get_next()

    _dir.list_dir_end()

    return _list