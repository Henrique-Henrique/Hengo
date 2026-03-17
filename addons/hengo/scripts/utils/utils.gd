class_name HenUtils extends Node

const NONE_ICON = preload('res://addons/hengo/assets/new_icons/full_circle.svg')

const ICON_FUNCTION = preload('res://addons/hengo/assets/new_icons/square-function.svg')
const ICON_VARIABLE = preload('res://addons/hengo/assets/new_icons/variable.svg')
const ICON_IF = preload('res://addons/hengo/assets/new_icons/git-branch.svg')
const ICON_LOOP = preload('res://addons/hengo/assets/new_icons/repeat.svg')
const ICON_STATE = preload('res://addons/hengo/assets/new_icons/activity.svg')
const ICON_SIGNAL = preload('res://addons/hengo/assets/new_icons/signal.svg')
const ICON_DEBUG = preload('res://addons/hengo/assets/new_icons/bug.svg')
const ICON_VOID = preload('res://addons/hengo/assets/new_icons/circle-slash.svg')
const ICON_INVALID = preload('res://addons/hengo/assets/new_icons/triangle.svg')
const ICON_CODE = preload('res://addons/hengo/assets/new_icons/code.svg')
const ICON_IMAGE = preload('res://addons/hengo/assets/new_icons/image.svg')
const ICON_CALCULATOR = preload('res://addons/hengo/assets/new_icons/calculator.svg')
const ICON_LINK_OFF = preload('res://addons/hengo/assets/new_icons/link-2-off.svg')
const ICON_INPUT = preload('res://addons/hengo/assets/new_icons/file-input.svg')
const ICON_OUTPUT = preload('res://addons/hengo/assets/new_icons/file-output.svg')
const ICON_BOX = preload('res://addons/hengo/assets/new_icons/box.svg')
const ICON_LAYERS = preload('res://addons/hengo/assets/new_icons/layers.svg')
const ICON_PLAY = preload('res://addons/hengo/assets/new_icons/play.svg')
const ICON_TRANSITION = preload('res://addons/hengo/assets/new_icons/arrow-right-left.svg')
const ICON_EVENT = preload('res://addons/hengo/assets/new_icons/sparkles.svg')
const ICON_ROUTE = preload('res://addons/hengo/assets/new_icons/route.svg')
const ICON_PROPERTY = preload('res://addons/hengo/assets/new_icons/sliders-horizontal.svg')
const ICON_GAMEPAD = preload('res://addons/hengo/assets/new_icons/gamepad-2.svg')


const DEPTH_COLORS: Array[Color] = [
	Color('#acacacff'),
	Color('#c6dbffff'),
	Color('#ff8686ff'),
	Color('#782a7a'),
	Color('#b826d1ff'),
]


static func get_depth_color(depth: int) -> Color:
	return DEPTH_COLORS[depth % DEPTH_COLORS.size()]


