@tool
class_name HenVCInOutData extends RefCounted

var id: int = (Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()
var name: String
var type: StringName: set = _on_change_type
var sub_type: StringName
var category: StringName
var is_ref: bool
var code_value: String
var value: Variant
var data: Variant
var is_prop: bool
var is_static: bool
var ref: RefCounted
var ref_change_rule: RefChangeRule

signal update_changes
signal moved
signal deleted
signal type_changed
signal connection_request(_data: Dictionary)
signal io_hovered(_context: Dictionary)
signal expression_saved(_context: Dictionary)
signal method_picker_requested(_context: Dictionary)

enum RefChangeRule {
	NONE = 0,
	TYPE_CHANGE = 1,
	VALUE_CODE_VALUE_CHANGE = 2,
	IS_PROP = 3
}


func _init(_data: Dictionary) -> void:
	name = _data.name
	type = _data.type

	if _data.has('id'): id = _data.id
	if _data.has('sub_type'): sub_type = _data.sub_type
	if _data.has('category'): category = _data.category
	if _data.has('is_ref'): is_ref = _data.is_ref
	if _data.has('code_value'): code_value = _data.code_value
	if _data.has('value'): value = _data.value
	if _data.has('data'): data = _data.data
	if _data.has('is_prop'): is_prop = _data.is_prop
	if _data.has('is_static'): is_static = _data.is_static
	if _data.has('ref'): set_ref(_data.ref, _data.ref_change_rule if _data.has('ref_change_rule') else RefChangeRule.NONE)


func _on_change_type(_type: StringName) -> void:
	type_changed.emit(type, _type, self)
	type = _type


func set_ref(_ref, _ref_change_rule: RefChangeRule = RefChangeRule.NONE) -> void:
	ref = _ref
	ref_change_rule = _ref_change_rule

	# when param is moved
	if ref.has_signal('moved') and not ref.is_connected('moved', _on_move):
		ref.moved.connect(_on_move)

	# if ref.has_signal('deleted') and not ref.is_connected('deleted', _on_delete):
	# 	if not ref is HenVarData:
	# 		ref.deleted.connect(_on_delete)

	if _ref.has_signal('data_changed') and not ref.is_connected('data_changed', on_data_changed):
		_ref.data_changed.connect(on_data_changed)
	
	update_changes.emit()


func _on_move(_is_input: bool, _pos: int) -> void:
	moved.emit(_is_input, _pos, self)


func _on_delete(_is_input: bool) -> void:
	deleted.emit(_is_input, self)


func remove_ref() -> void:
	if ref:
		for signal_connetion: Dictionary in ref.get_signal_connection_list('data_changed'):
			signal_connetion.signal.disconnect(signal_connetion.callable)
	
	ref_change_rule = RefChangeRule.NONE
	update_changes.emit()


func on_data_changed(_name: String, _value) -> void:
	if ref_change_rule != RefChangeRule.NONE:
		match ref_change_rule:
			RefChangeRule.TYPE_CHANGE:
				if _name != 'type':
					return
			RefChangeRule.VALUE_CODE_VALUE_CHANGE:
				if not ['value', 'code_value'].has(_name):
					return
			RefChangeRule.IS_PROP:
				if _name == 'type':
					# if new type is diffent, reset input
					if not HenUtils.is_type_relation_valid(_value, type):
					# if _value != 'Variant' and type != 'Variant' and _value != type:
						reset_input_value()
						remove_ref()
						return
				
				if not ['value', 'code_value'].has(_name):
					return
	
	set(_name, _value)

	if sub_type != '@dropdown':
		match _name:
			'type':
				reset_input_value()

	update_changes.emit()


func get_save() -> Dictionary:
	var dt: Dictionary = {
		id = id,
		name = name,
		type = type
	}

	if sub_type: dt.sub_type = sub_type
	if category: dt.category = category
	if is_ref: dt.is_ref = is_ref
	if code_value: dt.code_value = code_value
	if value: dt.value = value
	if data: dt.data = data
	if is_prop: dt.is_prop = is_prop
	if is_static: dt.is_static = is_static
	if ref_change_rule != RefChangeRule.NONE: dt.ref_change_rule = int(ref_change_rule)

	return dt


func reset_input_value() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	category = &'default_value'
	is_prop = false

	if global.script_config and global.script_config.type == type:
		code_value = '_ref.'
		is_ref = true
		return
	
	match type:
		'String', 'NodePath', 'StringName':
			code_value = '""'
		'int':
			code_value = '0'
		'float':
			code_value = '0.'
		'Vector2':
			code_value = 'Vector2(0, 0)'
		'bool':
			code_value = 'false'
		'Variant':
			code_value = 'null'
		_:
			if HenEnums.VARIANT_TYPES.has(type):
				code_value = type + '()'
			elif ClassDB.can_instantiate(type):
				code_value = type + '.new()'

	match type:
		'String', 'NodePath', 'StringName':
			value = ''
		_:
			value = code_value


func get_type_color() -> Color:
	match type:
		'String':
			return Color('#8eef97')
		'float':
			return Color('#FFDD65')
		'int':
			return Color('#5ABBEF')
		'bool':
			return Color('#FC7F7F')
		'Vector2', 'Vector3':
			return Color('#c368ed')
		'Variant':
			return Color('#72788a')
		_:
			if ClassDB.is_parent_class(type, 'Control'):
				return Color('#8eef97')
			elif ClassDB.is_parent_class(type, 'Node2D'):
				return Color('#5ABBEF')
			elif ClassDB.is_parent_class(type, 'Node3D'):
				return Color('#FC7F7F')
			elif ClassDB.is_parent_class(type, 'AnimationMixer'):
				return Color('#c368ed')

			return Color.WHITE


func create_virtual_connection(_type: StringName) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	# packs necessary data, moving dependency resolution to the manager
	var context = {
		type = _type,
		local_port_id = id,
		remote_data = global.connection_to_data
	}

	connection_request.emit(context)


func on_expression_save(_code_value: String, _word_list: Array) -> void:
	var context = {
		code = _code_value,
		words = _word_list
	}
	
	expression_saved.emit(context)


func on_method_picker_request(_io_type: StringName, _mouse_pos: Vector2) -> void:
	# packs local port data and mouse position for the handler
	var context = {
		io_type = _io_type,
		port_id = id,
		mouse_pos = _mouse_pos,
		port_type = type,
	}
	
	method_picker_requested.emit(context)


func on_io_mouse_enter(_connector) -> void:
	var context = {
		connector = _connector,
		color = get_type_color(),
		source = self
	}
	
	io_hovered.emit(context)


func on_value_change(_value, _generated_code: StringName) -> void:
	value = _value
	code_value = _generated_code


func on_outprop_value_change(_value, _type: StringName, _generate_code: String) -> void:
	value = _value
	type = _type
	code_value = _generate_code


func on_outprop_config_request(_dropdown: HenDropdown) -> void:
	_dropdown.type = category
	_dropdown.custom_data = data
	_dropdown.input_ref = self


func on_inprop_config_request(_dropdown: HenDropdown) -> void:
	_dropdown.type = category
	_dropdown.custom_data = data
	_dropdown.input_ref = self

	match category:
		'enum_list':
			_dropdown.text = ClassDB.class_get_enum_constants(data[0], data[1])[0]
			_dropdown.custom_value = '.'.join(data) + '.' + _dropdown.text
		'get_prop', 'set_prop':
			_dropdown.alignment = HORIZONTAL_ALIGNMENT_LEFT
			_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
