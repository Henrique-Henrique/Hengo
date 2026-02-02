@tool
class_name HenCnodeInOut extends PanelContainer

@export var root: HenCnode
@export_enum('in', 'out') var type: String

const CNODE_INPUT_LABEL = preload('res://addons/hengo/scenes/cnode_input_label.tscn')

var io_type: StringName
var sub_type: StringName

signal request_method_picker
signal on_mouse_enter
signal request_create_connection
signal on_value_change
signal on_set_res_data
signal on_outprop_value_change
signal outprop_config_request
signal inprop_config_request
signal on_expression_save

func _ready():
	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)
	gui_input.connect(_on_gui)

const DROPDOWN_SCENE = preload('res://addons/hengo/scenes/props/dropdown.tscn')

func _on_gui(_event: InputEvent) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if _event is InputEventMouseButton:
		if _event.pressed:
			if _event.button_index == MOUSE_BUTTON_LEFT:
				global.can_make_connection = true

				var connector: TextureRect = get_node('%Connector')
				var pos = global.CAM.get_relative_vec2(get_node('%Connector').global_position)

				global.CONNECTION_GUIDE.is_in_out = true
				global.CONNECTION_GUIDE.start(pos + connector.size / 2, self)
		else:
			if global.can_make_connection and not global.connection_to_data:
				request_method_picker.emit(type, get_global_mouse_position())
			elif global.can_make_connection and global.connection_to_data:
				request_create_connection.emit(type)

			global.CONNECTION_GUIDE.end()

			global.connection_to_data = null
			global.can_make_connection = false
			global.TOOLTIP.close()
	elif _event is InputEventMouseMotion:
		if type == 'out':
			global.TOOLTIP.go_to(get_global_mouse_position(), '[i]Connect[/i]')
		else:
			global.TOOLTIP.close()

func _on_enter() -> void:
	if not (Engine.get_singleton(&'Global') as HenGlobal).can_make_connection:
		get('theme_override_styles/panel/').set('border_color', Color(1., 1., 1., .7))
		return

	get('theme_override_styles/panel/').set('border_color', Color.RED)

	on_mouse_enter.emit(get_node('%Connector'))


func _on_exit() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	get('theme_override_styles/panel/').set('border_color', Color.TRANSPARENT)
	
	global.TOOLTIP.close()
	global.connection_to_data = null

	if global.CONNECTION_GUIDE.is_in_out:
		global.CONNECTION_GUIDE.hover_pos = null
		global.CONNECTION_GUIDE.gradient.colors[1] = Color.WHITE


func change_name(_text: String) -> void:
	get_node('%Name').text = _text
	size.x = 0


func set_out_prop(_sub_type: String = '', _default_value = null) -> void:
	if type == 'out':
		var prop_container = get_node('%CNameOutput')
		var prop

		match _sub_type:
			'@dropdown':
				var dropdown = DROPDOWN_SCENE.instantiate()

				outprop_config_request.emit(dropdown)

				if not _default_value:
					dropdown.set_default('Node')

				get_child(0).process_mode = Node.PROCESS_MODE_INHERIT

				prop_container.add_child(dropdown)
				prop_container.move_child(dropdown, 0)
				prop = dropdown

				dropdown.value_changed.connect(_on_out_value.bind(dropdown))
		
		if prop and _default_value:
			prop.set_default(str(_default_value))


func _on_out_value(_value, _type, _prop) -> void:
	on_outprop_value_change.emit(_value, _type, _prop.get_generated_code())


