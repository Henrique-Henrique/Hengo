@tool
extends VBoxContainer

const PROP_CONTAINER: PackedScene = preload('res://addons/hengo/scenes/prop_container.tscn')

var resource: Resource

var prop_name: String
var array_type_string: String
var array_val: Array
var depth: int = 0
var current_path: String = ''


# initial setup called by inspector.gd
func setup(res: Resource, p_name: String, val: Array, hint_string: String, p_depth: int = 0, p_path: String = '') -> void:
	resource = res
	prop_name = p_name
	array_val = val
	depth = p_depth
	
	if p_path.is_empty():
		current_path = prop_name.capitalize()
	else:
		current_path = p_path + ' > ' + prop_name.capitalize()
	
	
	if ':' in hint_string:
		array_type_string = hint_string.split(':')[-1]
	else:
		array_type_string = hint_string


func _ready() -> void:
	if Engine.is_editor_hint():
		var editor_scale: float = EditorInterface.get_editor_scale()
		add_theme_constant_override('separation', int(10 * editor_scale))

	call_deferred('_setup_header')
	_refresh_list()


func _setup_header() -> void:
	var parent: Node = get_parent()
	if not parent: return
	
	var label: Label = parent.get_node_or_null('Name')
	if not label: return
	
	# check if we already did this (re-entering tree)
	if label.get_parent() is HBoxContainer and label.get_parent().get_parent() == parent:
		# already setup, just ensure we have our button
		var existing_hbox: HBoxContainer = label.get_parent()
		if existing_hbox.has_node('AddBtn'):
			var existing_btn: Button = existing_hbox.get_node('AddBtn')
			if existing_btn.pressed.is_connected(_on_add_pressed):
				existing_btn.pressed.disconnect(_on_add_pressed)
			existing_btn.pressed.connect(_on_add_pressed)
			return

	# create header hbox
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.size_flags_horizontal = SIZE_EXPAND_FILL
	
	var pos: int = label.get_index()
	parent.remove_child(label)
	hbox.add_child(label)
	
	var btn: Button = Button.new()
	btn.name = 'AddBtn'
	btn.text = 'Add ' + prop_name.capitalize()
	btn.icon = get_theme_icon('Add', 'EditorIcons')
	btn.pressed.connect(_on_add_pressed)
	hbox.add_child(btn)
	
	parent.add_child(hbox)
	parent.move_child(hbox, pos)


func _refresh_list() -> void:
	# clear existing
	for child in get_children():
		remove_child(child)
		child.queue_free()
		
	# add items
	for i in range(array_val.size()):
		var item: Variant = array_val[i]
		_create_item_editor(item, i)


func set_default(_val: Variant) -> void:
	pass


func _create_item_editor(item: Variant, index: int) -> void:
	var margin_container: MarginContainer = MarginContainer.new()
	if depth > 0:
		margin_container.add_theme_constant_override('margin_left', 20)
	
	var container: PanelContainer = PanelContainer.new()
	var vbox: VBoxContainer = VBoxContainer.new()
	container.add_child(vbox)
	
	margin_container.add_child(container)
	add_child(margin_container)
	
	container.self_modulate = HenUtils.get_depth_color(depth)
	
	var header: HBoxContainer = HBoxContainer.new()
	var label: Label = Label.new()
	label.text = current_path + ' ' + str(index)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var del_btn: Button = Button.new()
	del_btn.icon = get_theme_icon('Remove', 'EditorIcons')
	del_btn.flat = true
	del_btn.pressed.connect(func(): _on_remove_pressed(index))
	
	header.add_child(label)
	header.add_child(del_btn)
	vbox.add_child(header)
	
	if item is Resource:
		for prop in item.get_property_list():
			if prop.usage & PROPERTY_USAGE_EDITOR:
				_create_sub_property_editor(vbox, item, prop, index)


