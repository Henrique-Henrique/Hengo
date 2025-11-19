@tool
class_name HenCreateScript extends VBoxContainer

const HENGO_PATH: StringName = 'res://hengo/'
const HENGO_SAVE_PATH: StringName = 'res://hengo/save/'

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
        loader.load(HENGO_PATH + script_name + '.gd')
    else:
        var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
        signal_bus.request_list_update.emit()

    (Engine.get_singleton(&'Global') as HenGlobal).GENERAL_POPUP.hide_popup()


func get_script_content(_class: StringName) -> String:
    return 'extends ' + _class


func get_save_content(_script_path: StringName) -> HenScriptData:
    var script_data: HenScriptData = HenScriptData.new()
    var _class: StringName = extend_bt.text if ClassDB.class_exists(extend_bt.text) else 'Node'

    script_data.side_bar_list = HenSideBarList.new().get_save(script_data)
    script_data.node_counter = 1
    script_data.type = _class
    script_data.virtual_cnode_list.append(
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
    
    return script_data


func create_script(path: String, content: String):
    var script = GDScript.new()
    script.source_code = content
    
    var new_path: StringName = HENGO_PATH + path + '.gd'

    var error = ResourceSaver.save(script, new_path)
    if error == OK:
        print('Script saved successfully at: ', new_path)
        var id: int = ResourceSaver.get_resource_id_for_path(new_path)
        HenScriptData.save(get_save_content(new_path), HENGO_SAVE_PATH + str(id) + '.hengo')
        EditorInterface.get_resource_filesystem().scan()
    else:
        print('Error saving script: ', error)
    
    return error