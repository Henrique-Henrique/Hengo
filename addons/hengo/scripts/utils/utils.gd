@tool
class_name HenUtils extends Node

# an action binding stores 'var:<id>' for a hengo variable and the bare name for a
# native property, so renaming a variable can't silently break the generated code
const BIND_VAR_PREFIX: String = 'var:'
# bind to an input of the function or macro the action runs inside, which reaches
# the caller's value instead of anything the script holds
const BIND_ARG_PREFIX: String = 'arg:'
# bind to a node reached by path instead of a variable, so a sibling node can be
# used without declaring anything
const BIND_PATH_PREFIX: String = 'path:'

# values the engine already gives away, offered in the bind picker alongside
# variables and properties. `global` marks a code that stands alone instead of
# reading off the owner, and needs_class limits a source to owners that have it.
# a code must be atomic or parenthesized: it substitutes mid-expression.
# a source with `key` takes an argument and is stored as "key:argument", its code
# coming from code_format; label_format defaults to "name (argument)"
# arg_picker names the menu that fills the argument instead of a text field, and
# arg_example is an argument the code is known to compile with
const NATIVE_SOURCES: Array[Dictionary] = [
	{
		name = 'Self (this node)',
		code = '_ref',
		type = 'Node',
		needs_class = &'',
		global = true,
		kind = &'node'
	},
	{
		name = 'Node path',
		key = 'path',
		arg_prompt = 'Node Path',
		arg_picker = &'node_path',
		code_format = 'get_node("{arg}")',
		label_format = '{arg}',
		type = 'Node',
		needs_class = &'Node',
		global = false,
		kind = &'node'
	},
	{
		name = 'Action strength',
		key = 'action_strength',
		arg_prompt = 'Input Action',
		code_format = 'Input.get_action_strength("{arg}")',
		type = 'float',
		needs_class = &'',
		global = true
	},
	{
		name = 'Action pressed',
		key = 'action_pressed',
		arg_prompt = 'Input Action',
		code_format = 'Input.is_action_pressed("{arg}")',
		type = 'bool',
		needs_class = &'',
		global = true
	},
	# the key is an engine constant, so it is the one argument that is not quoted
	{
		name = 'Key pressed',
		key = 'key_pressed',
		arg_prompt = 'Key, such as KEY_SHIFT',
		arg_example = 'KEY_SHIFT',
		code_format = 'Input.is_key_pressed({arg})',
		type = 'bool',
		needs_class = &'',
		global = true
	},
	{
		name = 'Mouse button pressed',
		key = 'mouse_pressed',
		arg_prompt = 'Button, such as MOUSE_BUTTON_LEFT',
		arg_example = 'MOUSE_BUTTON_LEFT',
		code_format = 'Input.is_mouse_button_pressed({arg})',
		type = 'bool',
		needs_class = &'',
		global = true
	},
	{
		name = 'Mouse Position',
		code = 'get_global_mouse_position()',
		type = 'Vector2',
		needs_class = &'CanvasItem',
		global = false
	},
	{
		name = 'Mouse X',
		code = 'get_global_mouse_position().x',
		type = 'float',
		needs_class = &'CanvasItem',
		global = false
	},
	{
		name = 'Mouse Y',
		code = 'get_global_mouse_position().y',
		type = 'float',
		needs_class = &'CanvasItem',
		global = false
	},
	{
		name = 'Mouse Screen Position',
		code = 'get_viewport().get_mouse_position()',
		type = 'Vector2',
		needs_class = &'Node',
		global = false
	},
	{
		name = 'Screen Size',
		code = 'get_viewport().get_visible_rect().size',
		type = 'Vector2',
		needs_class = &'Node',
		global = false
	},
	{
		name = 'Any Key Pressed',
		code = 'Input.is_anything_pressed()',
		type = 'bool',
		needs_class = &'',
		global = true
	},
	{
		name = 'Delta',
		code = 'get_process_delta_time()',
		type = 'float',
		needs_class = &'Node',
		global = false
	},
	{
		name = 'Speed',
		code = 'linear_velocity.length()',
		type = 'float',
		needs_class = &'RigidBody3D',
		global = false
	},
	{
		name = 'Velocity',
		code = 'linear_velocity',
		type = 'Vector3',
		needs_class = &'RigidBody3D',
		global = false
	},
	{
		name = 'Random Float (0-1)',
		code = 'randf()',
		type = 'float',
		needs_class = &'',
		global = true
	},
	{
		name = 'Random Bool',
		code = '(randf() < 0.5)',
		type = 'bool',
		needs_class = &'',
		global = true
	},
	{
		name = 'Random Angle',
		code = '(randf() * TAU)',
		type = 'float',
		needs_class = &'',
		global = true
	},
	{
		name = 'Random Direction',
		code = 'Vector2.from_angle(randf() * TAU)',
		type = 'Vector2',
		needs_class = &'',
		global = true
	},
	{
		name = 'Random Color',
		code = 'Color(randf(), randf(), randf())',
		type = 'Color',
		needs_class = &'',
		global = true
	}
]

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
const ICON_LITERAL = preload('res://addons/hengo/assets/new_icons/shapes.svg')
const ICON_EQUAL = preload('res://addons/hengo/assets/new_icons/equal.svg')
const ICON_BINARY = preload('res://addons/hengo/assets/new_icons/binary.svg')
const ICON_PLUS = preload('res://addons/hengo/assets/new_icons/plus.svg')

