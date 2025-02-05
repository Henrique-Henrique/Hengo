@tool
class_name HenDropdown extends Button

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
			if HenRouter.current_route.type == HenRouter.ROUTE_TYPE.STATE:
				options = HenRouter.current_route.state_ref.get_all_transition_data()
		HenCnode.SUB_TYPE.CONST:
			var const_name = get_parent().owner.root.get_cnode_name()

			if HenEnums.CONST_API_LIST.has(const_name):
				options = HenEnums.CONST_API_LIST[const_name]
		'action':
			var arr: Array = []

			for dict in ProjectSettings.get_property_list():
				if dict.name.begins_with('input/'):
					arr.append({
						name = dict.name.substr(dict.name.find('/') + 1, dict.name.length())
					})
			
			options = arr
		'hengo_states':
			options = HenGlobal.SCRIPTS_STATES[custom_data] if HenGlobal.SCRIPTS_STATES.has(custom_data) else []
		'cast_type':
			options = HenEnums.DROPDOWN_ALL_CLASSES
		'current_states':
			options = HenGlobal.STATE_CONTAINER.get_children().map(func(state): return {name = state.get_state_name()})
		'enum_list':
			var enum_reference: Dictionary = {}

			for enum_name in ClassDB.class_get_enum_constants(custom_data[0], custom_data[1]):
				enum_reference[enum_name] = '.'.join(custom_data) + '.' + enum_name
			
			options = enum_reference.keys().map(func(x: String) -> Dictionary: return {name = x, code_name = enum_reference[x]}) if not enum_reference.is_empty() else []
		'all_props':
			var arr: Array = []

			for prop in HenGlobal.PROPS_CONTAINER.get_all_values(true):
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
			options = HenGlobal.ROUTE_REFERENCE_CONTAINER.get_children().map(func(x): return {
				name = x.route.name
			})


	HenGlobal.DROPDOWN_MENU.position = global_position
	HenGlobal.DROPDOWN_MENU.get_parent().show_container()
	HenGlobal.DROPDOWN_MENU.mount(options, _selected, type)


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
		HenCnode.SUB_TYPE.CONST:
			var output = get_parent().owner
			output.change_type(_item.type)
		'all_props':
			var input = custom_data.input_ref
			var group: String = 'p' + str(_item.item.get_index())

			input.remove_in_prop(true)

			HenGlobal.GROUP.reset_and_add_group(self, group)
			custom_value = str(_item.item.get_index())
		
	emit_signal('value_changed', text)

	match type:
		'hengo_states':
			if HenRouter.current_route.type == HenRouter.ROUTE_TYPE.STATE:
				HenCodeGeneration.check_state_errors(HenRouter.current_route.state_ref)

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
		'all_props', 'callable':
			return text.to_snake_case()
		_:
			return '\"' + text + '\"'