static func get_icon_for_subtype(_sub_type: int) -> Texture2D:
	match _sub_type:
		HenVirtualCNode.SubType.FUNC, \
		HenVirtualCNode.SubType.USER_FUNC, \
		HenVirtualCNode.SubType.FUNC_FROM, \
		HenVirtualCNode.SubType.MACRO, \
		HenVirtualCNode.SubType.SCRIPT_MACRO:
			return ICON_FUNCTION

		HenVirtualCNode.SubType.VIRTUAL, \
		HenVirtualCNode.SubType.OVERRIDE_VIRTUAL:
			return ICON_LAYERS

		HenVirtualCNode.SubType.FUNC_INPUT, \
		HenVirtualCNode.SubType.MACRO_INPUT:
			return ICON_INPUT

		HenVirtualCNode.SubType.FUNC_OUTPUT, \
		HenVirtualCNode.SubType.MACRO_OUTPUT:
			return ICON_OUTPUT

		HenVirtualCNode.SubType.VAR, \
		HenVirtualCNode.SubType.LOCAL_VAR, \
		HenVirtualCNode.SubType.SET_VAR, \
		HenVirtualCNode.SubType.SET_LOCAL_VAR, \
		HenVirtualCNode.SubType.VAR_FROM, \
		HenVirtualCNode.SubType.SET_VAR_FROM, \
		HenVirtualCNode.SubType.CONST, \
		HenVirtualCNode.SubType.GET_FROM_PROP, \
		HenVirtualCNode.SubType.IN_PROP:
			return ICON_VARIABLE

		HenVirtualCNode.SubType.GET_PROP, \
		HenVirtualCNode.SubType.SET_PROP:
			return ICON_PROPERTY

		HenVirtualCNode.SubType.IF:
			return ICON_IF

		HenVirtualCNode.SubType.FOR, \
		HenVirtualCNode.SubType.FOR_ARR, \
		HenVirtualCNode.SubType.FOR_ITEM:
			return ICON_LOOP

		HenVirtualCNode.SubType.BREAK, \
		HenVirtualCNode.SubType.CONTINUE, \
		HenVirtualCNode.SubType.PASS, \
		HenVirtualCNode.SubType.GO_TO_VOID, \
		HenVirtualCNode.SubType.SELF_GO_TO_VOID:
			return ICON_PLAY

		HenVirtualCNode.SubType.STATE, \
		HenVirtualCNode.SubType.STATE_START:
			return ICON_STATE

		HenVirtualCNode.SubType.SIGNAL_ENTER, \
		HenVirtualCNode.SubType.SIGNAL_CONNECTION, \
		HenVirtualCNode.SubType.SIGNAL_DISCONNECTION:
			return ICON_SIGNAL

		HenVirtualCNode.SubType.DEBUG, \
		HenVirtualCNode.SubType.DEBUG_VALUE, \
		HenVirtualCNode.SubType.DEBUG_PUSH, \
		HenVirtualCNode.SubType.DEBUG_FLOW_START, \
		HenVirtualCNode.SubType.START_DEBUG_STATE, \
		HenVirtualCNode.SubType.DEBUG_STATE:
			return ICON_DEBUG

		HenVirtualCNode.SubType.VOID:
			return ICON_VOID
		
		HenVirtualCNode.SubType.INVALID:
			return ICON_INVALID
		
		HenVirtualCNode.SubType.RAW_CODE:
			return ICON_CODE

		HenVirtualCNode.SubType.IMG:
			return ICON_IMAGE

		HenVirtualCNode.SubType.EXPRESSION:
			return ICON_CALCULATOR

		HenVirtualCNode.SubType.NOT_CONNECTED:
			return ICON_LINK_OFF

		HenVirtualCNode.SubType.CAST:
			return ICON_BOX

		HenVirtualCNode.SubType.MAKE_TRANSITION, \
		HenVirtualCNode.SubType.STATE_TRANSITION, \
		HenVirtualCNode.SubType.STATE_TRANSITION_FROM:
			return ICON_TRANSITION

		HenVirtualCNode.SubType.INPUT_EVENT_CHECK, \
		HenVirtualCNode.SubType.INPUT_ACTION_CHECK, \
		HenVirtualCNode.SubType.INPUT_POLLING:
			return ICON_GAMEPAD

	return null


