@tool
class_name HenDropdown extends Button

var options: Array = []
@export var type: String = ''
var custom_data
var custom_value: String = ''
var input_ref: HenVirtualCNode.InOutData

signal value_changed

func _ready() -> void:
	button_down.connect(_on_pressed)


func _on_pressed() -> void:
	match type:
		'state_transition':
			# all transitions
			if HenRouter.current_route.type == HenRouter.ROUTE_TYPE.STATE:
				options = HenRouter.current_route.ref.flow_connections.map(func(x):
					return {name = x.name, ref = x})
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
		'all_classes':
			options = HenEnums.DROPDOWN_ALL_CLASSES
		'enum_list':
			var enum_reference: Dictionary = {}

			for enum_name in ClassDB.class_get_enum_constants(custom_data[0], custom_data[1]):
				enum_reference[enum_name] = '.'.join(custom_data) + '.' + enum_name
			
			options = enum_reference.keys().map(func(x: String) -> Dictionary: return {name = x, code_name = enum_reference[x]}) if not enum_reference.is_empty() else []
		'all_props':
			var arr: Array = []

			# local variables
			match HenRouter.current_route.type:
				HenRouter.ROUTE_TYPE.FUNC, HenRouter.ROUTE_TYPE.SIGNAL, HenRouter.ROUTE_TYPE.MACRO:
					if HenRouter.current_route.ref.get(&'local_vars') is Array:
						for var_data: HenSideBar.VarData in (HenRouter.current_route.ref.local_vars as Array):
							if HenUtils.is_type_relation_valid(input_ref.type, var_data.type):
								arr.append({
									name = var_data.name,
									category = 'class_props',
									ref = var_data
								})

			# variables
			for var_data: HenSideBar.VarData in HenGlobal.SIDE_BAR_LIST.var_list:
				if HenUtils.is_type_relation_valid(input_ref.type, var_data.type):
					arr.append({
						name = var_data.name,
						category = 'class_props',
						ref = var_data
					})
			
			# properties
			for prop: Dictionary in ClassDB.class_get_property_list(HenGlobal.script_config.type):
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
		'get_prop', 'set_prop':
			var arr: Array = []
			
			# local variables
			match HenRouter.current_route.type:
				HenRouter.ROUTE_TYPE.FUNC, HenRouter.ROUTE_TYPE.SIGNAL, HenRouter.ROUTE_TYPE.MACRO:
					if HenRouter.current_route.ref.get(&'local_vars') is Array:
						for var_data: HenSideBar.VarData in (HenRouter.current_route.ref.local_vars as Array):
							arr.append({name = var_data.name, type = var_data.type, ref = var_data})

			# variables
			for var_data: HenSideBar.VarData in HenGlobal.SIDE_BAR_LIST.var_list:
				arr.append({name = var_data.name, type = var_data.type, ref = var_data})

			# properties
			for prop: Dictionary in ClassDB.class_get_property_list(HenGlobal.script_config.type if not custom_data else custom_data):
				var prop_type: StringName = type_string(prop.type)
				if prop.type != TYPE_NIL:
					arr.append({
						name = prop.name,
						type = prop_type
					})
				
				get_const_list(arr, '', prop.name, prop_type, false)

			options = arr
		'state_event_list':
			pass
			# var data: Dictionary = HenGlobal.SCRIPTS_INFO.get(custom_data)

			# if data.has('state_event_list'):
			# 	options = data.state_event_list.map(func(x: String) -> Dictionary: return {name = x.to_snake_case()})
		'signal_list':
			var arr: Array = []
			var all_classes: PackedStringArray = ClassDB.get_class_list()

			# print(ClassDB.class_get_signal_list('BaseButton', true))

			for class_name_data: String in all_classes:
				for signal_data: Dictionary in ClassDB.class_get_signal_list(class_name_data, true):
					arr.append(
						{
							name = '{name}   ({class})'.format({
								name = signal_data.name,
								'class' = class_name_data
							}),
							signal_name = signal_data.name,
							signal_class = class_name_data
						})
				
			options = arr
		'get_from_name':
			options = []
			for script_path: String in DirAccess.get_files_at('res://hengo/save'):
				var id: int = int(script_path.get_basename())
				if id == 0:
					continue
				
				options.append({
					name = ResourceUID.get_id_path(id).get_file().get_basename(),
					id = id
				})
		'get_from':
			var id: int = get_parent().owner.root.virtual_ref.inputs[0].get_from_id
			var resource: HenScriptData = ResourceLoader.load('res://hengo/save/' + str(id) + '.res')
			options = []
			for var_data: Dictionary in resource.side_bar_list.var_list:
				options.append(var_data)
			

	HenGlobal.DROPDOWN_MENU.position = global_position
	HenGlobal.DROPDOWN_MENU.get_parent().show_container()
	HenGlobal.DROPDOWN_MENU.mount(options, _selected, type)


func _selected(_item: Dictionary) -> void:
	text = _item.name

	HenGlobal.CAM.can_scroll = true

	match type:
		'hengo_states':
			text = (_item.name as String).to_snake_case()
		'state_transition':
			emit_signal('value_changed', text)
			input_ref.set_ref(_item.ref, HenVirtualCNode.InOutData.RefChangeRule.VALUE_CODE_VALUE_CHANGE)
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

			if _item.has('ref'):
				input_ref.set_ref(_item.ref, HenVirtualCNode.InOutData.RefChangeRule.IS_PROP)
			else:
				input_ref.remove_ref()
			return
		'get_prop':
			emit_signal('value_changed', text, _item.type)

			if _item.has('ref'):
				input_ref.set_ref(_item.ref)
			else:
				input_ref.remove_ref()
			return
		'set_prop':
			emit_signal('value_changed', text)
			
			var second_input: HenCnodeInOut = get_parent().owner.get_parent().get_child(1 if not custom_data else 2)
			
			if _item.has('ref'):
				second_input.input_ref.type = _item.ref.type
				second_input.input_ref.reset_input_value()
				second_input.input_ref.set_ref(_item.ref, HenVirtualCNode.InOutData.RefChangeRule.TYPE_CHANGE)
				input_ref.set_ref(_item.ref, HenVirtualCNode.InOutData.RefChangeRule.VALUE_CODE_VALUE_CHANGE)
			else:
				second_input.input_ref.remove_ref()
				second_input.input_ref.type = _item.type
				second_input.input_ref.reset_input_value()
				second_input.input_ref.update_changes.emit()
			return
		'signal_list':
			var item: HenSideBar.SignalData = custom_data.signal_ref
			item.set_signal_params(_item.signal_class, _item.signal_name)
		'get_from_name':
			input_ref.get_from_id = _item.id
			print(_item)
		'get_from':
			emit_signal('value_changed', text, _item.type)
			input_ref.from_side_bar_id = _item.id
			input_ref.update_changes.emit()
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
