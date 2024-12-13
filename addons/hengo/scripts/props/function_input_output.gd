@tool
extends VBoxContainer

signal added_param
signal removed_param(idx: int)
signal type_changed
signal name_changed
signal moved_param

var f_name: String = ''
var f_type: String = ''

# private
#
func _ready() -> void:
    get_node('%Add').pressed.connect(_on_add)

func _on_add() -> void:
    _add()

func _add(_config: Dictionary = {}) -> void:
    var param = load('res://addons/hengo/scenes/function_param.tscn').instantiate()
    var name_node = param.get_node('%Name')

    name_node.text = _config.name if _config.has('name') else ''
    get_node('%ParamContainer').add_child(param)

    param.get_node('%TypePick').text = _config.type if _config.has('type') else 'Variant'

    # if has res that's mean that is default setting
    # if not _config.is_empty():
    #     name_node.connect('value_changed', _on_change_in_out_name.bind(_res))

    #     param.connect('move_up_pressed', _on_move_up_down.bind('up', param, _res))
    #     param.connect('move_down_pressed', _on_move_up_down.bind('down', param, _res))
    #     param.connect('removed_pressed', _on_remove_param.bind(param, _res))
    #     param.connect('type_changed', _on_type_change.bind(_res))
    #     emit_signal('added_param', _res)
    #     return

    # if is not default, so creating one res
    name_node.connect('value_changed', _on_change_in_out_name.bind(param.get_index()))

    param.connect('move_up_pressed', _on_move_up_down.bind('up', param))
    param.connect('move_down_pressed', _on_move_up_down.bind('down', param))
    param.connect('removed_pressed', _on_remove_param.bind(param))
    param.connect('type_changed', _on_type_change.bind(param.get_index()))

    emit_signal('added_param')


func _on_type_change(_value: String, _idx: int) -> void:
    f_type = _value
    emit_signal('type_changed', _value, _idx)


func _on_change_in_out_name(_name: String, _idx: int) -> void:
    f_name = _name
    emit_signal('name_changed', _name, _idx)


func _on_remove_param(_param) -> void:
    #TODO undo/redo
    emit_signal('removed_param', _param.get_index())
    get_node('%ParamContainer').remove_child(_param)


func _on_move_up_down(_type: String, _param) -> void:
    match _type:
        'up':
            get_node('%ParamContainer').move_child(_param, max(0, _param.get_index() - 1))
        'down':
            get_node('%ParamContainer').move_child(_param, _param.get_index() + 1)

    emit_signal('moved_param', _type)