static func get_color_for_subtype(_sub_type: int) -> Color:
	match _sub_type:
		HenVirtualCNode.SubType.FUNC, \
		HenVirtualCNode.SubType.USER_FUNC, \
		HenVirtualCNode.SubType.FUNC_FROM, \
		HenVirtualCNode.SubType.MACRO, \
		HenVirtualCNode.SubType.SCRIPT_MACRO:
			return Color('#54a0ff')

		HenVirtualCNode.SubType.VIRTUAL, \
		HenVirtualCNode.SubType.OVERRIDE_VIRTUAL:
			return Color('#ff9ff3')

		HenVirtualCNode.SubType.FUNC_INPUT, \
		HenVirtualCNode.SubType.MACRO_INPUT:
			return Color('#ff9ff3')

		HenVirtualCNode.SubType.FUNC_OUTPUT, \
		HenVirtualCNode.SubType.MACRO_OUTPUT:
			return Color('#ff9ff3')

		HenVirtualCNode.SubType.VAR, \
		HenVirtualCNode.SubType.LOCAL_VAR, \
		HenVirtualCNode.SubType.SET_VAR, \
		HenVirtualCNode.SubType.SET_LOCAL_VAR, \
		HenVirtualCNode.SubType.VAR_FROM, \
		HenVirtualCNode.SubType.SET_VAR_FROM, \
		HenVirtualCNode.SubType.CONST, \
		HenVirtualCNode.SubType.GET_FROM_PROP, \
		HenVirtualCNode.SubType.IN_PROP:
			return Color('#1dd1a1')

		HenVirtualCNode.SubType.GET_PROP, \
		HenVirtualCNode.SubType.SET_PROP:
			return Color('#00d2d3')

		HenVirtualCNode.SubType.IF:
			return Color('#ff6b6b')

		HenVirtualCNode.SubType.FOR, \
		HenVirtualCNode.SubType.FOR_ARR, \
		HenVirtualCNode.SubType.FOR_ITEM:
			return Color('#ff6b6b')

		HenVirtualCNode.SubType.BREAK, \
		HenVirtualCNode.SubType.CONTINUE, \
		HenVirtualCNode.SubType.PASS, \
		HenVirtualCNode.SubType.GO_TO_VOID, \
		HenVirtualCNode.SubType.SELF_GO_TO_VOID:
			return Color('#ff6b6b')

		HenVirtualCNode.SubType.STATE, \
		HenVirtualCNode.SubType.STATE_START:
			return Color('#a29bfe')

		HenVirtualCNode.SubType.SIGNAL_ENTER, \
		HenVirtualCNode.SubType.SIGNAL_CONNECTION, \
		HenVirtualCNode.SubType.SIGNAL_DISCONNECTION:
			return Color('#ff6b6b')

		HenVirtualCNode.SubType.DEBUG, \
		HenVirtualCNode.SubType.DEBUG_VALUE, \
		HenVirtualCNode.SubType.DEBUG_PUSH, \
		HenVirtualCNode.SubType.DEBUG_FLOW_START, \
		HenVirtualCNode.SubType.START_DEBUG_STATE, \
		HenVirtualCNode.SubType.DEBUG_STATE:
			return Color('#c8d6e5')

		HenVirtualCNode.SubType.VOID:
			return Color('#d1d9e0')
		
		HenVirtualCNode.SubType.RAW_CODE:
			return Color('#feca57')

		HenVirtualCNode.SubType.EXPRESSION:
			return Color('#ff9f43')

		HenVirtualCNode.SubType.MAKE_TRANSITION, \
		HenVirtualCNode.SubType.STATE_TRANSITION, \
		HenVirtualCNode.SubType.STATE_TRANSITION_FROM:
			return Color('#6c5ce7')

		HenVirtualCNode.SubType.INPUT_EVENT_CHECK, \
		HenVirtualCNode.SubType.INPUT_ACTION_CHECK, \
		HenVirtualCNode.SubType.INPUT_POLLING:
			return Color('#ef5777')

	return Color('#343434')

static func move_array_item(_arr: Array, _ref, _factor: int) -> bool:
	var target_idx: int = _arr.find(_ref) - _factor
	var can_move: bool = false

	match _factor:
		1:
			can_move = target_idx >= 0
		(-1):
			can_move = target_idx < _arr.size()

	if can_move:
		var value_to_change: Variant = _arr[target_idx]
		_arr[target_idx] = _ref
		_arr[target_idx + _factor] = value_to_change

	return can_move


static func move_array_item_to_idx(_arr: Array, _ref, _pos: int) -> void:
	var value_to_change: Variant = _arr[_pos]
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
		if (HenEnums.RULES_TO_CONNECT[_to_type] as Array).has(_type):
			return true

	# check if class is from Node, this is useful when using methods like "get_node" e.g. Node -> BaseButton
	if _type == &'Node' and ClassDB.is_parent_class(_to_type, &'Node'):
		return true

	# check if type inherits the other type e.g. Control -> Button
	if ClassDB.is_parent_class(_type, _to_type):
		return true

	# denies if none is true
	return false


static func get_variant_type_from_string(type_name: StringName) -> int:
	for i in TYPE_MAX:
		if type_string(i) == type_name:
			return i
	
	return TYPE_NIL


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
	return '\n[img]res://addons/hengo/assets/icons/terminal/circle-x.svg[/img] [b][color=#dc3545]' + _text + '[/color][color=#ff4757][/color][/b]'

static func get_success_text(_text: String) -> String:
	return '\n[img]res://addons/hengo/assets/icons/terminal/check.svg[/img] [b][color=#28a745]' + _text + '[/color][color=#2ed573][/color][/b]'

static func get_warning_text(_text: String) -> String:
	return '\n[img]res://addons/hengo/assets/icons/terminal/triangle-alert.svg[/img] [b][color=#ffc107]' + _text + '[/color][color=#ffa502][/color][/b]'

static func get_building_text(_text: String) -> String:
	return '\n[img]res://addons/hengo/assets/icons/terminal/chevron-right.svg[/img] [color=#ffffff]' + _text + '[/color][color=#747d8c][/color]'


