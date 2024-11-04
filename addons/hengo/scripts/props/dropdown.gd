@tool
extends Button

const _Global = preload('res://addons/hengo/scripts/global.gd')
const _Router = preload('res://addons/hengo/scripts/router.gd')
const _CodeGeneration = preload('res://addons/hengo/scripts/code_generation.gd')
const _Enums = preload('res://addons/hengo/references/enums.gd')

var options: Array = []
var type: String = ''
var custom_data
var custom_value: String = ''

signal value_changed


func _ready() -> void:
	button_down.connect(_on_pressed)


func _on_pressed() -> void:
	match type:
		'state_transition':
			# all transitions
			if _Router.current_route.type == _Router.ROUTE_TYPE.STATE:
				options = _Router.current_route.state_ref.get_all_transition_data()
		'const':
			var const_name = get_parent().owner.root.get_cnode_name()

			if _Enums.CONST_API_LIST.has(const_name):
				options = _Enums.CONST_API_LIST[const_name]
		'action':
			var arr: Array = []

			for dict in ProjectSettings.get_property_list():
				if dict.name.begins_with('input/'):
					arr.append({
						name = dict.name.substr(dict.name.find('/') + 1, dict.name.length())
					})
			
			options = arr
		'hengo_states':
			options = _Global.SCRIPTS_STATES[custom_data] if _Global.SCRIPTS_STATES.has(custom_data) else []
		'cast_type':
			options = _Enums.DROPDOWN_ALL_CLASSES
		'current_states':
			options = _Global.STATE_CONTAINER.get_children().map(func(state): return {name = state.get_state_name()})
		'enum_list':
			var enum_reference: Dictionary = {}

			for enum_name in ClassDB.class_get_enum_constants(custom_data[0], custom_data[1]):
				enum_reference[enum_name] = '.'.join(custom_data) + '.' + enum_name
			
			options = enum_reference.keys().map(func(x: String) -> Dictionary: return {name = x, code_name = enum_reference[x]}) if not enum_reference.is_empty() else []

	_Global.DROPDOWN_MENU.position = global_position
	_Global.DROPDOWN_MENU.get_parent().show()
	_Global.DROPDOWN_MENU.mount(options, _selected, type)


func _selected(_item: Dictionary) -> void:
	text = _item.name

	match type:
		'hengo_states', 'state_transition', 'current_states':
			text = (_item.name as String).to_snake_case()
		'enum_list':
			text = _item.name
			custom_value = _item.code_name
			emit_signal('value_changed', custom_value)
			return
		'cast_type':
			var output = get_parent().owner

			output.hide_connection()
			output.set_type((_item.name as String))
		'const':
			var output = get_parent().owner
			output.change_type(_item.type)
		
	emit_signal('value_changed', text)

	match type:
		'hengo_states':
			if _Router.current_route.type == _Router.ROUTE_TYPE.STATE:
				_CodeGeneration.check_state_errors(_Router.current_route.state_ref)

	get_parent().owner.root.size = Vector2.ZERO

# public
#
func set_default(_text: String) -> void:
	match type:
		'enum_list':
			text = _text.split('.')[-1] as String
			custom_value = _text
		'cast_type':
			text = _text

			if get_parent():
				get_parent().owner.set_type(_text)
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
		_:
			return '\"' + text + '\"'