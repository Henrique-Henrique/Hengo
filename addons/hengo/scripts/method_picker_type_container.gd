@tool
extends VBoxContainer

@onready var type_tree: Tree = %TypeTree
@onready var search: LineEdit = %SearchType
    

func _ready() -> void:
    build_list()

func build_list() -> void:
    type_tree.clear()

    var root: TreeItem = type_tree.create_item()
    root.set_text(0, &'Object')

    for class_item in ClassDB.get_inheriters_from_class(&'Object'):
        var item: TreeItem = type_tree.create_item(root)
        item.set_text(0, class_item)
