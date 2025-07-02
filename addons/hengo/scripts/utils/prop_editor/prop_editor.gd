@tool
class_name HenPropEditor extends MarginContainer

const PROP_EDITOR = preload('res://addons/hengo/scenes/utils/prop_editor/prop_editor.tscn')
const PROP_ITEM = preload('res://addons/hengo/scenes/utils/prop_editor/prop_item.tscn')
const PROP_ARRAY_ITEM = preload('res://addons/hengo/scenes/utils/prop_editor/prop_array_item.tscn')
const ARRAY_ITEM = preload('res://addons/hengo/scenes/utils/prop_editor/array_item.tscn')


static var editor_ref: HenPropEditor

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
class Prop:
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
				var item = preload('res://addons/hengo/scenes/props/dropdown.tscn').instantiate()
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

#
#
#
#
#
#
func _ready() -> void:
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

	for prop: Prop in props:
		match prop.type:
			Prop.Type.ARRAY:
				var arr_item: HenPropArrayItem = PROP_ARRAY_ITEM.instantiate()
				arr_item.start(prop)
				(arr_item.get_node('%Name') as Label).text = prop.name

				# create array items
				for item_prop: Prop in prop.prop_list:
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
	editor_ref = editor

	editor.start()
	return editor


static func get_singleton() -> HenPropEditor:
	return editor_ref