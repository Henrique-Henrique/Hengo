@tool
extends PanelContainer

@onready var name_node: Button = %Name
@onready var sub_category_node: HFlowContainer = %SubCategoryContainer

func set_item_data(_data: Dictionary) -> void:
    name_node.text = _data._class_name

    for chd: Button in sub_category_node.get_children():
        sub_category_node.remove_child(chd)
        chd.queue_free()
    
    for category: Dictionary in _data.get(&'categories', []):
        var bt: Button = Button.new()
        bt.pressed.connect(_on_press.bind(_data.get(&'_class_name', ''), category))
        bt.icon = load('res://addons/hengo/assets/new_icons/' + category.get(&'icon', 'square') + '.svg')
        bt.add_theme_color_override(&'icon_normal_color', category.get(&'color', Color.WHITE))
        bt.text = category.name
        sub_category_node.add_child(bt)
    
    await RenderingServer.frame_pre_draw


func _on_press(_class_name: StringName, _data: Dictionary) -> void:
    var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
    if _data.get(&'is_native', false):
        signal_bus.request_code_search_select.emit(_data)
        return
    signal_bus.request_code_search_show_list.emit(_class_name, _data.get(&'method_list', []), _data.name)