static func get_text_size(_text: String) -> Vector2:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var font: Font = global.HENGO_ROOT.get_theme_font(&'font', &'Control')
	var font_size: int = global.HENGO_ROOT.get_theme_font_size(&'font_size', &'Control')
	return font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)


static func get_icon_texture(_type: StringName) -> Texture2D:
	if EditorInterface.get_editor_theme().has_icon(_type, &'EditorIcons'):
		return EditorInterface.get_editor_theme().get_icon(_type, &'EditorIcons')
	
	return NONE_ICON


static func get_type_parent_color(_type: StringName, _alpha: float = 1.0, _default: Color = Color('#0000004a')) -> Color:
	# returns color based on specific type or class inheritance
	match _type:
		&'Getter':
			return Color('#1ABC9C', _alpha)
		&'Setter':
			return Color('#FF7675', _alpha)
		&'Function':
			return Color('#3498DB', _alpha)
		&'Variable':
			return Color('#2ECC71', _alpha)
		&'State':
			return Color('#E74C3C', _alpha)
		&'State Transition', &'Sub State Transition':
			return Color('#E67E22', _alpha)
		&'Signal':
			return Color('#F1C40F', _alpha)
		&'Macro':
			return Color('#9B59B6', _alpha)
		&'String':
			return Color('#8eef97', _alpha)
		&'float':
			return Color('#FFDD65', _alpha)
		&'int':
			return Color('#5ABBEF', _alpha)
		&'bool':
			return Color('#FC7F7F', _alpha)
		&'Variant':
			return Color('#72788a', _alpha)

	if ClassDB.is_parent_class(_type, 'Node2D'):
		return Color('#6E90E7', _alpha)
	elif ClassDB.is_parent_class(_type, 'Node3D'):
		return Color('#E96266', _alpha)
	elif ClassDB.is_parent_class(_type, 'Control'):
		return Color('#67DE7A', _alpha)
	elif ClassDB.is_parent_class(_type, 'AnimationMixer'):
		return Color('#AC76E5', _alpha)
	elif ClassDB.is_parent_class(_type, 'CanvasLayer'):
		return Color('#E0BF48', _alpha)

	return _default


# extracts the id directly from the resource object
static func get_res_parent_id(res: HenSaveResType) -> String:
	var path: String = res.resource_path
	var parts: PackedStringArray = path.split('/')

	if parts.size() <= 4 or parts[4].is_empty() or not parts[4].is_valid_int():
		return ''

	return parts[4]


static func get_dependency_hash(res: Resource) -> int:
	var hash_val: int = 0
	
	if res is HenSaveVar:
		var v: HenSaveVar = res as HenSaveVar
		hash_val = (v.name + str(v.type)).hash()
	elif res is HenSaveFunc:
		var f: HenSaveFunc = res as HenSaveFunc
		var signature: String = f.name
		
		for p: HenSaveParam in f.inputs:
			signature += p.name + str(p.type)
			
		for p: HenSaveParam in f.outputs:
			signature += p.name + str(p.type)
			
		hash_val = signature.hash()
	elif res is HenSaveSignal:
		var s: HenSaveSignal = res as HenSaveSignal
		var signature: String = s.name
		
		for p: HenSaveParam in s.inputs:
			signature += p.name + str(p.type)
			
		hash_val = signature.hash()
	elif res is HenSaveMacro:
		var m: HenSaveMacro = res as HenSaveMacro
		hash_val = m.name.hash()
		
	return hash_val


static func get_dependency_type(res: Resource) -> HenEnums.DependencyType:
	if res is HenSaveVar:
		return HenEnums.DependencyType.VAR
	elif res is HenSaveFunc:
		return HenEnums.DependencyType.FUNC
	elif res is HenSaveSignal:
		return HenEnums.DependencyType.SIGNAL
	elif res is HenSaveMacro:
		return HenEnums.DependencyType.MACRO
		
	return HenEnums.DependencyType.VAR


# returns the scaled size for high dpi displays
static func get_scaled_size(base_size: int) -> int:
	return int(base_size * EditorInterface.get_editor_scale())


static func is_circular_dependent(_sub_type: HenVirtualCNode.SubType) -> bool:
	match _sub_type:
		HenVirtualCNode.SubType.FUNC_INPUT, \
		HenVirtualCNode.SubType.FUNC_OUTPUT, \
		HenVirtualCNode.SubType.MACRO_INPUT, \
		HenVirtualCNode.SubType.MACRO_OUTPUT, \
		HenVirtualCNode.SubType.SIGNAL_ENTER:
			return true
		
	return false