const DEPTH_COLORS: Array[Color] = [
	Color('#acacacff'),
	Color('#c6dbffff'),
	Color('#ff8686ff'),
	Color('#782a7a'),
	Color('#b826d1ff'),
]

# semantic ui palette — color icons/text by what the action does
const UI_COLORS = {
	create = Color('#2ECC71'),
	compile = Color('#3B7DE8'),
	flow = Color('#5DADE2'),
	state = Color('#E67E22'),
	code = Color('#9B59B6'),
	settings = Color('#9CA8B5'),
	destructive = Color('#E57373'),
	dashboard = Color('#F59E0B'),
	rename = Color('#F39C12'),
	info_yellow = Color('#F1C40F'),
	web = Color('#1ABC9C'),
	layout = Color('#5DADE2'),
}


static var _script_dir_index: Dictionary = {}

static func get_depth_color(depth: int) -> Color:
	return DEPTH_COLORS[depth % DEPTH_COLORS.size()]


# applies a semantic color to a button's icon (and text when it has any)
static func tint_button(_bt: Button, _color: Color, _tint_text: bool = true) -> void:
	_bt.add_theme_color_override(&'icon_normal_color', _color)
	_bt.add_theme_color_override(&'icon_hover_color', _color.lightened(.15))
	_bt.add_theme_color_override(&'icon_pressed_color', _color.darkened(.15))
	_bt.add_theme_color_override(&'icon_focus_color', _color)

	if _tint_text:
		_bt.add_theme_color_override(&'font_color', _color)
		_bt.add_theme_color_override(&'font_hover_color', _color.lightened(.15))
		_bt.add_theme_color_override(&'font_pressed_color', _color.darkened(.15))
		_bt.add_theme_color_override(&'font_focus_color', _color)


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


# resolves a bound value source (hengo variable or owner property) to its type name
static func get_bound_source_type(_save_data: HenSaveData, _bind_code: String) -> String:
	if not _save_data:
		return ''

	var bind: Dictionary = classify_bind_code(_save_data, _bind_code)

	match str(bind.kind):
		'var':
			return (bind.value as HenSaveVar).type
		'arg':
			return str((bind.value as HenSaveParam).type)
		'native':
			return str((bind.value as Dictionary).type)
		'property':
			for prop: Dictionary in ClassDB.class_get_property_list(_save_data.identity.type):
				if prop.name == _bind_code:
					return type_string(prop.type)

	return ''


