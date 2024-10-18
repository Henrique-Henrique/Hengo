@tool
extends VBoxContainer

signal added_param
signal removed_param
signal moved_param
signal type_changed

# private
#
func _ready() -> void:
    get_node('%Add').pressed.connect(_on_add)

func _on_add() -> void:
    _add()

func _add(_res: Resource=null) -> void:
    var param = load('res://addons/hengo/scenes/function_param.tscn').instantiate()
    var name_node = param.get_node('%Name')

    name_node.text = _res.name if _res else ''
    get_node('%ParamContainer').add_child(param)

    param.get_node('%TypePick').text = _res.type if _res else 'Variant'

    # if has res that's mean that is default setting
    if _res:
        name_node.connect('value_changed', _on_change_in_out_name.bind(_res))

        param.connect('move_up_pressed', _on_move_up_down.bind('up', param, _res))
        param.connect('move_down_pressed', _on_move_up_down.bind('down', param, _res))
        param.connect('removed_pressed', _on_remove_param.bind(param, _res))
        param.connect('type_changed', _on_type_change.bind(_res))
        emit_signal('added_param', _res)
        return

    # if is not default, so creating one res
    var res = load('res://addons/hengo/resources/cnode_function_in_out.tres').duplicate()
    name_node.connect('value_changed', _on_change_in_out_name.bind(res))

    param.connect('move_up_pressed', _on_move_up_down.bind('up', param, res))
    param.connect('move_down_pressed', _on_move_up_down.bind('down', param, res))
    param.connect('removed_pressed', _on_remove_param.bind(param, res))
    param.connect('type_changed', _on_type_change.bind(res))
    emit_signal('added_param', res)

func _on_type_change(_value: String, _res: Resource) -> void:
    _res.type = _value

func _on_change_in_out_name(_name: String, _res: Resource) -> void:
    _res.name = _name

func _on_remove_param(_param, _res: Resource) -> void:
    #TODO undo/redo
    get_node('%ParamContainer').remove_child(_param)
    emit_signal('removed_param', _res)

func _on_move_up_down(_type: String, _param, _res: Resource) -> void:
    match _type:
        'up':
            get_node('%ParamContainer').move_child(_param, max(0, _param.get_index() - 1))
        'down':
            get_node('%ParamContainer').move_child(_param, _param.get_index() + 1)

    emit_signal('moved_param', _res, _type)

# public
#
func set_default(_params: Array) -> void:
    for param in _params:
        var res = param.get('res')
        _add(res)