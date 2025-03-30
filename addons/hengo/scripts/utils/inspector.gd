@tool
class_name HenInspector extends VBoxContainer

const INSPECTOR_ITEM = preload('res://addons/hengo/scenes/utils/inspector_item.tscn')

signal item_changed

class InspectorItem:
    var name: String
    var type: StringName
    var sub_type: StringName
    var value: Variant
    var ref: Variant
    var field: Dictionary
    var item_creation_callback: Callable

    func _init(_data: Dictionary) -> void:
        type = _data.type

        if type == 'Array':
            field = _data.field
            item_creation_callback = _data.item_creation_callback

        if _data.has('name'):
            name = _data.name
            
        if _data.has('value'):
            value = _data.value

        if _data.has('ref'):
            ref = _data.ref
        

static func start(_list: Array, _inspector: HenInspector = null) -> HenInspector:
    var inspector: HenInspector = preload('res://addons/hengo/scenes/utils/inspector.tscn').instantiate() if not _inspector else _inspector

    if _inspector:
        for chd in inspector.get_children():
            inspector.remove_child(chd)
            chd.queue_free()

    for item_data: InspectorItem in _list:
        var item = INSPECTOR_ITEM.instantiate()
        var field_container = item.get_node('%FieldContainer')
        var prop: Control

        (item.get_node('%Name') as Label).text = item_data.name

        match item_data.type:
            'String':
                prop = preload('res://addons/hengo/scenes/props/string.tscn').instantiate()
            'int':
                prop = preload('res://addons/hengo/scenes/props/int.tscn').instantiate()
            'float':
                prop = preload('res://addons/hengo/scenes/props/float.tscn').instantiate()
            'Vector2':
                prop = preload('res://addons/hengo/scenes/props/vec2.tscn').instantiate()
            'bool':
                prop = preload('res://addons/hengo/scenes/props/boolean.tscn').instantiate()
            'Array':
                prop = preload('res://addons/hengo/scenes/props/array.tscn').instantiate()
                prop.start(item_data.field, item_data.value, item_data.item_creation_callback)
            
        if prop:
            field_container.add_child(prop)

            if prop.has_method('set_default'):
                prop.set_default(item_data.value)

            if prop.has_signal('value_changed'):
                prop.connect('value_changed', inspector.item_value_changed.bind(item_data.name, item_data.ref))

        inspector.add_child(item)

    HenGlobal.GENERAL_POPUP.reset_size()
    return inspector


func item_value_changed(_value: Variant, _name: String, _ref: Object) -> void:
    if _ref: _ref.set(_name, _value)
    item_changed.emit()