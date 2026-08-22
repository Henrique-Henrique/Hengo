@tool
class_name HenDropdown extends Button

const DROP_DOWN_MENU_SCENE: PackedScene = preload('res://addons/hengo/scenes/drop_down_menu.tscn')

var options: Array = []
@export var type: String = ''
var custom_data
var custom_value: String = ''

signal value_changed
signal on_set_res_data


func _ready() -> void:
	button_down.connect(_on_pressed)


# every mapped script as a type option, labeled with the class it extends
static func get_hengo_script_types() -> Array:
	var map_dep: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var arr: Array = []

	if not map_dep:
		return arr

	for script_id: StringName in map_dep.ast_list:
		var ast: HenMapDependencies.ProjectAST = map_dep.ast_list[script_id]

		if not ast.identity:
			continue

		if global and global.SAVE_DATA and global.SAVE_DATA.identity and ast.identity.id == global.SAVE_DATA.identity.id:
			continue

		arr.append({
			name = ast.identity.name + ' (' + str(ast.identity.type) + ')',
			type = ast.identity.type,
			script_id = ast.identity.id
		})

	return arr


func _selected(_item: Dictionary) -> void:
	text = _item.name

	HenCam.set_all_can_scroll(get_tree(), true)

	match type:
		'var_type':
			# a script option carries its base class plus the identity to remember;
			# both cases travel together so type and script_id never disagree
			if _item.has('script_id'):
				on_set_res_data.emit(_item)
			else:
				on_set_res_data.emit({type = _item.name, script_id = &''})
			return
		'hengo_states':
			text = (_item.name as String).to_snake_case()
		'enum_list':
			text = _item.name
			custom_value = _item.code_name
			emit_signal('value_changed', custom_value)
			return
		'all_props':
			emit_signal('value_changed', text, text.to_snake_case())
			return
		'get_prop':
			emit_signal('value_changed', text, _item.type)
			return


	value_changed.emit(text)

func set_font_size(_size: int) -> void:
	add_theme_font_size_override('font_size', _size)


func set_default(_text: String) -> void:
	match type:
		'enum_list':
			text = _text.split('.')[-1] as String
			custom_value = _text
		_:
			text = _text


func get_value() -> String:
	match type:
		'enum_list':
			return custom_value
		_:
			return text


func get_generated_code() -> String:
	match type:
		'enum_list':
			return custom_value
		'all_props', 'callable':
			return text.to_snake_case()
		'get_prop', 'set_prop':
			return text.replacen(' -> ', '.')

	return text


func get_const_list(_arr: Array, _type: StringName, _name: String, _prop_type: StringName, _check_type: bool = true) -> Array:
	var enums: HenEnums = Engine.get_singleton(&'Enums')
	if enums.NATIVE_PROPS_LIST.has(_prop_type):
		for prop: Dictionary in enums.NATIVE_PROPS_LIST.get(_prop_type):
			var my_name: String = _name + ' -> ' + prop.name

			if _check_type:
				if _type == 'Variant' or prop.type == _type:
					_arr.append({
						name = my_name,
						value = my_name.replacen(' -> ', '.')
					})
					continue
			else:
				_arr.append({
						name = my_name,
						value = my_name.replacen(' -> ', '.'),
						type = prop.type
					})

			get_const_list(_arr, _type, my_name, prop.type, _check_type)

	return _arr

