@tool
class_name HenCnodeInOut extends PanelContainer


@export var root: HenCnode
@export_enum('in', 'out') var type: String

var input_ref: HenVCInOutData

class CNodeInOutConnectionData:
	var vc: HenVirtualCNode
	var in_out: HenVCInOutData

	func _init(_vc: HenVirtualCNode, _in_out: HenVCInOutData) -> void:
		vc = _vc
		in_out = _in_out


func _ready():
	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)
	gui_input.connect(_on_gui)


func _on_gui(_event: InputEvent) -> void:
	if _event is InputEventMouseButton:
		if _event.pressed:
			if _event.button_index == MOUSE_BUTTON_LEFT:
				HenGlobal.can_make_connection = true

				var connector: TextureRect = get_node('%Connector')
				var pos = HenGlobal.CAM.get_relative_vec2(get_node('%Connector').global_position)

				HenGlobal.CONNECTION_GUIDE.is_in_out = true
				HenGlobal.CONNECTION_GUIDE.start(pos + connector.size / 2, self)
		else:
			if HenGlobal.can_make_connection and not HenGlobal.connection_to_data:
				# call mehotd list on in_out type
				var method_list = preload('res://addons/hengo/scenes/utils/method_picker.tscn').instantiate()
				var data: Dictionary = {
					from = root.virtual_ref,
					in_out_id = input_ref.id,
				}

				if type == 'in':
					data.to_virtual_ref = input_ref
				else:
					data.from_virtual_ref = input_ref

				method_list.start(input_ref.type, get_global_mouse_position(), false, type, data)

				HenGlobal.GENERAL_POPUP.get_parent().show_content(method_list, 'Pick a Method', get_global_mouse_position())

			elif HenGlobal.can_make_connection and HenGlobal.connection_to_data:
				# try connection
				var connection: HenVCConnectionReturn = create_virtual_connection(HenGlobal.connection_to_data)

				if connection:
					HenGlobal.history.create_action('Add Connection')
					HenGlobal.history.add_do_method(connection.add)
					HenGlobal.history.add_do_reference(connection)
					HenGlobal.history.add_undo_method(connection.remove)
					HenGlobal.history.commit_action()

			HenGlobal.CONNECTION_GUIDE.end()

			HenGlobal.connection_to_data = null
			HenGlobal.can_make_connection = false
			HenGlobal.TOOLTIP.close()
	elif _event is InputEventMouseMotion:
		if type == 'out':
			HenGlobal.TOOLTIP.go_to(get_global_mouse_position(), '[i]Connect[/i]')
		else:
			HenGlobal.TOOLTIP.close()

func _on_enter() -> void:
	if not HenGlobal.can_make_connection:
		get('theme_override_styles/panel/').set('border_color', Color(1., 1., 1., .7))
		return

	get('theme_override_styles/panel/').set('border_color', Color.RED)

	HenGlobal.connection_to_data = CNodeInOutConnectionData.new(
		self.root.virtual_ref,
		input_ref,
	)

	if HenGlobal.CONNECTION_GUIDE.is_in_out:
		var connector: TextureRect = get_node('%Connector')
		var pos = HenGlobal.CAM.get_relative_vec2(get_node('%Connector').global_position)

		HenGlobal.CONNECTION_GUIDE.hover_pos = pos + connector.size / 2
		HenGlobal.CONNECTION_GUIDE.gradient.colors[1] = get_type_color(input_ref.type)

func _on_exit() -> void:
	get('theme_override_styles/panel/').set('border_color', Color.TRANSPARENT)
	
	HenGlobal.TOOLTIP.close()
	HenGlobal.connection_to_data = null

	if HenGlobal.CONNECTION_GUIDE.is_in_out:
		HenGlobal.CONNECTION_GUIDE.hover_pos = null
		HenGlobal.CONNECTION_GUIDE.gradient.colors[1] = Color.WHITE


func create_virtual_connection(_data: CNodeInOutConnectionData) -> HenVCConnectionReturn:
	if type == 'in':
		return root.virtual_ref.create_input_connection(
			input_ref.id,
			_data.in_out.id,
			_data.vc
		)

	return _data.vc.create_input_connection(
		_data.in_out.id,
		input_ref.id,
		root.virtual_ref
	)


func change_name(_text: String) -> void:
	get_node('%Name').text = _text
	size.x = 0


func set_out_prop(_sub_type: String = '', _default_value = null) -> void:
	if type == 'out':
		var prop_container = get_node('%CNameOutput')
		var prop

		match _sub_type:
			'@dropdown':
				var dropdown = preload('res://addons/hengo/scenes/props/dropdown.tscn').instantiate()

				dropdown.type = input_ref.category
				dropdown.custom_data = input_ref.data
				dropdown.input_ref = input_ref

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
	if input_ref:
		input_ref.value = _value
		input_ref.type = _type
		input_ref.code_value = _prop.get_generated_code()


