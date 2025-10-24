@tool
class_name HenPropEditor extends MarginContainer

const PROP_EDITOR = preload('res://addons/hengo/scenes/utils/prop_editor/prop_editor.tscn')
const PROP_ITEM = preload('res://addons/hengo/scenes/utils/prop_editor/prop_item.tscn')
const PROP_ARRAY_ITEM = preload('res://addons/hengo/scenes/utils/prop_editor/prop_array_item.tscn')
const ARRAY_ITEM = preload('res://addons/hengo/scenes/utils/prop_editor/array_item.tscn')

static var instance: HenPropEditor

#
#
#
#
#
#
var get_prop_callback: Callable
var instance_ref

#
#
#
#
#
#
func _ready() -> void:
	instance = self
	(%Delete as Button).pressed.connect(_on_delete)
#
#
#
#
#
#
func _on_delete() -> void:
	instance_ref.delete()
#
#
#
#
#
#
func start() -> void:
	var item_container: VBoxContainer = get_node('%ItemContainer')
	var props: Array = get_prop_callback.call()

	for item in item_container.get_children():
		item_container.remove_child(item)
		item.queue_free()

	for prop: HenProp in props:
		match prop.type:
			HenProp.Type.ARRAY:
				var arr_item: HenPropArrayItem = PROP_ARRAY_ITEM.instantiate()
				arr_item.start(prop)
				(arr_item.get_node('%Name') as Label).text = prop.name

				# create array items
				for item_prop: HenProp in prop.prop_list:
					var item: HenArrayItem = ARRAY_ITEM.instantiate()
					var field: Control = item_prop.get_field()

					item.start(item_prop)
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


static func mount(_ref: RefCounted) -> HenPropEditor:
	var editor: HenPropEditor = PROP_EDITOR.instantiate() as HenPropEditor
	editor.get_prop_callback = (_ref as Variant).get_inspector_array_list
	editor.instance_ref = _ref
	editor.start()
	return editor


static func get_singleton() -> HenPropEditor:
	return instance