# full expression a bind code emits: an engine-global source stands alone, every
# other bind reads off the owner. empty when the bind no longer resolves
static func bind_expression(_save_data: HenSaveData, _bind_code: String) -> String:
	var resolved: String = resolve_bind_code(_save_data, _bind_code)

	if resolved.is_empty():
		return ''

	var bind: Dictionary = classify_bind_code(_save_data, _bind_code)
	var is_global: bool = str(bind.kind) == 'native' and bool((bind.value as Dictionary).get('global', false))

	# a function input is a parameter of the method being written, a macro input is
	# a script variable of the use running it: neither reads off the owner here
	if str(bind.kind) == 'arg':
		return resolved

	return resolved if is_global else '_ref.' + resolved


# THE place a bind code is read. everything else asks this instead of slicing the
# string on its own — kind is var | native | property | none, and `arg` carries
# the argument of a parameterized source
static func classify_bind_code(_save_data: HenSaveData, _bind_code: String) -> Dictionary:
	if _bind_code.is_empty():
		return {kind = 'none', value = null, arg = ''}

	if _bind_code.begins_with(BIND_VAR_PREFIX):
		var variable: HenSaveVar = get_bind_var(_save_data, _bind_code)
		return {kind = 'var', value = variable, arg = ''} if variable else {kind = 'none', value = null, arg = ''}

	if _bind_code.begins_with(BIND_ARG_PREFIX):
		var param: HenSaveParam = get_bind_arg(_save_data, _bind_code)
		return {kind = 'arg', value = param, arg = ''} if param else {kind = 'none', value = null, arg = ''}

	var separator: int = _bind_code.find(':')

	if separator > 0:
		var key: String = _bind_code.substr(0, separator)
		var arg: String = _bind_code.substr(separator + 1).strip_edges()

		for source: Dictionary in NATIVE_SOURCES:
			if str(source.get('key', '')) == key:
				# an empty argument would emit ("") and read as bound while doing nothing
				return {kind = 'native', value = source, arg = arg} if not arg.is_empty() else {kind = 'none', value = null, arg = ''}

		# an unknown key is not a property name either: `foo:bar` is not valid gdscript
		return {kind = 'none', value = null, arg = ''}

	for source: Dictionary in NATIVE_SOURCES:
		if str(source.get('code', '')) == _bind_code:
			return {kind = 'native', value = source, arg = ''}

	# bindings saved before ids also reach a variable by its snake name
	var by_name: HenSaveVar = get_bind_var(_save_data, _bind_code)

	if by_name:
		return {kind = 'var', value = by_name, arg = ''}

	return {kind = 'property', value = _bind_code, arg = ''}


# native source a bind code points at, empty when it is a variable or a property
static func get_native_source(_save_data: HenSaveData, _bind_code: String) -> Dictionary:
	var bind: Dictionary = classify_bind_code(_save_data, _bind_code)

	return bind.value as Dictionary if str(bind.kind) == 'native' else {}


static func bind_code_for_var(_var: HenSaveVar) -> String:
	return BIND_VAR_PREFIX + str(_var.id)


static func bind_code_for_arg(_param: HenSaveParam) -> String:
	return BIND_ARG_PREFIX + str(_param.id)


# a function input is a parameter of the method being written; a macro input is a
# script variable named after the use running it, which the emit path fills in
static func arg_code(_save_data: HenSaveData, _param: HenSaveParam) -> String:
	if not _param or not _save_data:
		return ''

	for func_res: HenSaveFunc in _save_data.functions:
		if func_res.inputs.has(_param):
			return _param.name.to_snake_case()

	return '_ref.' + HenSaveStateMacro.INPUT_VAR_PREFIX + '{{MACRO_ID}}_' + _param.name.to_snake_case()