# returns the specific path based on the provided enum type
static func get_side_bar_item_path(_save_data_id: StringName, _type: HenSideBar.SideBarItem) -> StringName:
	var base_path: StringName = HenEnums.HENGO_SAVE_PATH + _save_data_id
	var suffix: String = ''

	match _type:
		HenSideBar.SideBarItem.VARIABLES:
			suffix = '/variables/'
		HenSideBar.SideBarItem.FUNCTIONS:
			suffix = '/functions/'
		HenSideBar.SideBarItem.SIGNALS:
			suffix = '/signals/'
		HenSideBar.SideBarItem.SIGNALS_CALLBACK:
			suffix = '/signals_callback/'
		HenSideBar.SideBarItem.MACROS:
			suffix = '/macros/'
		HenSideBar.SideBarItem.STATES:
			suffix = '/states/'

	return base_path + suffix


static func save_side_bar_item(_res: Resource, _save_data_id: StringName, _type: HenSideBar.SideBarItem) -> bool:
	var path: StringName = get_side_bar_item_path(_save_data_id, _type)

	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_absolute(path)
	
	_res.take_over_path(path + str(_res.get(&'id')) + HenEnums.SAVE_EXTENSION)
	var result: int = ResourceSaver.save(_res)
	return result == OK


static func get_current_ast_list() -> HenMapDependencies.ProjectAST:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var ast: HenMapDependencies.ProjectAST = HenMapDependencies.ProjectAST.new()

	ast.identity = global.SAVE_DATA.identity
	ast.macros = global.SAVE_DATA.macros + global.script_macros
	ast.variables = global.SAVE_DATA.variables
	ast.functions = global.SAVE_DATA.functions
	ast.signals = global.SAVE_DATA.signals
	ast.signals_callback = global.SAVE_DATA.signals_callback
	ast.states = global.SAVE_DATA.states

	return ast


static func get_res(_res_data: Dictionary, _save_data: HenSaveData) -> Resource:
	if _res_data.has('id') and _res_data.has('type'):
		var list: Array = []

		if _res_data.has('save_data_id'):
			var map_deps: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
			
			if map_deps.ast_list.has(_res_data.save_data_id):
				var ast: HenMapDependencies.ProjectAST = map_deps.ast_list[_res_data.save_data_id]
				
				match _res_data.type:
					HenSideBar.AddType.VAR:
						list = ast.variables
					HenSideBar.AddType.FUNC:
						list = ast.functions
					HenSideBar.AddType.SIGNAL_CALLBACK:
						list = ast.signals_callback
					HenSideBar.AddType.SIGNAL:
						list = ast.signals
					HenSideBar.AddType.MACRO:
						list = ast.macros
					HenSideBar.AddType.STATE:
						list = ast.states
		else:
			match _res_data.type:
				HenSideBar.AddType.VAR:
					list = _save_data.variables
				HenSideBar.AddType.FUNC:
					list = _save_data.functions
				HenSideBar.AddType.SIGNAL_CALLBACK:
					list = _save_data.signals_callback
				HenSideBar.AddType.SIGNAL:
					list = _save_data.signals
				HenSideBar.AddType.MACRO:
					list = _save_data.macros.duplicate()
					list.append_array((Engine.get_singleton(&'Global') as HenGlobal).script_macros)
				HenSideBar.AddType.STATE:
					list = _save_data.states
				HenSideBar.AddType.LOCAL_VAR:
					var check_list: Callable = func(l: Array) -> HenSaveParam:
						for item: Variant in l:
							if item is HenSaveResTypeWithRoute:
								for lv: HenSaveParam in item.local_vars:
									if lv.id == _res_data.id:
										return lv
						return null

					var found: HenSaveParam = check_list.call(_save_data.functions)
					if not found: found = check_list.call(_save_data.macros)
					if not found: found = check_list.call(_save_data.states)
					if not found:
						for sub_list: Array in _save_data.sub_states.values():
							found = check_list.call(sub_list)
							if found: break
					
					if found: return found
		
		for item: Variant in list:
			if item.id == _res_data.id:
				return item
			
		if not _res_data.has('save_data_id') and _res_data.type == HenSideBar.AddType.STATE:
			for sub_states: Array in _save_data.sub_states.values():
				for s: HenSaveState in sub_states:
					if s.id == _res_data.id:
						return s

	return null
