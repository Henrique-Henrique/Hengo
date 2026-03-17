@tool
class_name HenInspector extends VBoxContainer

const PROP_CONTAINER: PackedScene = preload('res://addons/hengo/scenes/prop_container.tscn')
const TITLE_FONT: Font = preload('res://addons/hengo/assets/fonts/bold.ttf')
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
var header_panel: PanelContainer
var header_margin: MarginContainer
var header_box: HBoxContainer
var title_label: Label
var actions_box: HBoxContainer
var body_scroll: ScrollContainer
var vbox: VBoxContainer
var inspector_title: String = ''
var inspector_actions: Array[Dictionary] = []


func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override('separation', int(8 * _get_ui_scale()))

	header_panel = PanelContainer.new()
	header_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_header_panel_style()
	add_child(header_panel)

	header_margin = MarginContainer.new()
	header_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_margin.add_theme_constant_override('margin_top', int(4 * _get_ui_scale()))
	header_margin.add_theme_constant_override('margin_bottom', int(4 * _get_ui_scale()))
	header_margin.add_theme_constant_override('margin_left', int(8 * _get_ui_scale()))
	header_margin.add_theme_constant_override('margin_right', int(8 * _get_ui_scale()))
	header_panel.add_child(header_margin)

	header_box = HBoxContainer.new()
	header_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	header_box.add_theme_constant_override('separation', int(10 * _get_ui_scale()))
	header_margin.add_child(header_box)

	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.clip_text = true
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.add_theme_font_override('font', TITLE_FONT)
	title_label.add_theme_font_size_override('font_size', int(18 * _get_ui_scale()))
	title_label.add_theme_color_override('font_color', Color('#f3f4f6'))
	header_box.add_child(title_label)

	actions_box = HBoxContainer.new()
	actions_box.alignment = BoxContainer.ALIGNMENT_END
	actions_box.add_theme_constant_override('separation', int(6 * _get_ui_scale()))
	header_box.add_child(actions_box)

	body_scroll = ScrollContainer.new()
	body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(body_scroll)

	vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.add_child(vbox)


# initializes the inspector within the custom popup system
static func edit_resource(_res: Resource, _title: String = '', _actions: Array[Dictionary] = []) -> void:
	var global: HenGlobal = Engine.get_singleton('Global')
	var scene: PackedScene = load('res://addons/hengo/scenes/custom_inspector.tscn')
	var inspector: HenInspector = scene.instantiate()
	
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(inspector)
	inspector.edit(_res, _title, _actions)

	global.CURRENT_INSPECTOR = inspector
	inspector.grab_focus()


func edit(_res: Resource, _title: String = '', _actions: Array[Dictionary] = []) -> void:
	resource = _res
	inspector_title = _title
	inspector_actions = _actions

	_update_header()
	_update_props()
	
	if not _res.property_list_changed.is_connected(_update_props): _res.property_list_changed.connect(_update_props)


func _update_header() -> void:
	var text: String = inspector_title.strip_edges()
	if text.is_empty():
		text = _get_default_title()
	title_label.text = text

	for child in actions_box.get_children():
		child.queue_free()

	for action in inspector_actions:
		var bt: Button = _create_action_button(action)
		if bt:
			actions_box.add_child(bt)


func _update_props() -> void:
	for child in vbox.get_children():
		child.queue_free()

	if not resource:
		return

	var prop_index: int = 0
	for prop in resource.get_property_list():
		if _is_tool_button_property(prop):
			_create_tool_button(prop, prop_index)
			prop_index += 1
			continue

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