# input of a function or of a macro a bind code points at. ids are unique inside a
# script, so the definition holding it does not have to be named
static func get_bind_arg(_save_data: HenSaveData, _bind_code: String) -> HenSaveParam:
	if not _save_data or not _bind_code.begins_with(BIND_ARG_PREFIX):
		return null

	var param_id: String = _bind_code.substr(BIND_ARG_PREFIX.length())

	for func_res: HenSaveFunc in _save_data.functions:
		for param: HenSaveParam in func_res.inputs:
			if str(param.id) == param_id:
				return param

	for macro: HenSaveStateMacro in _save_data.macros:
		for param: HenSaveParam in macro.inputs:
			if str(param.id) == param_id:
				return param

	return null


static func script_path_of(_identity: HenSaveDataIdentity) -> String:
	if not _identity:
		return ''

	if not _identity.script_path.is_empty():
		return _identity.script_path

	return HenEnums.HENGO_SCRIPTS_PATH + str(_identity.id) + '.gd'


# variable a bind code points at: by id, or by name for bindings stored before ids
static func get_bind_var(_save_data: HenSaveData, _bind_code: String) -> HenSaveVar:
	if _bind_code.is_empty() or not _save_data:
		return null

	if _bind_code.begins_with(BIND_VAR_PREFIX):
		var var_id: String = _bind_code.substr(BIND_VAR_PREFIX.length())

		for v: HenSaveVar in _save_data.variables:
			if str(v.id) == var_id:
				return v

		return null

	for v: HenSaveVar in _save_data.variables:
		if v.name.to_snake_case() == _bind_code:
			return v

	return null


# identifier a bind code emits; empty when it no longer resolves
static func resolve_bind_code(_save_data: HenSaveData, _bind_code: String) -> String:
	var bind: Dictionary = classify_bind_code(_save_data, _bind_code)

	match str(bind.kind):
		'var':
			return (bind.value as HenSaveVar).name.to_snake_case()
		'arg':
			return arg_code(_save_data, bind.value as HenSaveParam)
		'native':
			return native_source_code(bind.value as Dictionary, str(bind.arg))
		'property':
			return str(bind.value)

	return ''


# gdscript a native source emits, with the argument filled in for the ones that
# take one
static func native_source_code(_source: Dictionary, _arg: String) -> String:
	if _source.has('code_format'):
		return str(_source.code_format).replace('{arg}', _arg)

	return str(_source.get('code', ''))


# label for a bind code in the ui, so a raw id never reaches the screen
static func get_bind_label(_save_data: HenSaveData, _bind_code: String) -> String:
	var bind: Dictionary = classify_bind_code(_save_data, _bind_code)

	if str(bind.kind) == 'arg':
		return (bind.value as HenSaveParam).name

	if str(bind.kind) == 'native':
		var source: Dictionary = bind.value
		var format: String = str(source.get('label_format', '{name} ({arg})')) if source.has('key') else '{name}'

		return format.replace('{name}', str(source.name)).replace('{arg}', str(bind.arg))

	var resolved: String = resolve_bind_code(_save_data, _bind_code)

	return resolved if not resolved.is_empty() else '(missing)'


static func reposition_control_inside(_control: Control) -> void:
	var rect: Rect2 = (Engine.get_singleton(&'Global') as HenGlobal).HENGO_ROOT.get_viewport_rect()

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
	

# EditorInterface only exists in the editor, and these scenes also run headless
static func disable_scene_with_owner(_ref: Node) -> bool:
	if not Engine.is_editor_hint():
		return false

	var can_disable: bool = false
	var root: Node = EditorInterface.get_edited_scene_root()

	if root:
		can_disable = (root == _ref or root == _ref.owner)

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


