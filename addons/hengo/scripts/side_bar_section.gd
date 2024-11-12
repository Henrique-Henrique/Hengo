@tool
extends PanelContainer

# imports
const _Assets = preload('res://addons/hengo/scripts/assets.gd')
const _Enums = preload('res://addons/hengo/references/enums.gd')
const _Router = preload('res://addons/hengo/scripts/router.gd')
const _Global = preload('res://addons/hengo/scripts/global.gd')
const _SideBarSectionItem = preload('res://addons/hengo/scripts/side_bar_section_item.gd')

enum Types {
    NONE,
    PROP_VAR,
    PROP_FUNCTION,
    STATE_SIGNAL,
    LOCAL_VAR
}

@export var type: Types = Types.NONE
@export var base_name: String = 'item'

var name_count: String = ''
# only used on local variable
var local_vars: Dictionary = {}


func _ready() -> void:
    gui_input.connect(_on_gui)

    if type == Types.STATE_SIGNAL:
        var add_button = get_node('%Add')
    
        add_button.pressed.connect(_on_signal_add_pressed.bind(add_button))
    else:
        get_node('%Add').pressed.connect(_on_add)


func _on_signal_add_pressed(bt: Button) -> void:
    var container = _Global.GENERAL_POPUP.get_child(0)

    # cleaning other controls of popup
    for node in container.get_children().slice(1):
        container.remove_child(node)
        node.queue_free()

    var popup_signal = load('res://addons/hengo/scenes/utils/popup_signal.tscn').instantiate()

    _Global.GENERAL_POPUP.get_child(0).add_child(popup_signal)
    _Global.GENERAL_POPUP.get_child(0).get_child(0).text = 'Create Signal'
    _Global.GENERAL_POPUP.get_parent().show()

    _Global.GENERAL_POPUP.size = Vector2.ZERO
    _Global.GENERAL_POPUP.global_position = bt.global_position - Vector2(_Global.GENERAL_POPUP.size.x, 0)


func _on_gui(_event: InputEvent) -> void:
    if _event is InputEventMouseButton:
        if _event.pressed:
            if _event.button_index == MOUSE_BUTTON_LEFT:
                var container: VBoxContainer = get_node('%Container')
                var anim_panel: Control = get_node('%AnimationPanel')
                var _show: bool = not container.visible
                var open_icon: TextureRect = get_node('%OpenIcon')
                var tween: Tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_parallel()

                print(_show)
                
                container.visible = _show
                anim_panel.visible = not container.visible

                open_icon.pivot_offset = open_icon.size / 2
                tween.tween_property(open_icon, 'rotation_degrees', 0 if container.visible else 180, .2)

                if anim_panel.visible:
                    tween.finished.connect(func(): container.visible = false)
                    anim_panel.custom_minimum_size = container.size
                    tween.tween_property(anim_panel, 'custom_minimum_size', Vector2(anim_panel.size.x, 0), .2)
                    

func _on_add() -> void:
    add_prop()

    print('Added: ', type)