func _create_tool_button(prop: Dictionary, prop_index: int) -> void:
	if prop_index > 0:
		var separator := HSeparator.new()
		vbox.add_child(separator)

	var action_callable: Variant = resource.get(prop.name)
	var hint_data: Dictionary = _parse_tool_button_hint(prop)

	var bt := Button.new()
	bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bt.text = str(hint_data.get('text', prop.name.capitalize()))

	var icon_name: String = str(hint_data.get('icon', ''))
	if not icon_name.is_empty() and has_theme_icon(icon_name, &"EditorIcons"):
		bt.icon = get_theme_icon(icon_name, &"EditorIcons")

	if action_callable is Callable:
		var callable_value: Callable = action_callable as Callable
		bt.disabled = not callable_value.is_valid()
		if callable_value.is_valid():
			bt.pressed.connect(func():
				callable_value.call()
			)
	else:
		bt.disabled = true

	var container: VBoxContainer = PROP_CONTAINER.instantiate()
	var label: Label = container.get_node('Name')
	label.visible = false
	container.add_child(bt)

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
		elif target_resource is HenSaveParam and prop.name == 'type':
			dropdown.type = 'all_godot_classes'
	
	if prop.type == TYPE_BOOL:
		editor.set_default(value)
	elif prop.type == TYPE_COLOR:
		editor.set_default(value)
	elif prop.type == TYPE_ARRAY:
		if editor.has_method('setup'):
			editor.call('setup', target_resource, prop.name, value, prop.hint_string, p_depth, p_path)
	else:
		if prop.type == TYPE_STRING and str(value) == '<null>':
			editor.set_default('')
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
	
	if prop_name == 'type' and (resource is HenSaveVar or resource is HenSaveParam):
		_update_props()
		(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()


func undo_redo(_undo: bool) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global or not global.history:
		return

	if _undo:
		global.history.undo()
	else:
		global.history.redo()


func get_prop_scene(target_resource: Resource, prop: Dictionary) -> PackedScene:
	var dropdown_prop = load('res://addons/hengo/scenes/props/dropdown.tscn')
	if (prop.type == TYPE_STRING or prop.type == TYPE_STRING_NAME) and _is_dropdown_hint(prop.hint_string):
		return dropdown_prop
	if target_resource is HenSaveParam and prop.name == 'type':
		return dropdown_prop
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


func _instantiate_editor(prop_scene: PackedScene, prop: Dictionary) -> Control:
	var editor: Control = prop_scene.instantiate()
	if editor:
		return editor

	var scene_path: String = prop_scene.resource_path if prop_scene else '<null>'
	push_error("Could not instantiate editor scene for prop '%s' (type: %s, hint: '%s') from '%s'." % [prop.name, str(prop.type), str(prop.hint_string), scene_path])
	return null


func _is_dropdown_hint(hint: String) -> bool:
	return DROPDOWN_HINT_TYPES.has(hint)


func _is_tool_button_property(prop: Dictionary) -> bool:
	return prop.type == TYPE_CALLABLE and int(prop.get('hint', PROPERTY_HINT_NONE)) == PROPERTY_HINT_TOOL_BUTTON and bool(prop.usage & PROPERTY_USAGE_EDITOR)


# parses tool button hint string
func _parse_tool_button_hint(prop: Dictionary) -> Dictionary:
	var default_text: String = str(prop.name).capitalize()
	var hint: String = str(prop.get('hint_string', ''))

	if hint.is_empty():
		return {
			text = default_text,
			icon = ''
		}

	var parts: PackedStringArray = hint.split(',', false, 1)
	var text: String = parts[0].strip_edges() if parts.size() > 0 else default_text
	var icon: String = parts[1].strip_edges() if parts.size() > 1 else ''

	if text.is_empty():
		text = default_text

	return {
		text = text,
		icon = icon
	}


func _get_default_title() -> String:
	if not resource:
		return 'Inspector'

	if resource.has_method('get'):
		var resource_name: Variant = resource.get('name')
		if resource_name is String and not (resource_name as String).is_empty():
			return str(resource_name)

	return resource.get_class()


func _create_action_button(action: Dictionary) -> Button:
	if not action is Dictionary:
		return null

	var action_callable: Callable = action.get('callable', Callable())
	if not action_callable.is_valid():
		return null

	var bt := Button.new()
	bt.text = str(action.get('name', 'Action'))
	bt.tooltip_text = str(action.get('tooltip', ''))
	
	var icon_value: Variant = action.get('icon', null)
	if icon_value is Texture2D:
		bt.icon = icon_value
	elif icon_value is String:
		var icon_res: Resource = load(icon_value)
		if icon_res is Texture2D:
			bt.icon = icon_res as Texture2D

	var color_value: Variant = action.get('color', null)
	if color_value is Color:
		_apply_button_color(bt, color_value as Color)

	bt.pressed.connect(func():
		var args: Variant = action.get('args', [])
		if args is Array and not (args as Array).is_empty():
			action_callable.callv(args)
		elif bool(action.get('pass_resource', false)):
			action_callable.call(resource)
		else:
			action_callable.call()
	)

	return bt


func _apply_button_color(bt: Button, color: Color) -> void:
	bt.self_modulate = color


func _apply_header_panel_style() -> void:
	header_panel.add_theme_stylebox_override('panel', StyleBoxEmpty.new())


func _get_ui_scale() -> float:
	if Engine.is_editor_hint():
		return EditorInterface.get_editor_scale()
	return 1.0