# rebuilds the script_id -> directory index by scanning every collection folder
static func rebuild_script_index() -> void:
	var fresh: Dictionary = {}

	if DirAccess.dir_exists_absolute(HenEnums.HENGO_COLLECTION_PATH):
		for collection_id: String in DirAccess.get_directories_at(HenEnums.HENGO_COLLECTION_PATH):
			var collection_path: String = HenEnums.HENGO_COLLECTION_PATH.path_join(collection_id)
			for script_id: String in DirAccess.get_directories_at(collection_path):
				var script_path: String = collection_path.path_join(script_id)
				# a folder is only a script if it carries an identity file
				if FileAccess.file_exists(script_path.path_join(HenEnums.IDENTITY_FILE)):
					fresh[StringName(script_id)] = script_path

	# single reference swap so concurrent readers never see a half-built index
	_script_dir_index = fresh


# resolves a script's directory by id, rebuilding the index on a cache miss
static func get_script_dir(_id: StringName) -> String:
	if _script_dir_index.has(_id):
		var cached: String = _script_dir_index[_id]
		if DirAccess.dir_exists_absolute(cached):
			return cached

	rebuild_script_index()
	return str(_script_dir_index.get(_id, ''))


# returns every known script id across all collections


static func get_all_script_ids() -> Array[StringName]:
	rebuild_script_index()

	var ids: Array[StringName] = []
	for id: StringName in _script_dir_index:
		ids.append(id)
	return ids


# returns the specific path based on the provided enum type
static func get_side_bar_item_path(_save_data_id: StringName, _type: HenSideBar.SideBarItem) -> StringName:
	var base_path: StringName = get_script_dir(_save_data_id)
	var suffix: String = ''

	match _type:
		HenSideBar.SideBarItem.VARIABLES:
			suffix = '/variables/'
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
	ast.macros = global.script_macros
	ast.variables = global.SAVE_DATA.variables
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
					HenSideBar.AddType.MACRO:
						list = ast.macros
					HenSideBar.AddType.STATE:
						list = ast.states
		else:
			match _res_data.type:
				HenSideBar.AddType.VAR:
					list = _save_data.variables
				HenSideBar.AddType.MACRO:
					list = (Engine.get_singleton(&'Global') as HenGlobal).script_macros.duplicate()
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

					var found: HenSaveParam = check_list.call(_save_data.states)
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


# true when a script extending _class is served by a list of target classes. an
# empty list serves everyone, and an unknown class never hides the pool
static func class_serves(_class: StringName, _targets: Array) -> bool:
	if _targets.is_empty() or not ClassDB.class_exists(_class):
		return true

	for target: Variant in _targets:
		if ClassDB.class_exists(StringName(str(target))) and ClassDB.is_parent_class(_class, StringName(str(target))):
			return true

	return false


# a node slot that falls back to the node the script sits on when nobody binds it,
# which is what an action reads through {{ref}}
static func is_node_ref_slot(_type: StringName, _bind_only: bool, _optional: bool) -> bool:
	if not _bind_only or not _optional or not ClassDB.class_exists(_type):
		return false

	return ClassDB.is_parent_class(_type, &'Node')


static func is_abstract_class_needing_connection(_type: StringName, _identity_type: StringName) -> bool:
	if not ClassDB.class_exists(_type) or not _identity_type:
		return false
	return (
		ClassDB.is_parent_class(_type, _identity_type) and
		not ClassDB.can_instantiate(_type)
	)


# true when a variable/property declared as _holder_type can hold an instance of
# _class. a script's extends is a lower bound — one extending Node can live on a
# Sprite2D — so either side may be the narrower one; only sibling branches fail
static func can_hold_instance_of(_holder_type: StringName, _class: StringName) -> bool:
	if _holder_type == _class:
		return true

	# every new variable is born Variant, and an untyped one does hold anything
	if _holder_type == &'Variant':
		return true

	# an unknown class on either side would filter everything out
	if not ClassDB.class_exists(_class) or not ClassDB.class_exists(_holder_type):
		return is_type_relation_valid(_class, _holder_type)

	return ClassDB.is_parent_class(_class, _holder_type) or ClassDB.is_parent_class(_holder_type, _class)