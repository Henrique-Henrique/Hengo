@tool
class_name HenInspector extends ScrollContainer

const PROP_CONTAINER: PackedScene = preload('res://addons/hengo/scenes/prop_container.tscn')
const PROPS: Dictionary = {
	TYPE_BOOL: preload('res://addons/hengo/scenes/props/boolean.tscn'),
	TYPE_INT: preload('res://addons/hengo/scenes/props/int.tscn'),
	TYPE_FLOAT: preload('res://addons/hengo/scenes/props/float.tscn'),
	TYPE_STRING: preload('res://addons/hengo/scenes/props/string.tscn'),
	TYPE_VECTOR2: preload('res://addons/hengo/scenes/props/vec2.tscn'),
	TYPE_VECTOR2I: preload('res://addons/hengo/scenes/props/vec2i.tscn'),
	TYPE_VECTOR3: preload('res://addons/hengo/scenes/props/vec3.tscn'),
	TYPE_VECTOR3I: preload('res://addons/hengo/scenes/props/vec3i.tscn'),
	TYPE_VECTOR4: preload('res://addons/hengo/scenes/props/vec4.tscn'),
	TYPE_COLOR: preload('res://addons/hengo/scenes/props/color.tscn'),
	TYPE_ARRAY: preload('res://addons/hengo/scenes/props/array.tscn')
}

var resource: Resource
var vbox: VBoxContainer


func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	
	vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vbox)


# initializes the inspector within the custom popup system
static func edit_resource(_res: Resource) -> void:
	var global: HenGlobal = Engine.get_singleton('Global')
	var scene: PackedScene = load('res://addons/hengo/scenes/custom_inspector.tscn')
	var inspector: HenInspector = scene.instantiate()
	
	global.GENERAL_POPUP.show_content(inspector)
	inspector.edit(_res)

	global.CURRENT_INSPECTOR = inspector
	inspector.grab_focus()


func edit(_res: Resource) -> void:
	resource = _res
	
	_update_props()


func _update_props() -> void:
	for child in vbox.get_children():
		child.queue_free()

	if not resource:
		return

	for prop in resource.get_property_list():
		if prop.type == TYPE_ARRAY or prop.usage & PROPERTY_USAGE_EDITOR:
			_create_prop_editor(prop)


func _create_prop_editor(prop: Dictionary) -> void:
	var prop_scene: PackedScene = PROPS.get(prop.type)
	if not prop_scene:
		return

	var container: VBoxContainer = PROP_CONTAINER.instantiate()
	var label: Label = container.get_node('Name')
	label.text = prop.name.capitalize()
	# adjusts font size relative to editor scale
	if Engine.is_editor_hint():
		var editor_scale: float = EditorInterface.get_editor_scale()
		label.add_theme_font_size_override('font_size', int(14 * editor_scale))

	vbox.add_theme_constant_override('separation', 10 * int(EditorInterface.get_editor_scale()))
	
	var editor: Control = prop_scene.instantiate()
	_configure_editor(editor, prop)
	
	container.add_child(editor)
	
	var panel: PanelContainer = PanelContainer.new()
	var idx: int = vbox.get_child_count()
	
	if idx % 2 != 0:
		panel.self_modulate = Color(1, 1, 1, 0.05)
	else:
		panel.self_modulate = Color(1, 1, 1, 0)
	
	panel.add_child(container)
	vbox.add_child(panel)


func _configure_editor(editor: Control, prop: Dictionary) -> void:
	var value: Variant = resource.get(prop.name)
	
	if prop.type == TYPE_BOOL:
		editor.set_default(value)
	elif prop.type == TYPE_COLOR:
		editor.set_default(value)
	elif prop.type == TYPE_ARRAY:
		if editor.has_method('setup'):
			editor.setup(resource, prop.name, value, prop.hint_string)
	else:
		editor.set_default(str(value))

	if editor.has_signal('value_changed'):
		editor.value_changed.connect(func(new_val: Variant):
			_on_value_changed(prop.name, new_val, prop.type)
		)


func _on_value_changed(prop_name: String, new_val: Variant, type: int) -> void:
	var final_val: Variant = new_val
	
	if type == TYPE_INT and new_val is float:
		final_val = int(new_val)
	elif type == TYPE_INT and new_val is String:
		final_val = int(new_val)
	elif type == TYPE_FLOAT and new_val is String:
		final_val = float(new_val)
	elif type == TYPE_VECTOR2 and new_val is String:
		final_val = str_to_var(new_val)
	elif type == TYPE_VECTOR2I and new_val is String:
		final_val = str_to_var(new_val)
	elif type == TYPE_VECTOR3 and new_val is String:
		final_val = str_to_var(new_val)
	elif type == TYPE_VECTOR3I and new_val is String:
		final_val = str_to_var(new_val)
	elif type == TYPE_VECTOR4 and new_val is String:
		final_val = str_to_var(new_val)
	elif type == TYPE_COLOR and new_val is String:
		final_val = str_to_var(new_val)
		
	# var global: HenGlobal = Engine.get_singleton('Global')
	# var history: UndoRedo = global.history
	
	# if history:
	# 	history.create_action('Set ' + prop_name)
	# 	history.add_do_property(resource, prop_name, final_val)
	# 	history.add_undo_property(resource, prop_name, resource.get(prop_name))
	# 	history.commit_action()
	# 	return

	resource.set(prop_name, final_val)