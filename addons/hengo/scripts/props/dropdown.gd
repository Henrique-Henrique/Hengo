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
				options = HenRouter.current_route.ref.flow_connections.map(func(x): return {name = x.name})
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
			
			for prop: Dictionary in ClassDB.class_get_property_list(HenGlobal.script_config.type):
				var _type: StringName = custom_data.input_ref.input_ref.type
				var prop_type: StringName = type_string(prop.type)
				
				if (_type == 'Variant' and prop.type != TYPE_NIL) or prop_type == _type:
					arr.append({
						name = prop.name
					})
				
				get_const_list(arr, _type, prop.name, prop_type)

			options = arr
		'signal':
			options = ClassDB.class_get_signal_list(custom_data).map(func(x): return {
				name = x.name
			})
		'callable':
			options = HenGlobal.ROUTE_REFERENCE_CONTAINER.get_children().map(func(x): return {
				name = x.route.name
			})
		'get_prop', 'set_prop':
			var arr: Array = []

			print(custom_data)

			if not custom_data:
				for prop in HenGlobal.PROPS_CONTAINER.get_all_values(true):
					arr.append(prop)
			
			for prop: Dictionary in ClassDB.class_get_property_list(HenGlobal.script_config.type if not custom_data else custom_data):
				var prop_type: StringName = type_string(prop.type)
				if prop.type != TYPE_NIL:
					arr.append({
						name = prop.name,
						type = prop_type
					})
				
				get_const_list(arr, '', prop.name, prop_type, false)

			options = arr


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
		'all_props':
			var input = custom_data.input_ref
			var value: String = text

			input.remove_in_prop(true)

			if _item.has('value'):
				value = _item.value
				input.input_ref.category = 'class_props'

			emit_signal('value_changed', text, value)
			HenGlobal.CNODE_CAM.can_scroll = true
			return
		'get_prop':
			emit_signal('value_changed', text, _item.type)
			get_parent().owner.set_type(_item.type)
			HenGlobal.CNODE_CAM.can_scroll = true
			return
		'set_prop':
			emit_signal('value_changed', text)
			var input: HenCnodeInOut = get_parent().owner.get_parent().get_child(1 if not custom_data else 2)

			for input_key: String in input.input_ref.keys():
				if not ['name', 'type'].has(input_key):
					input.input_ref.erase(input_key)

			input.change_type(_item.type)
			input.input_ref.type = _item.type
			
			match _item.type:
				'String', 'NodePath', 'StringName':
					input.input_ref.code_value = '""'
				'int':
					input.input_ref.code_value = '0'
				'float':
					input.input_ref.code_value = '0.'
				'Vector2':
					input.input_ref.code_value = 'Vector2.ZERO'
				'bool':
					input.input_ref.code_value = false
				'Variant':
					input.input_ref.code_value = 'null'
				_:
					if HenEnums.VARIANT_TYPES.has(input.input_ref.type):
						input.input_ref.code_value = input.input_ref.type + '()'
					elif ClassDB.can_instantiate(input.input_ref.type):
						input.input_ref.code_value = input.input_ref.type + '.new()'

			input.input_ref.erase('value')

			HenGlobal.CNODE_CAM.can_scroll = true
			return

	value_changed.emit(text)

	match type:
		'hengo_states':
			if HenRouter.current_route.type == HenRouter.ROUTE_TYPE.STATE:
				HenCodeGeneration.check_state_errors(HenRouter.current_route.state_ref)

	if get_parent() and get_parent().owner:
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
		'get_prop', 'set_prop':
			return text.replacen(' -> ', '.')
		_:
			return '\"' + text + '\"'
	

func get_const_list(_arr: Array, _type: StringName, _name: String, _prop_type: StringName, _check_type: bool = true) -> Array:
	if HenEnums.NATIVE_PROPS_LIST.has(_prop_type):
		for prop: Dictionary in HenEnums.NATIVE_PROPS_LIST.get(_prop_type):
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
