@tool
class_name HenPropEditor extends MarginContainer

const PROP_EDITOR = preload('res://addons/hengo/scenes/utils/prop_editor/prop_editor.tscn')
const PROP_ITEM = preload('res://addons/hengo/scenes/utils/prop_editor/prop_item.tscn')
const PROP_ARRAY_ITEM = preload('res://addons/hengo/scenes/utils/prop_editor/prop_array_item.tscn')
const ARRAY_ITEM = preload('res://addons/hengo/scenes/utils/prop_editor/array_item.tscn')

class Prop:
    enum Type {
        ARRAY,
        STRING
    }

    var name: String
    var type: Type
    var prop_list: Array[Prop]

    func _init(_name: String, _type: Type, _prop_list: Array[Prop] = []) -> void:
        name = _name
        type = _type
        prop_list = _prop_list
    
    func get_field() -> Control:
        match type:
            Type.STRING:
                return preload('res://addons/hengo/scenes/props/string.tscn').instantiate()
            
        return null


func start(_props: Array[Prop]) -> void:
    var item_container: VBoxContainer = get_node('%ItemContainer')
    
    for prop: Prop in _props:
        match prop.type:
            Prop.Type.ARRAY:
                var arr_item = PROP_ARRAY_ITEM.instantiate()
                (arr_item.get_node('%Name') as Label).text = prop.name

                # create array items
                for item_prop: Prop in prop.prop_list:
                    var item = ARRAY_ITEM.instantiate()
                    var field: Control = item_prop.get_field()

                    (item.get_node('%Name') as Label).text = item_prop.name

                    item.add_child(field)
                    item.move_child(field, 1)
                    (arr_item.get_node('%Container') as VBoxContainer).add_child(item)

                item_container.add_child(arr_item)
            _:
                var item = PROP_ITEM.instantiate()
                var field: Control = prop.get_field()
                (item.get_node('%Name') as Label).text = prop.name

                item.add_child(field)
                item_container.add_child(item)


static func mount(_props: Array[Prop]) -> HenPropEditor:
    var editor: HenPropEditor = PROP_EDITOR.instantiate()
    editor.start(_props)

    return editor