func set_in_prop(_default_value = null, _add_prop_ref: bool = true) -> void:
	if type == 'in':
		var prop_container = get_node('%CNameInput')
		var prop

		if prop_container.get_child_count() > 4:
			return

		match input_ref.sub_type:
			'@dropdown':
				var dropdown = preload('res://addons/hengo/scenes/props/dropdown.tscn').instantiate()

				dropdown.type = input_ref.category
				dropdown.custom_data = input_ref.data
				dropdown.input_ref = input_ref

				match input_ref.category:
					'enum_list':
						dropdown.text = ClassDB.class_get_enum_constants(input_ref.data[0], input_ref.data[1])[0]
						dropdown.custom_value = '.'.join(input_ref.data) + '.' + dropdown.text
					'get_prop', 'set_prop':
						dropdown.alignment = HORIZONTAL_ALIGNMENT_LEFT
						dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL

				
				prop_container.add_child(dropdown)
				prop = dropdown
			'expression':
				var expression_bt: HenExpressionBt = preload('res://addons/hengo/scenes/utils/expression_bt.tscn').instantiate()

				expression_bt.v_cnode = root.virtual_ref

				prop_container.add_child(expression_bt)
				prop = expression_bt

			_:
				match input_ref.type:
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
					'bool':
						var prop_bool = preload('res://addons/hengo/scenes/props/boolean.tscn').instantiate()
						prop_container.add_child(prop_bool)
						prop = prop_bool
					'Variant':
						var l: Label = HenAssets.CNodeInputLabel.instantiate()
						l.text = 'null'
						prop_container.add_child(l)
					_:
						var l: Label = HenAssets.CNodeInputLabel.instantiate()

						if prop_container.get_child_count() < 3:
							l.text = input_ref.code_value
							if l.text == '_ref.':
								l.text = 'self'
							
							prop_container.add_child(l)
						

		if prop and _default_value:
			prop.set_default(str(_default_value))

		if prop and prop.has_signal('value_changed'):
			prop.value_changed.connect(_on_value.bind(prop))

		# props ref
		if _add_prop_ref: add_prop_ref()


func _on_value(_value, _prop) -> void:
	if input_ref:
		input_ref.value = _value
		input_ref.code_value = _prop.get_generated_code()


func add_prop_ref(_default = null, _prop_idx: int = -1) -> HenDropdown:
	# props ref
	var input_container = get_node('%CNameInput')
	var prop_ref_bt = preload('res://addons/hengo/scenes/props/dropdown.tscn').instantiate()
	prop_ref_bt.text = ''
	prop_ref_bt.icon = preload('res://addons/hengo/assets/icons/circle-dot.svg')
	prop_ref_bt.type = 'all_props'
	prop_ref_bt.tooltip_text = 'Bind prop value'
	
	prop_ref_bt.add_theme_stylebox_override('normal', StyleBoxEmpty.new())
	prop_ref_bt.input_ref = input_ref

	if _default:
		prop_ref_bt.set_default(_default)

	input_container.add_child(prop_ref_bt)

	prop_ref_bt.value_changed.connect(_on_prop_value_changed)

	return prop_ref_bt


func _on_prop_value_changed(_value, _code_value) -> void:
	input_ref.value = _value
	input_ref.code_value = _code_value
	input_ref.is_prop = true


func reset_in_props(_jump_first: bool = false) -> void:
	if type == 'in':
		for in_prop in get_node('%CNameInput').get_children().slice(3 if _jump_first else 2):
			get_node('%CNameInput').remove_child(in_prop)
			in_prop.queue_free()
		
	root.reset_size()


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
			connector.texture = HenAssets.get_icon_texture('circle')
			connector.set('modulate', Color('#8eef97'))
		'float':
			connector.texture = HenAssets.get_icon_texture('circle')
			connector.set('modulate', Color('#FFDD65'))
		'int':
			connector.texture = HenAssets.get_icon_texture('circle')
			connector.set('modulate', Color('#5ABBEF'))
		'bool':
			connector.texture = HenAssets.get_icon_texture('circle')
			connector.set('modulate', Color('#FC7F7F'))
		'Variant':
			connector.texture = HenAssets.get_icon_texture('circle')
			connector.set('modulate', Color('#72788a'))
		_:
			connector.texture = HenAssets.get_icon_texture(_type)
	
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


func get_type_color(_type: String) -> Color:
	match _type:
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
			if ClassDB.is_parent_class(_type, 'Control'):
				return Color('#8eef97')
			elif ClassDB.is_parent_class(_type, 'Node2D'):
				return Color('#5ABBEF')
			elif ClassDB.is_parent_class(_type, 'Node3D'):
				return Color('#FC7F7F')
			elif ClassDB.is_parent_class(_type, 'AnimationMixer'):
				return Color('#c368ed')

			return Color.WHITE