func set_in_prop(_default_value = null, _add_prop_ref: bool = true) -> void:
	if type == 'in':
		var prop_container = get_node('%CNameInput')
		var prop

		if prop_container.get_child_count() > 4:
			return

		match sub_type:
			'@dropdown':
				var dropdown = DROPDOWN_SCENE.instantiate()

				inprop_config_request.emit(dropdown)
				prop_container.add_child(dropdown)
				prop = dropdown
			'expression':
				var expression_bt: HenExpressionBt = preload('res://addons/hengo/scenes/utils/expression_bt.tscn').instantiate()
				expression_bt.on_expression_save.connect(_on_expression_save)
				prop_container.add_child(expression_bt)
				prop = expression_bt

			_:
				match io_type:
					'String', 'NodePath', 'StringName':
						var _str = preload('res://addons/hengo/scenes/props/string.tscn').instantiate()
						prop_container.add_child(_str)
						prop = _str
					'int':
						var prop_int = preload('res://addons/hengo/scenes/props/int.tscn').instantiate()
						prop_container.add_child(prop_int)
						prop = prop_int
					'float':
						var prop_float = preload('res://addons/hengo/scenes/props/float.tscn').instantiate()
						prop_container.add_child(prop_float)
						prop = prop_float
					'Vector2':
						var prop_vec2 = preload('res://addons/hengo/scenes/props/vec2.tscn').instantiate()
						prop_container.add_child(prop_vec2)
						prop = prop_vec2
					'Vector2i':
						var prop_vec2i = preload('res://addons/hengo/scenes/props/vec2i.tscn').instantiate()
						prop_container.add_child(prop_vec2i)
						prop = prop_vec2i
					'Vector3':
						var prop_vec3 = preload('res://addons/hengo/scenes/props/vec3.tscn').instantiate()
						prop_container.add_child(prop_vec3)
						prop = prop_vec3
					'Vector3i':
						var prop_vec3i = preload('res://addons/hengo/scenes/props/vec3i.tscn').instantiate()
						prop_container.add_child(prop_vec3i)
						prop = prop_vec3i
					'Vector4':
						var prop_vec4 = preload('res://addons/hengo/scenes/props/vec4.tscn').instantiate()
						prop_container.add_child(prop_vec4)
						prop = prop_vec4
					'Color':
						var prop_color = preload('res://addons/hengo/scenes/props/color.tscn').instantiate()
						prop_container.add_child(prop_color)
						prop = prop_color
					'bool':
						var prop_bool = preload('res://addons/hengo/scenes/props/boolean.tscn').instantiate()
						prop_container.add_child(prop_bool)
						prop = prop_bool
					'Variant':
						var l: Label = CNODE_INPUT_LABEL.instantiate()
						l.text = 'null'
						prop_container.add_child(l)
					_:
						var l: Label = CNODE_INPUT_LABEL.instantiate()

						if prop_container.get_child_count() < 3:
							var global: HenGlobal = Engine.get_singleton(&'Global')
							if HenUtils.is_type_relation_valid(
								global.SAVE_DATA.identity.type,
								io_type,
							):
								l.text = 'self'

							prop_container.add_child(l)
						

		if prop and _default_value:
			prop.set_default(str(_default_value))

		if prop and prop.has_signal('value_changed'):
			prop.value_changed.connect(_on_value.bind(prop))
		
		if prop and prop.has_signal('on_set_res_data'):
			prop.on_set_res_data.connect(_on_set_res_data)

		# props ref
		if _add_prop_ref: add_prop_ref()


func _on_set_res_data(_data: Dictionary) -> void:
	on_set_res_data.emit(_data)


func _on_value(_value, _prop) -> void:
	on_value_change.emit(_value, _prop.get_generated_code())


func add_prop_ref(_default = null, _prop_idx: int = -1) -> HenDropdown:
	# props ref
	var input_container = get_node('%CNameInput')
	var prop_ref_bt = DROPDOWN_SCENE.instantiate()

	# prop_ref_bt.text = ''
	# prop_ref_bt.icon = preload('res://addons/hengo/assets/icons/circle-dot.svg')
	# prop_ref_bt.type = 'all_props'
	# prop_ref_bt.tooltip_text = 'Bind prop value'
	
	# prop_ref_bt.add_theme_stylebox_override('normal', StyleBoxEmpty.new())
	# prop_ref_bt.input_ref = input_ref

	# if _default:
	# 	prop_ref_bt.set_default(_default)

	# input_container.add_child(prop_ref_bt)

	# prop_ref_bt.value_changed.connect(_on_prop_value_changed)

	return prop_ref_bt


