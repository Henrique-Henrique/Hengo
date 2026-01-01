@tool
class_name HenVCInOutData extends Resource

@export var id: int
@export var name: String
@export var type: StringName
@export var sub_type: StringName
@export var category: StringName
@export var is_ref: bool
@export var code_value: String
@export var value: Variant
@export var data: Variant
@export var is_prop: bool
@export var is_static: bool
@export var res_data: Dictionary

signal connection_request(_data: Dictionary)
signal io_hovered(_context: Dictionary)
signal expression_saved(_context: Dictionary)
signal method_picker_requested(_context: Dictionary)
signal changed_code_value(_id: int, _context: Dictionary)
signal on_set_res_data(_data: Dictionary)


static func create(_data: Dictionary) -> HenVCInOutData:
	var io: HenVCInOutData = HenVCInOutData.new()
	io.id = _data.id if _data.has('id') else (Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()
	io.name = _data.name
	io.type = _data.type

	if _data.has('sub_type'): io.sub_type = _data.sub_type
	if _data.has('category'): io.category = _data.category
	if _data.has('is_ref'): io.is_ref = _data.is_ref
	if _data.has('code_value'): io.code_value = _data.code_value
	if _data.has('value'): io.value = _data.value
	if _data.has('data'): io.data = _data.data
	if _data.has('is_prop'): io.is_prop = _data.is_prop
	if _data.has('is_static'): io.is_static = _data.is_static

	return io


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
	changed_code_value.emit(id, {
		value = value,
		code_value = code_value,
		type = type
	})


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


func set_res_data(_data: Dictionary) -> void:
	res_data = _data


func get_res(_save_data: HenSaveData) -> Resource:
	return HenUtils.get_res(res_data, _save_data)
