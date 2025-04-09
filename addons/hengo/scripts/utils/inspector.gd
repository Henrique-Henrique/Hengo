@tool
class_name HenInspector extends MarginContainer

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
	var item_move_callback: Callable
	var item_delete_callback: Callable
	var prop_array_ref: HenPropArray
	var category: StringName

	func _init(_data: Dictionary) -> void:
		type = _data.type

		if type == 'Array':
			field = _data.field
			item_creation_callback = _data.item_creation_callback

			if _data.has('item_move_callback'):
				item_move_callback = _data.item_move_callback
			
			if _data.has('item_delete_callback'):
				item_delete_callback = _data.item_delete_callback

		if _data.has('name'):
			name = _data.name
			
		if _data.has('value'):
			value = _data.value

		if _data.has('ref'):
			ref = _data.ref
		
		if _data.has('category'):
			category = _data.category

		if _data.has('prop_array_ref'):
			prop_array_ref = _data.prop_array_ref
		

static func start(_list: Array, _inspector: HenInspector = null) -> HenInspector:
	var inspector: HenInspector = preload('res://addons/hengo/scenes/utils/inspector.tscn').instantiate() if not _inspector else _inspector
	var container: VBoxContainer = inspector.get_node('%InspectorContainer')

	# cleaning inputs to update inspector
	if _inspector:
		for chd in container.get_children():
			container.remove_child(chd)
			chd.queue_free()

	for item_data: InspectorItem in _list:
		var item = INSPECTOR_ITEM.instantiate()
		var field_container = item.get_node('%FieldContainer')
		var prop: Control

		(item.get_node('%Name') as Label).text = item_data.name

		# binding move buttons to array prop
		if item_data.prop_array_ref:
			var array_container: HBoxContainer = item.get_node('%ArrayContainer')
			array_container.visible = true
			(array_container.get_node('%Up') as Button).pressed.connect(item_data.prop_array_ref.on_item_move.bind(HenPropArray.ArrayMove.UP, item_data.ref))
			(array_container.get_node('%Down') as Button).pressed.connect(item_data.prop_array_ref.on_item_move.bind(HenPropArray.ArrayMove.DOWN, item_data.ref))
			(array_container.get_node('%Delete') as Button).pressed.connect(item_data.prop_array_ref.on_item_delete.bind(item_data.ref))

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
				prop.start(item_data.field, item_data.value, item_data.item_creation_callback, item_data.item_move_callback, item_data.item_delete_callback)
			'@dropdown':
				prop = preload('res://addons/hengo/scenes/props/dropdown.tscn').instantiate()

				(prop as HenDropdown).type = item_data.category
			'@Param':
				prop = preload('res://addons/hengo/scenes/props/param.tscn').instantiate()
				# name and type are obligatory
				prop.set_values(item_data.ref.name, item_data.ref.type)
				prop.param_changed.connect(inspector.item_value_changed.bind(item_data.ref))

		if prop:
			field_container.add_child(prop)

			if prop.has_method('set_default'):
				prop.set_default(item_data.value)

			if prop.has_signal('value_changed'):
				prop.connect('value_changed', inspector.item_value_changed.bind(item_data.name, item_data.ref))

		container.add_child(item)

	HenGlobal.GENERAL_POPUP.reset_size()
	return inspector


func item_value_changed(_value: Variant, _name: String, _ref: Object) -> void:
	if _ref: _ref.set(_name, _value)
	item_changed.emit()