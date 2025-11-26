class_name HenUtils extends Node

const NONE_ICON = preload('res://addons/hengo/assets/icons/menu/none.svg')

static func move_array_item(_arr: Array, _ref, _factor: int) -> bool:
	var target_idx: int = _arr.find(_ref) - _factor
	var can_move: bool = false

	match _factor:
		1:
			can_move = target_idx >= 0
		(-1):
			can_move = target_idx < _arr.size()

	if can_move:
		var value_to_change = _arr[target_idx]
		_arr[target_idx] = _ref
		_arr[target_idx + _factor] = value_to_change

	return can_move


static func move_array_item_to_idx(_arr: Array, _ref, _pos: int) -> void:
	var value_to_change = _arr[_pos]
	var old_pos: int = _arr.find(_ref)

	_arr[_pos] = _ref
	_arr[old_pos] = value_to_change


static func is_type_relation_valid(_type: StringName, _to_type: StringName) -> bool:
	# check if type is the same e.g. String == String
	if _type == _to_type:
		return true

	# check if one of the types are Variant e.g. Variant <-> Object
	if _type == &'Variant' or _to_type == &'Variant':
		return true

	# check some rules for types e.g. String <-> StringName
	if HenEnums.RULES_TO_CONNECT.has(_to_type):
		if HenEnums.RULES_TO_CONNECT[_to_type].has(_type):
			return true

	# check if class is from Node, this is useful when using methods like "get_node" e.g. Node -> BaseButton
	if _type == &'Node' and ClassDB.is_parent_class(_to_type, &'Node'):
		return true

	# check if type inherits the other type e.g. Control -> Button
	if ClassDB.is_parent_class(_type, _to_type):
		return true

	# denies if none is true
	return false


static func reposition_control_inside(_control: Control) -> void:
	var rect: Rect2 = (Engine.get_singleton(&'Global') as HenGlobal).CNODE_UI.get_viewport_rect()

	# x
	if _control.position.x + _control.size.x > rect.position.x + rect.size.x:
		_control.position.x = rect.position.x + rect.size.x - _control.size.x - 8
	
	if _control.position.x < rect.position.x:
		_control.position.x = rect.position.x + 8
	
	# y
	if _control.position.y + _control.size.y > rect.position.y + rect.size.y:
		_control.position.y = rect.position.y + rect.size.y - _control.size.y - 8
	elif _control.position.y < rect.position.y:
		_control.position.y = rect.position.y + 8
	

static func disable_scene_with_owner(_ref: Node) -> bool:
	var can_disable: bool = EditorInterface.get_edited_scene_root() == _ref or EditorInterface.get_edited_scene_root() == _ref.owner

	if can_disable:
		_ref.set_process(false)
		_ref.set_physics_process(false)
		_ref.set_process_input(false)
		_ref.set_process_unhandled_input(false)
		_ref.set_process_unhandled_key_input(false)
	
	return can_disable


static func disable_scene(_ref: Node) -> bool:
	var can_disable: bool = EditorInterface.get_edited_scene_root() == _ref

	if can_disable:
		_ref.set_process(false)
		_ref.set_physics_process(false)
		_ref.set_process_input(false)
		_ref.set_process_unhandled_input(false)
		_ref.set_process_unhandled_key_input(false)
	
	return can_disable


static func get_error_text(_text: String) -> String:
	return "\n[img]res://addons/hengo/assets/icons/terminal/circle-x.svg[/img] [b][color=#dc3545]" + _text + "[/color][color=#ff4757][/color][/b]"

static func get_success_text(_text: String) -> String:
	return "\n[img]res://addons/hengo/assets/icons/terminal/check.svg[/img] [b][color=#28a745]" + _text + "[/color][color=#2ed573][/color][/b]"

static func get_warning_text(_text: String) -> String:
	return "\n[img]res://addons/hengo/assets/icons/terminal/triangle-alert.svg[/img] [b][color=#ffc107]" + _text + "[/color][color=#ffa502][/color][/b]"

static func get_building_text(_text: String) -> String:
	return "\n[img]res://addons/hengo/assets/icons/terminal/chevron-right.svg[/img] [color=#ffffff]" + _text + "[/color][color=#747d8c][/color]"


static func get_text_size(_text: String) -> Vector2:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var font: Font = global.HENGO_ROOT.get_theme_font(&'font', &'Control')
	var font_size: int = global.HENGO_ROOT.get_theme_font_size(&'font_size', &'Control')
	return font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)


static func get_icon_texture(_type: StringName) -> Texture2D:
	if EditorInterface.get_editor_theme().has_icon(_type, &'EditorIcons'):
		return EditorInterface.get_editor_theme().get_icon(_type, &'EditorIcons')
	
	return NONE_ICON


static func load_res(_id: int, _sub_type: HenVirtualCNode.SubType, _res_id: int = -1) -> Resource:
	var res_id: int = 0

	if _res_id == -1:
		var global: HenGlobal = Engine.get_singleton(&'Global')
		res_id = global.SAVE_DATA.id

	var SAVE_PATH: String = 'res://hengo/save_2/'
	var script_id: StringName = str(res_id)
	var script_path: StringName = SAVE_PATH + script_id

	match _sub_type:
		HenVirtualCNode.SubType.VAR, \
		HenVirtualCNode.SubType.SET_VAR:
			return load(script_path + '/variables/' + str(_id) + '.tres')

	return null