func _on_pressed() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	match type:
		'action':
			var arr: Array = []

			for dict in ProjectSettings.get_property_list():
				if dict.name.begins_with('input/'):
					arr.append({
						name = dict.name.substr(dict.name.find('/') + 1, dict.name.length())
					})

			options = arr
		'all_godot_classes':
			options = (HenEnums.VARIANT_TYPES + ClassDB.get_class_list() as Array).map(func(x: String): return {
				name = x
			})
		'var_type':
			# project scripts come first: a variable holding one keeps its identity
			options = get_hengo_script_types()
			options.append_array((HenEnums.VARIANT_TYPES + ClassDB.get_class_list() as Array).map(func(x: String): return {
				name = x
			}))
		'hengo_states':
			options = global.SCRIPTS_STATES[custom_data] if global.SCRIPTS_STATES.has(custom_data) else []
		'all_classes':
			options = (Engine.get_singleton(&'Enums') as HenEnums).DROPDOWN_ALL_CLASSES
		'all_classes_self':
			options = [ {name = 'SELF'}]
			options.append_array((Engine.get_singleton(&'Enums') as HenEnums).DROPDOWN_ALL_CLASSES)
		'enum_list':
			var enum_reference: Dictionary = {}

			for enum_name in ClassDB.class_get_enum_constants(custom_data[0], custom_data[1]):
				enum_reference[enum_name] = '.'.join(custom_data) + '.' + enum_name

			options = enum_reference.keys().map(func(x: String) -> Dictionary: return {name = x, code_name = enum_reference[x]}) if not enum_reference.is_empty() else []
		'signal':
			options = ClassDB.class_get_signal_list(custom_data).map(func(x): return {
				name = x.name
			})
		'callable':
			options = []
		'key_code':
			var arr: Array = []
			var key_list: Array = [
				'KEY_SPACE', 'KEY_ESCAPE', 'KEY_TAB', 'KEY_BACKSPACE', 'KEY_ENTER',
				'KEY_UP', 'KEY_DOWN', 'KEY_LEFT', 'KEY_RIGHT',
				'KEY_A', 'KEY_B', 'KEY_C', 'KEY_D', 'KEY_E', 'KEY_F', 'KEY_G', 'KEY_H',
				'KEY_I', 'KEY_J', 'KEY_K', 'KEY_L', 'KEY_M', 'KEY_N', 'KEY_O', 'KEY_P',
				'KEY_Q', 'KEY_R', 'KEY_S', 'KEY_T', 'KEY_U', 'KEY_V', 'KEY_W', 'KEY_X',
				'KEY_Y', 'KEY_Z',
				'KEY_0', 'KEY_1', 'KEY_2', 'KEY_3', 'KEY_4', 'KEY_5', 'KEY_6', 'KEY_7',
				'KEY_8', 'KEY_9',
				'KEY_F1', 'KEY_F2', 'KEY_F3', 'KEY_F4', 'KEY_F5', 'KEY_F6',
				'KEY_F7', 'KEY_F8', 'KEY_F9', 'KEY_F10', 'KEY_F11', 'KEY_F12',
				'KEY_SHIFT', 'KEY_CTRL', 'KEY_ALT', 'KEY_META',
				'KEY_INSERT', 'KEY_DELETE', 'KEY_HOME', 'KEY_END', 'KEY_PAGEUP', 'KEY_PAGEDOWN'
			]
			for key_name in key_list:
				arr.append({name = key_name, code_name = key_name})
			options = arr
		'mouse_button':
			var arr: Array = []
			var mouse_list: Array = [
				'MOUSE_BUTTON_LEFT', 'MOUSE_BUTTON_RIGHT', 'MOUSE_BUTTON_MIDDLE',
				'MOUSE_BUTTON_WHEEL_UP', 'MOUSE_BUTTON_WHEEL_DOWN',
				'MOUSE_BUTTON_WHEEL_LEFT', 'MOUSE_BUTTON_WHEEL_RIGHT',
				'MOUSE_BUTTON_XBUTTON1', 'MOUSE_BUTTON_XBUTTON2'
			]
			for btn_name in mouse_list:
				arr.append({name = btn_name, code_name = btn_name})
			options = arr
		'state_event_list':
			pass


	var dropdown_menu: HenDropDownMenu = DROP_DOWN_MENU_SCENE.instantiate()
	dropdown_menu.mount(options, _selected, type)
	dropdown_menu.custom_minimum_size.x = size.x

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(dropdown_menu, {
		layout = HenGeneralPopup.Layout.ANCHORED,
		pos = global_position,
		min_size = Vector2(max(size.x, 220), 280)
	})