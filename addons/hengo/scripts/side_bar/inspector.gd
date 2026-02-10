@tool
class_name HenInspector extends ScrollContainer

const PROP_CONTAINER: PackedScene = preload("res://addons/hengo/scenes/prop_container.tscn")
const PROPS: Dictionary = {
	TYPE_BOOL: preload("res://addons/hengo/scenes/props/boolean.tscn"),
	TYPE_INT: preload("res://addons/hengo/scenes/props/int.tscn"),
	TYPE_FLOAT: preload("res://addons/hengo/scenes/props/float.tscn"),
	TYPE_STRING: preload("res://addons/hengo/scenes/props/string.tscn"),
	TYPE_VECTOR2: preload("res://addons/hengo/scenes/props/vec2.tscn"),
	TYPE_VECTOR2I: preload("res://addons/hengo/scenes/props/vec2i.tscn"),
	TYPE_VECTOR3: preload("res://addons/hengo/scenes/props/vec3.tscn"),
	TYPE_VECTOR3I: preload("res://addons/hengo/scenes/props/vec3i.tscn"),
	TYPE_VECTOR4: preload("res://addons/hengo/scenes/props/vec4.tscn"),
	TYPE_COLOR: preload("res://addons/hengo/scenes/props/color.tscn")
}

var resource: Resource
var vbox: VBoxContainer


func _init() -> void:
	vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vbox)

# initializes the inspector within the custom popup system
static func edit_resource(_res: Resource) -> void:
	var global: HenGlobal = Engine.get_singleton('Global')
	var scene: PackedScene = load("res://addons/hengo/scenes/custom_inspector.tscn")
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
		if prop.usage & PROPERTY_USAGE_EDITOR:
			_create_prop_editor(prop)


func _create_prop_editor(prop: Dictionary) -> void:
	var prop_scene: PackedScene = PROPS.get(prop.type)
	if not prop_scene:
		return

	var container: HBoxContainer = PROP_CONTAINER.instantiate()
	container.get_node("Name").text = prop.name.capitalize()
	
	var editor: Control = prop_scene.instantiate()
	_configure_editor(editor, prop)
	
	container.add_child(editor)
	vbox.add_child(container)


func _configure_editor(editor: Control, prop: Dictionary) -> void:
	var value = resource.get(prop.name)
	
	if prop.type == TYPE_BOOL:
		editor.set_default(value)
	elif prop.type == TYPE_COLOR:
		editor.set_default(value)
	else:
		editor.set_default(str(value))

	if editor.has_signal("value_changed"):
		editor.value_changed.connect(func(new_val):
			_on_value_changed(prop.name, new_val, prop.type)
		)


func _on_value_changed(prop_name: String, new_val, type: int) -> void:
	var final_val = new_val
	
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
		
	# native undo redo
	if Engine.is_editor_hint():
		var undo_redo: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
		if undo_redo:
			undo_redo.create_action("Set " + prop_name)
			undo_redo.add_do_property(resource, prop_name, final_val)
			undo_redo.add_undo_property(resource, prop_name, resource.get(prop_name))
			undo_redo.commit_action()
			return

	resource.set(prop_name, final_val)