func _on_prop_value_changed(_value, _code_value) -> void:
	pass
	# input_ref.value = _value
	# input_ref.code_value = _code_value
	# input_ref.is_prop = true


func reset_in_props(_jump_first: bool = false) -> void:
	if type == 'in':
		for in_prop in get_node('%CNameInput').get_children().slice(3 if _jump_first else 2):
			get_node('%CNameInput').remove_child(in_prop)
			in_prop.queue_free()
		
	root.reset_size()


func set_connected_color(_color: Color = Color.TRANSPARENT) -> void:
	var style: StyleBoxFlat = get('theme_override_styles/panel')
	if not style: return
	
	style.bg_color = _color


func remove_in_prop(_ignore_prop: bool = false) -> void:
	if type == 'in':
		for in_prop in get_node('%CNameInput').get_children().slice(2):
			if _ignore_prop and in_prop is HenDropdown and in_prop.type == 'all_props':
				continue

			in_prop.free()
	
	root.reset_size()


# only called by props signal
func set_default(_name: String) -> void:
	if _name.begins_with('t:'):
		change_type(_name.split('t:')[1])
		return
	
	change_name(_name)


func remove_out_prop() -> void:
	if type == 'out':
		var prop_container = get_node('%CNameOutput')
		for node in prop_container.get_children():
			if not node is Label and not node is TextureRect:
				prop_container.remove_child(node)
				node.queue_free()
		
	reset_size()


# type behavior
func set_type(_type: String) -> void:
	var connector = get_node('%Connector')

	connector.set('modulate', Color('#fff'))

	match _type:
		'String':
			connector.texture = HenUtils.get_icon_texture('circle')
			connector.set('modulate', Color('#8eef97'))
		'float':
			connector.texture = HenUtils.get_icon_texture('circle')
			connector.set('modulate', Color('#FFDD65'))
		'int':
			connector.texture = HenUtils.get_icon_texture('circle')
			connector.set('modulate', Color('#5ABBEF'))
		'bool':
			connector.texture = HenUtils.get_icon_texture('circle')
			connector.set('modulate', Color('#FC7F7F'))
		'Variant':
			connector.texture = HenUtils.get_icon_texture('circle')
			connector.set('modulate', Color('#72788a'))
		_:
			connector.texture = HenUtils.get_icon_texture(_type)
	
	tooltip_text = _type

	if root: root.reset_size()


func change_type(_type: String, _default_value = null, _sub_type: String = '', _add_prop_ref: bool = true) -> void:
	set_type(_type)

	if type == 'in':
		reset_in_props()
		set_in_prop(_default_value, _add_prop_ref)
	else:
		remove_out_prop()
		set_out_prop(_sub_type, _default_value)

	root.reset_size()


func _on_expression_save(_code_value: String, _word_list: Array) -> void:
	on_expression_save.emit(_code_value, _word_list)


func reset_signals(_inout: HenVCInOutData):
	for signal_name: StringName in [
		'request_method_picker',
		'on_mouse_enter',
		'request_create_connection',
		'on_value_change',
		'on_outprop_value_change',
		'outprop_config_request',
		'inprop_config_request',
		'on_expression_save',
		'on_set_res_data'
	]:
		for connection: Dictionary in get_signal_connection_list(signal_name):
			@warning_ignore('unsafe_method_access')
			connection.signal.disconnect(connection.callable)


	request_method_picker.connect(_inout.on_method_picker_request)
	on_mouse_enter.connect(_inout.on_io_mouse_enter)
	request_create_connection.connect(_inout.create_virtual_connection)
	on_value_change.connect(_inout.on_value_change)
	on_outprop_value_change.connect(_inout.on_outprop_value_change)
	outprop_config_request.connect(_inout.on_outprop_config_request)
	inprop_config_request.connect(_inout.on_inprop_config_request)
	on_expression_save.connect(_inout.on_expression_save)
	on_set_res_data.connect(_inout.on_set_res_data.emit)