class_name HenProp extends RefCounted

enum Type {
    ARRAY,
    STRING,
    DROPDOWN,
    BOOL
}

var name: String
var type: Type
var prop_list: Array
var default_value: Variant
var on_value_changed: Callable
var on_item_create: Callable
var on_item_delete: Callable
var on_item_move: Callable
var category: StringName
var data: Variant


func _init(_data: Dictionary) -> void:
    name = _data.name
    type = _data.type

    for key: StringName in [
        'prop_list',
        'default_value',
        'on_value_changed',
        'on_item_create',
        'on_item_delete',
        'on_item_move',
        'category',
        'data'
    ]:
        if _data.has(key):
            set(key, _data.get(key))
    
    
func get_field() -> Control:
    match type:
        Type.STRING:
            var item = preload('res://addons/hengo/scenes/props/string.tscn').instantiate()

            if default_value:
                item.set_default(default_value)

            if on_value_changed:
                item.connect('value_changed', on_value_changed)

            return item
        Type.DROPDOWN:
            # why preload doesn't work here?
            var dropdown_scene: PackedScene = ResourceLoader.load('res://addons/hengo/scenes/props/dropdown.tscn')
            var item = dropdown_scene.instantiate()

            item.type = category

            if data:
                item.custom_data = data
            
            if default_value:
                item.set_default(default_value)

            if on_value_changed:
                item.connect('value_changed', on_value_changed)

            return item
        Type.BOOL:
            var item = preload('res://addons/hengo/scenes/props/boolean.tscn').instantiate()

            if default_value:
                item.set_default(default_value)

            if on_value_changed:
                item.connect('value_changed', on_value_changed)

            return item
    return null