func add_prop(_config: Dictionary = {}, start_item: bool = true) -> _SideBarSectionItem:
    var item = _Assets.SideBarSectionItemScene.instantiate()
    var prop_name = (base_name + name_count as String).to_snake_case() if not _config.has('name') else _config.get('name')
    item.get_node('%Name').text = prop_name

    if not _config.has('name'):
        if name_count.is_empty():
            name_count = str(1)
        else:
            name_count = str(
                int(name_count) + 1
            )

    match type:
        Types.PROP_VAR, Types.LOCAL_VAR:
            var res = load('res://addons/hengo/resources/prop_var.tres')
            var var_res = load('res://addons/hengo/resources/cnode_var.tres').duplicate()
            
            if type == Types.LOCAL_VAR:
                item.type = 'local_var'
            else:
                item.type = 'var'

            var _name: Resource = res.duplicate()
            var _type: Resource = res.duplicate()

            _name._ref = item
            _name.name = "Name"
            _name.type = _Enums.PROP_TYPE.STRING
            _name.sub_type = "item_name"
            _name.cnode_var_ref = var_res
            _name.value = prop_name

            _type._ref = item
            _type.name = "Type"
            _type.type = _Enums.PROP_TYPE.DROPDOWN
            _type.sub_type = 'item_type'
            _type.cnode_var_ref = var_res
            _type.value = 'Variant' if not _config.has('type') else _config.get('type')

            # these resources are the props from sidmenu variable
            item.res = [
                _name,
                _type
            ]


            # this data is sent to cnode creation
            item.data = {
                var_res = var_res
            }

            # style margin for no button items
            var style: StyleBoxFlat = item.get('theme_override_styles/panel')

            style.content_margin_top = 4
            style.content_margin_bottom = 4


            if type == Types.LOCAL_VAR:
                var route = _Router.current_route if not _config.has('route_ref') else _config.get('route_ref')

                if not local_vars.has(route.id):
                    local_vars[route.id] = []
                
                local_vars[route.id].append(item)
                item.route_ref = route
            else:
                var _export: Resource = res.duplicate()

                _export._ref = item
                _export.name = "Export"
                _export.type = _Enums.PROP_TYPE.BOOL
                _export.value = false if not _config.has('export_var') else _config.get('export_var')

                item.res.append(_export)
        Types.PROP_FUNCTION:
            var res = load('res://addons/hengo/resources/prop_function.tres')

            item.type = 'function'

            var _name: Resource = res.duplicate()
            var _inputs: Resource = res.duplicate()
            var _outputs: Resource = res.duplicate()

            _name.item_ref = item
            _name.name = "Name"
            _name.type = _Enums.PROP_TYPE.STRING
            _name.sub_type = "item_name"
            _name.value = prop_name

            _inputs.item_ref = item
            _inputs.name = "Inputs"
            _inputs.type = _Enums.PROP_TYPE.FUNCTION_INPUT
            _inputs.value = ''

            _outputs.item_ref = item
            _outputs.name = "Outputs"
            _outputs.type = _Enums.PROP_TYPE.FUNCTION_OUTPUT
            _outputs.value = ''

            # these resources are the props from sidemenu variable
            item.res = [
                _name,
                _inputs,
                _outputs
            ]

            # this data is sent to cnode creation and updating
            item.data = {
                func_res = _name,
                inputs_res = _inputs,
                outputs_res = _outputs
            }
        Types.STATE_SIGNAL:
            var res = load('res://addons/hengo/resources/prop_state_signal.tres')

            item.type = 'state_signal'

            var _name: Resource = res.duplicate()
            var _params: Resource = res.duplicate()

            _name.item_ref = item
            _name.name = "Name"
            _name.type = _Enums.PROP_TYPE.STRING
            _name.sub_type = "item_name"
            _name.value = prop_name

            _params.item_ref = item
            _params.name = "Custom Params"
            _params.type = _Enums.PROP_TYPE.FUNCTION_OUTPUT
            _params.value = ''

            # these resources are the props from sidemenu variable
            item.res = [
                _name,
                _params
            ]

            item.data = {
                signal_params = _params
            }

            item.data.signal_data = _config.get('signal_data')
    
    # color
    var _color: Color = (get('theme_override_styles/panel').get('bg_color') as Color).darkened(.4)
    item.get('theme_override_styles/panel').set('bg_color', _color)
    item.color = _color


    get_node('%Container').add_child(item)

    if start_item:
        item.start_item()

    return item

func show_local_vars(_route: Dictionary) -> void:
    var container = get_node('%Container')

    # cleaning others local variables
    for item in container.get_children():
        container.remove_child(item)

    if local_vars.has(_route.id):
        # adding local variable from that route
        for item in local_vars[_route.id]:
            container.add_child(item)

    visible = true

func show_signal_params(_route: Dictionary) -> void:
    print('signals')
