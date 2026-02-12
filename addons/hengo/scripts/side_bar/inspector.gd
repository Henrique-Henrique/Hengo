@tool
class_name HenInspector extends ScrollContainer

const PROP_CONTAINER: PackedScene = preload('res://addons/hengo/scenes/prop_container.tscn')
const DROPDOWN_PROP: PackedScene = preload('res://addons/hengo/scenes/props/dropdown.tscn')
const DROPDOWN_HINT_TYPES: Array[String] = [
	'state_transition',
	'action',
	'all_godot_classes',
	'hengo_states',
	'all_classes',
	'all_classes_self',
	'enum_list',
	'all_props',
	'signal',
	'callable',
	'key_code',
	'mouse_button',
	'state_event_list'
]
const PROPS: Dictionary = {
	TYPE_BOOL: preload('res://addons/hengo/scenes/props/boolean.tscn'),
	TYPE_INT: preload('res://addons/hengo/scenes/props/int.tscn'),
	TYPE_FLOAT: preload('res://addons/hengo/scenes/props/float.tscn'),
	TYPE_STRING: preload('res://addons/hengo/scenes/props/string.tscn'),
	TYPE_STRING_NAME: preload('res://addons/hengo/scenes/props/string.tscn'),
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
	
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(inspector)
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

	var prop_index: int = 0
	for prop in resource.get_property_list():
		if prop.type == TYPE_ARRAY or prop.usage & PROPERTY_USAGE_EDITOR:
			_create_prop_editor(prop, prop_index)
			prop_index += 1


func _create_prop_editor(prop: Dictionary, prop_index: int) -> void:
	var prop_scene: PackedScene = get_prop_scene(resource, prop)
	if not prop_scene:
		return

	if prop_index > 0:
		var separator := HSeparator.new()
		vbox.add_child(separator)

	var container: VBoxContainer = PROP_CONTAINER.instantiate()
	var label: Label = container.get_node('Name')
	label.text = prop.name.capitalize()
	# adjusts font size relative to editor scale
	if Engine.is_editor_hint():
		var editor_scale: float = EditorInterface.get_editor_scale()
		label.add_theme_font_size_override('font_size', int(14 * editor_scale))

	vbox.add_theme_constant_override('separation', 10 * int(EditorInterface.get_editor_scale()))
	
	var editor: Control = _instantiate_editor(prop_scene, prop)
	if not editor:
		return

	configure_editor(editor, resource, prop)
	
	container.add_child(editor)
	
	var panel: PanelContainer = PanelContainer.new()
	
	if prop_index % 2 != 0:
		panel.self_modulate = Color(1, 1, 1, 0.05)
	else:
		panel.self_modulate = Color(1, 1, 1, 0)
	
	panel.add_child(container)
	vbox.add_child(panel)


func configure_editor(editor: Control, target_resource: Resource, prop: Dictionary, p_depth: int = 0, p_path: String = '', connect_change_signal: bool = true) -> void:
	var value: Variant = target_resource.get(prop.name)

	if editor is HenDropdown:
		var dropdown: HenDropdown = editor as HenDropdown
		if _is_dropdown_hint(prop.hint_string):
			dropdown.type = prop.hint_string
		elif is_save_param_resource(target_resource) and prop.name == 'type':
			dropdown.type = 'all_godot_classes'
	
	if prop.type == TYPE_BOOL:
		editor.set_default(value)
	elif prop.type == TYPE_COLOR:
		editor.set_default(value)
	elif prop.type == TYPE_ARRAY:
		if editor.has_method('setup'):
			editor.call('setup', target_resource, prop.name, value, prop.hint_string, p_depth, p_path)
	else:
		editor.set_default(str(value))

	if connect_change_signal and editor.has_signal('value_changed'):
		editor.value_changed.connect(func(new_val: Variant):
			_on_value_changed(prop.name, new_val, prop.type)
		)


func _on_value_changed(prop_name: String, new_val: Variant, type: int) -> void:
	var final_val: Variant = normalize_value(resource, prop_name, new_val, type)
		
	# var global: HenGlobal = Engine.get_singleton('Global')
	# var history: UndoRedo = global.history
	
	# if history:
	# 	history.create_action('Set ' + prop_name)
	# 	history.add_do_property(resource, prop_name, final_val)
	# 	history.add_undo_property(resource, prop_name, resource.get(prop_name))
	# 	history.commit_action()
	# 	return

	resource.set(prop_name, final_val)


func get_prop_scene(target_resource: Resource, prop: Dictionary) -> PackedScene:
	if (prop.type == TYPE_STRING or prop.type == TYPE_STRING_NAME) and _is_dropdown_hint(prop.hint_string):
		return DROPDOWN_PROP
	if is_save_param_resource(target_resource) and prop.name == 'type':
		return DROPDOWN_PROP

	return PROPS.get(prop.type)


func normalize_value(target_resource: Resource, prop_name: String, new_val: Variant, type: int) -> Variant:
	var final_val: Variant = new_val
	var current_value: Variant = target_resource.get(prop_name)

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
	elif current_value is StringName and new_val is String:
		final_val = StringName(new_val)

	return final_val


func is_save_param_resource(res: Resource) -> bool:
	if res is HenSaveParam:
		return true

	var script: Script = res.get_script()
	return script != null and script.resource_path == 'res://addons/hengo/scripts/save_load/resource/save_param.gd'


func _instantiate_editor(prop_scene: PackedScene, prop: Dictionary) -> Control:
	var editor: Control = prop_scene.instantiate()
	if editor:
		return editor

	var scene_path: String = prop_scene.resource_path if prop_scene else '<null>'
	push_error("Could not instantiate editor scene for prop '%s' (type: %s, hint: '%s') from '%s'." % [prop.name, str(prop.type), str(prop.hint_string), scene_path])
	return null


func _is_dropdown_hint(hint: String) -> bool:
	return DROPDOWN_HINT_TYPES.has(hint)