func _create_sub_property_editor(parent_container: Control, item: Resource, prop: Dictionary, _index: int) -> void:
	var inspector: HenInspector = find_parent_inspector()
	if not inspector:
		return
		
	var prop_scene: PackedScene = inspector.get_prop_scene(item, prop)
	if not prop_scene:
		if prop.type == TYPE_ARRAY:
			prop_scene = preload('res://addons/hengo/scenes/props/array.tscn')
		else:
			return

	var container: VBoxContainer = PROP_CONTAINER.instantiate()
	var label: Label = container.get_node('Name')
	label.text = prop.name.capitalize()
	
	if Engine.is_editor_hint():
		var editor_scale: float = EditorInterface.get_editor_scale()
		label.add_theme_font_size_override('font_size', int(14 * editor_scale))
		add_theme_constant_override('separation', int(10 * editor_scale))
	
	var editor: Control = prop_scene.instantiate()
	if not editor:
		var scene_path: String = prop_scene.resource_path if prop_scene else '<null>'
		push_error("Could not instantiate array editor for prop '%s' (type: %s, hint: '%s') from '%s'." % [prop.name, str(prop.type), str(prop.hint_string), scene_path])
		return

	inspector.configure_editor(editor, item, prop, depth + 1, current_path, false)

	if editor.has_signal('value_changed'):
		editor.value_changed.connect(func(new_val: Variant):
			_on_item_prop_changed(item, prop.name, new_val, prop.type)
		)
	
	container.add_child(editor)
	parent_container.add_child(container)


func _on_add_pressed() -> void:
	var global: HenGlobal = Engine.get_singleton('Global')
	
	var new_item: Variant
	if ClassDB.class_exists(array_type_string):
		new_item = ClassDB.instantiate(array_type_string)
	elif ProjectSettings.get_global_class_list().any(func(d): return d.class == array_type_string):
		var script_classes: Array[Dictionary] = ProjectSettings.get_global_class_list()
		for c in script_classes:
			if c.class == array_type_string:
				new_item = load(c.path).new()
				break
				
	if not new_item:
		push_error('Could not instantiate ' + array_type_string)
		return

	if array_type_string == 'HenSaveParam' and new_item.has_method('create'):
		var script: Script = load('res://addons/hengo/scripts/save_load/resource/save_param.gd')
		new_item = script.create()
	
	var history: UndoRedo = global.history
	history.create_action('Add ' + array_type_string)
	
	var new_arr: Array = array_val.duplicate()
	new_arr.append(new_item)
	
	history.add_do_property(resource, prop_name, new_arr)
	history.add_undo_property(resource, prop_name, array_val)
	
	history.add_do_method(_active_refresh.bind(new_arr))
	history.add_undo_method(_active_refresh.bind(array_val))
	
	history.commit_action()


func _on_remove_pressed(index: int) -> void:
	var global: HenGlobal = Engine.get_singleton('Global')
	var history: UndoRedo = global.history
	
	var new_arr: Array = array_val.duplicate()
	new_arr.remove_at(index)
	
	history.create_action('Remove Array Item')
	history.add_do_property(resource, prop_name, new_arr)
	history.add_undo_property(resource, prop_name, array_val)
	
	history.add_do_method(_active_refresh.bind(new_arr))
	history.add_undo_method(_active_refresh.bind(array_val))
	
	history.commit_action()


func _on_item_prop_changed(item: Resource, p_name: String, new_val: Variant, type: int) -> void:
	var final_val: Variant = new_val
	var inspector: HenInspector = find_parent_inspector()
	if inspector:
		final_val = inspector.normalize_value(item, p_name, new_val, type)
	
	var global: HenGlobal = Engine.get_singleton('Global')
	var history: UndoRedo = global.history
	
	history.create_action('Set ' + p_name)
	history.add_do_property(item, p_name, final_val)
	history.add_undo_property(item, p_name, item.get(p_name))
	
	if p_name == 'type' and item is HenSaveParam:
		history.add_do_method((Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit)
		history.add_undo_method((Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit)
		history.add_do_method(_refresh_list)
		history.add_undo_method(_refresh_list)
	
	history.commit_action()
	
	if p_name == 'type' and item is HenSaveParam:
		_refresh_list()


func _active_refresh(new_arr: Array) -> void:
	array_val = new_arr
	if is_inside_tree():
		_refresh_list()


func find_parent_inspector() -> HenInspector:
	var node: Node = get_parent()
	while node:
		if node is HenInspector:
			return node
		node = node.get_parent()
	return null
