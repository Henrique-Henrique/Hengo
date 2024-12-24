@tool
extends Button

const _Global = preload('res://addons/hengo/scripts/global.gd')
const _Router = preload('res://addons/hengo/scripts/router.gd')
const _CodeGeneration = preload('res://addons/hengo/scripts/code_generation.gd')
const _Enums = preload('res://addons/hengo/references/enums.gd')

var options: Array = []
@export var type: String = ''
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
		'all_props':
			var arr: Array = []

			for prop in _Global.PROPS_CONTAINER.get_all_values(true):
				if custom_data.input_ref.is_type_relatable(
					'out',
					'in',
					prop.type,
					custom_data.input_ref.connection_type,
				):
					arr.append(prop)
		
			options = arr
		'signal':
			options = ClassDB.class_get_signal_list(custom_data).map(func(x): return {
				name = x.name
			})
		'callable':
			options = _Global.ROUTE_REFERENCE_CONTAINER.get_children().map(func(x): return {
				name = x.route.name
			})


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

			if output:
				output.hide_connection()
				output.set_type((_item.name as String))
		'const':
			var output = get_parent().owner
			output.change_type(_item.type)
		'all_props':
			var input = custom_data.input_ref
			input.remove_in_prop(true)
			
			for group in get_groups():
				remove_from_group(group)

			add_to_group('p' + str(_item.item.get_index()))
			custom_value = str(_item.item.get_index())
		
	emit_signal('value_changed', text)

	match type:
		'hengo_states':
			if _Router.current_route.type == _Router.ROUTE_TYPE.STATE:
				_CodeGeneration.check_state_errors(_Router.current_route.state_ref)

	if get_parent().owner:
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

			if get_parent().owner:
				get_parent().owner.set_type(_text)
		'all_props':
			if _text.begins_with('t:'):
				if custom_data.input_ref.is_type_relatable('out', 'in', _text.split('t:')[1], custom_data.input_ref.connection_type):
					return
				
				queue_free()

				custom_data.input_ref.reset_in_props(true)
				custom_data.input_ref.set_in_prop()

			text = _text
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
		'all_props':
			return text.to_snake_case()
		_:
			return '\"' + text + '\"'