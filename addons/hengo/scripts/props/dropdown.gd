@tool
class_name HenDropdown extends Button

var options: Array = []
@export var type: String = ''
var custom_data
var custom_value: String = ''
var input_ref: HenVCInOutData

signal value_changed

func _ready() -> void:
	button_down.connect(_on_pressed)


func _on_pressed() -> void:
	var router: HenRouter = Engine.get_singleton(&'Router')
	var global: HenGlobal = Engine.get_singleton(&'Global')

	match type:
		'state_transition':
			pass
			# all transitions
			# if router.current_route.type == router.ROUTE_TYPE.STATE:
				# options = (router.current_route.get_ref() as HenVirtualCNode).flow_outputs.map(func(x: HenVCFlow):
				# 	return {name = x.name, ref = x})
		'action':
			var arr: Array = []

			for dict in ProjectSettings.get_property_list():
				if dict.name.begins_with('input/'):
					arr.append({
						name = dict.name.substr(dict.name.find('/') + 1, dict.name.length())
					})
			
			options = arr
		'all_godot_classes':
			options = (ClassDB.get_class_list() as Array).map(func(x: String): return {
				name = x
			})
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
		'all_props':
			var arr: Array = []

			# local variables
			# match router.current_route.type:
			# 	router.ROUTE_TYPE.FUNC, router.ROUTE_TYPE.SIGNAL, router.ROUTE_TYPE.MACRO:
			# 		if router.current_route.get_ref().get(&'local_vars') is Array:
			# 			for var_data: HenVarData in (router.current_route.get_ref().get(&'local_vars') as Array):
			# 				if HenUtils.is_type_relation_valid(input_ref.type, var_data.type):
			# 					arr.append({
			# 						name = var_data.name,
			# 						category = 'class_props',
			# 						ref = var_data
			# 					})

			# variables
			for var_data: HenSaveVar in global.SAVE_DATA.variables:
				if HenUtils.is_type_relation_valid(input_ref.type, var_data.type):
					arr.append({
						name = var_data.name,
						category = 'class_props',
						ref = var_data
					})
			
			# properties
			for prop: Dictionary in ClassDB.class_get_property_list(global.SAVE_DATA.identity.type):
				var _type: StringName = input_ref.type
				var prop_type: StringName = type_string(prop.type)
				
				if (_type == 'Variant' and prop.type != TYPE_NIL) or HenUtils.is_type_relation_valid(_type, prop_type):
					arr.append({
						name = prop.name,
						category = 'class_props',
					})
				
				get_const_list(arr, _type, prop.name, prop_type)

			options = arr
		'signal':
			options = ClassDB.class_get_signal_list(custom_data).map(func(x): return {
				name = x.name
			})
		'callable':
			options = []
			# options = HenGlobal.ROUTE_REFERENCE_CONTAINER.get_children().map(func(x): return {
			# 	name = x.route.name
			# })
		'state_event_list':
			pass

			
	global.DROPDOWN_MENU.position = global_position
	global.DROPDOWN_MENU.get_parent().show_container()
	global.DROPDOWN_MENU.mount(options, _selected, type)
	global.DROPDOWN_MENU.size.x = size.x


func _selected(_item: Dictionary) -> void:
	text = _item.name

	(Engine.get_singleton(&'Global') as HenGlobal).CAM.can_scroll = true

	match type:
		'hengo_states':
			text = (_item.name as String).to_snake_case()
		'state_transition':
			emit_signal('value_changed', text)
			# input_ref.set_ref(_item.ref, HenVCInOutData.RefChangeRule.VALUE_CODE_VALUE_CHANGE)
			return
		'enum_list':
			text = _item.name
			custom_value = _item.code_name
			emit_signal('value_changed', custom_value)
			return
		'all_props':
			emit_signal('value_changed', text, text.to_snake_case())
			var input = get_parent().owner

			input.remove_in_prop(true)

			input_ref.category = 'class_props'

			# if _item.has('ref'):
			# 	input_ref.set_ref(_item.ref, HenVCInOutData.RefChangeRule.IS_PROP)
			# else:
			# 	input_ref.remove_ref()
			return
		'get_prop':
			emit_signal('value_changed', text, _item.type)

			if _item.has('ref'):
				input_ref.set_ref(_item.ref)
			else:
				input_ref.remove_ref()
			return


	value_changed.emit(text)

# public
#
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
