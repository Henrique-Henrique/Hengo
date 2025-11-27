@tool
class_name HenCreateScript extends VBoxContainer

@onready var script_name_input: LineEdit = %ScriptName
@onready var create_bt: Button = %CreateBt
@onready var create_and_open_bt: Button = %CreateOpen
@onready var extend_bt: HenDropdown = %ExtendBt


func _ready() -> void:
    create_bt.pressed.connect(_on_create)
    create_and_open_bt.pressed.connect(_on_create.bind(true))


func _on_create(_open: bool = false) -> void:
    var text: String = script_name_input.text

    if text.is_empty():
        return
    
    var script_name: String = text.to_snake_case().get_basename()
    var _class: StringName = extend_bt.text if ClassDB.class_exists(extend_bt.text) else 'Node'
    var error: int = create_script(script_name, get_script_content(_class))
    
    if error != OK:
        return

    if _open:
        var loader: HenLoader = Engine.get_singleton(&'Loader')
        loader.load(HenEnums.HENGO_PATH.path_join(script_name).path_join('.gd'))
    else:
        var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
        signal_bus.request_list_update.emit()

    (Engine.get_singleton(&'Global') as HenGlobal).GENERAL_POPUP.hide_popup()


func get_script_content(_class: StringName) -> String:
    return 'extends ' + _class


func get_save_content(_script_path: StringName, _id: int) -> HenSaveData:
    var save_data: HenSaveData = HenSaveData.new()
    var _class: StringName = extend_bt.text if ClassDB.class_exists(extend_bt.text) else 'Node'

    save_data.id = str(_id)
    save_data.counter = 1
    save_data.type = _class
    save_data.virtual_cnode_list.append(
        {
            can_delete = false,
            id = 1,
            name = 'Stat State',
            position = 'Vector2(0, 0)',
            size = 'Vector2(99, 63)',
            sub_type = 37,
            type = 6
        }
    )
    
    return save_data


func create_script(path: String, content: String):
    var id: int = ResourceUID.create_id()
    var id_path: StringName = HenEnums.HENGO_SAVE_PATH.path_join(str(id))
    var res: HenSaveData = get_save_content(id_path, id)

    # var id: int = ResourceUID.create_id_for_path(id_path)
    # ResourceUID.add_id(id, id_path)
    # var res: HenSaveData = get_save_content(id_path, id)
    # if not DirAccess.dir_exists_absolute(id_path):
    #     DirAccess.make_dir_absolute(id_path)
    # ResourceSaver.save(res, id_path.path_join('save.tres'))
    # EditorInterface.get_resource_filesystem().scan()
    # var script = GDScript.new()
    # script.source_code = content
    # var new_path: StringName = HenEnums.HENGO_PATH.path_join(path + '.gd')
    # var result = ResourceSaver.save(script, new_path)
    # if result == OK:
    #     ResourceUID.add_id(id, new_path)
    #     var res: HenSaveData = get_save_content(new_path, id)
    #     var id_path: StringName = HenEnums.HENGO_SAVE_PATH.path_join(str(id))
    #     if not DirAccess.dir_exists_absolute(id_path):
    #         DirAccess.make_dir_absolute(id_path)
    #     ResourceSaver.save(res, id_path.path_join('save.tres'))
    #     EditorInterface.get_resource_filesystem().scan()
    # else:
    #     print('Error saving script: ', result)
    return 0