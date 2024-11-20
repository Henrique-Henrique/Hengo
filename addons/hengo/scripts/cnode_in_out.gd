@tool
extends PanelContainer

# imports
const _Global = preload('res://addons/hengo/scripts/global.gd')
const _Assets = preload('res://addons/hengo/scripts/assets.gd')
const _ConnectionLine = preload('res://addons/hengo/scripts/connection_line.gd')
const _Enums = preload('res://addons/hengo/references/enums.gd')
const _Router = preload('res://addons/hengo/scripts/router.gd')
const _CNode = preload('res://addons/hengo/scripts/cnode.gd')

@export var root: PanelContainer
@export_enum('in', 'out') var type: String

var connection_type: String = 'Variant'
# cnode reference from connection
var in_connected_from
# id from output connection
var out_from_in_out
# connections lines
var from_connection_lines: Array = []
var to_connection_lines: Array = []
# identify to generate code based on ref (first input)
var is_ref: bool = false
var category: StringName

#reparent / remove
var is_reparenting: bool = false
var line_ref: _ConnectionLine
var reparent_data: Dictionary = {}
var old_conn_ref

# only when necessary
var custom_data
var sub_type

# private
#
func _ready():
	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)
	gui_input.connect(_on_gui)
	get_node('%Connector').item_rect_changed.connect(_on_connector_rect_update)

# updating line
func _on_connector_rect_update() -> void:
	var connector = get_node('%Connector')
	
	for line in from_connection_lines:
		line.conn_size = connector.size / 2
		line.update_line()
	
	for line in to_connection_lines:
		line.conn_size = connector.size / 2
		line.update_line()

func _on_gui(_event: InputEvent) -> void:
	if _event is InputEventMouseButton:
		if _event.pressed:
			if _event.button_index == MOUSE_BUTTON_LEFT:
				if in_connected_from:
					var line = from_connection_lines[0]

					is_reparenting = true
					line_ref = line
					old_conn_ref = self.get_node('%Connector')

					hide_connection()

					_Global.can_make_connection = true
					_Global.connection_first_data = {
						type = line.input.owner.type,
						conn_type = line.input.owner.connection_type
					}
					_Global.reparent_data = {
						from_type = line.input.owner.type,
						from_conn_type = line.input.owner.connection_type,
						from_conn = line.input
					}
					_on_enter()
				else:
					_Global.can_make_connection = true
					_Global.connection_first_data = {
						type = type,
						conn_type = connection_type
					}

					var connector: TextureRect = get_node('%Connector')
					var pos = _Global.CAM.get_relative_vec2(get_node('%Connector').global_position)

					_Global.CONNECTION_GUIDE.is_in_out = true
					_Global.CONNECTION_GUIDE.start(pos + connector.size / 2, self)
		else:
			if _Global.can_make_connection and _Global.connection_to_data.is_empty():
				# call mehotd list on in_out type
				print('type:: ', connection_type)
				var method_list = load('res://addons/hengo/scenes/utils/method_picker.tscn').instantiate()
				method_list.start(connection_type, get_global_mouse_position(), false, type, {
					from_in_out = self
				})
				_Global.GENERAL_POPUP.get_parent().show_content(method_list, 'Pick a Method', get_global_mouse_position())

			elif _Global.can_make_connection and _Global.connection_to_data.has('auto_cast'):
				var to_cnode: _CNode = _Global.connection_to_data.from.root

				# making auto cast
				var cast_cnode: _CNode = _CNode.instantiate_and_add(
					{
						name = 'Casting -> BBT',
						sub_type = 'cast',
						category = 'native',
						inputs = [
							{
								name = 'from',
								type = connection_type
							}
						],
						outputs = [
							{
								name = 'to',
								sub_type = '@dropdown',
								category = 'cast_type',
								out_prop = _Global.connection_to_data.conn_type
							}
						],
						position = lerp(to_cnode.position, root.position, .5),
						route = _Router.current_route
					}
				)

				var cast_input = cast_cnode.get_node('%InputContainer').get_child(0)
				var cast_output = cast_cnode.get_node('%OutputContainer').get_child(0)

				var first_line = cast_input.create_connection_and_instance({
					from = self,
					type = type,
					conn_type = connection_type
				})

				var second_line = cast_output.create_connection_and_instance(_Global.connection_to_data)

				cast_cnode.position.x -= cast_cnode.size.x / 4

				print(cast_cnode)

			elif _Global.can_make_connection and not _Global.connection_to_data.is_empty():
				# try connection
				var line := create_connection(_Global.connection_to_data)

				if line:
					_Global.history.create_action('Add Connection')
					_Global.history.add_do_method(line.add_to_scene)
					_Global.history.add_do_reference(line)
					_Global.history.add_undo_method(line.remove_from_scene)
					_Global.history.commit_action()
			
			_Global.CONNECTION_GUIDE.end()

			_Global.connection_to_data = {}
			_Global.connection_first_data = {}
			_Global.reparent_data = {}
			_Global.can_make_connection = false
			is_reparenting = false
			line_ref = null

func _on_enter() -> void:
	if not _Global.can_make_connection:
		if type == 'out':
			get('theme_override_styles/panel/').set('border_color', Color.LIGHT_CORAL)
		return
	
	if not _is_type_relatable(_Global.connection_first_data.type, type, _Global.connection_first_data.conn_type, connection_type):
		# if true, can auto instantiate cast
		if ClassDB.is_parent_class(connection_type, _Global.connection_first_data.conn_type):
			get('theme_override_styles/panel/').set('border_color', Color.RED)

			_Global.connection_to_data = {
				from = self,
				type = type,
				conn_type = connection_type,
				reparent_data = _Global.reparent_data,
				auto_cast = true
			}
		return

	get('theme_override_styles/panel/').set('border_color', Color.RED)

	_Global.connection_to_data = {
		from = self,
		type = type,
		conn_type = connection_type,
		reparent_data = _Global.reparent_data
	}


	if _Global.CONNECTION_GUIDE.is_in_out:
		var connector: TextureRect = get_node('%Connector')
		var pos = _Global.CAM.get_relative_vec2(get_node('%Connector').global_position)

		_Global.CONNECTION_GUIDE.hover_pos = pos + connector.size / 2
		_Global.CONNECTION_GUIDE.gradient.colors[1] = get_type_color(connection_type)

func _on_exit() -> void:
	get('theme_override_styles/panel/').set('border_color', Color.TRANSPARENT)
	
	_Global.connection_to_data = {}

	if _Global.CONNECTION_GUIDE.is_in_out:
		_Global.CONNECTION_GUIDE.hover_pos = null
		_Global.CONNECTION_GUIDE.gradient.colors[1] = Color.WHITE

func _input(_event: InputEvent):
	if _event is InputEventMouseMotion:
		pass

func _is_type_relatable(_from_type: String, _to_type: String, _from_conn_type: String, _to_conn_type: String) -> bool:
	# if connection is in => out or out => in
	# if not, can't connect
	if not _from_type == 'in' and _to_type == 'out' \
	or not _from_type == 'out' and _to_type == 'in':
		return false

	if _from_conn_type == _to_conn_type:
		return true

	if _from_conn_type == 'Variant' or _to_conn_type == 'Variant':
		return true

	# checking if is native types
	if _Enums.VARIANT_TYPES.has(_from_conn_type):
		if not _from_conn_type == _to_conn_type:
			return false
	# if it's not native, it's a class
	else:
		# checking if types is relatable
		if _from_type == 'out':

			if not ClassDB.is_parent_class(_from_conn_type, _to_conn_type):
				return false
		else:
			if not ClassDB.is_parent_class(_to_conn_type, _from_conn_type):
				return false

	return true

# public
#
func create_connection(_config: Dictionary) -> _ConnectionLine:
	var _type = type if not is_reparenting else _config.reparent_data.from_type
	var _conn_type = connection_type if not is_reparenting else _config.reparent_data.from_conn_type

	if not _is_type_relatable(_type, _config.type, _conn_type, _config.conn_type):
		return

	var line = _Assets.ConnectionLineScene.instantiate()

	line.gradient.colors[0] = get_type_color(_conn_type)
	line.gradient.colors[1] = get_type_color(_config.conn_type)

	match _conn_type:
		'String':
			line.default_color = Color('#8eef97')
		'float':
			line.default_color = Color('#FFDD65')
		'int':
			line.default_color = Color('#5ABBEF')
		'bool':
			line.default_color = Color('#FC7F7F')
		'Vector2':
			line.default_color = Color.REBECCA_PURPLE
		'Variant':
			var c = Color.WHITE
			c.a = .3
			line.default_color = c
		_:
			pass

	var from_conn = get_node('%Connector') if not is_reparenting else _config.reparent_data.from_conn
	var to_conn = _config.from.get_node('%Connector')
	var _root = root if not is_reparenting else _config.reparent_data.from_conn.owner.root
	var _self = self if not is_reparenting else _config.reparent_data.from_conn.owner

	line.conn_size = from_conn.size / 2

	if _self.type == 'in':
		line.from_cnode = _config.from.root
		line.to_cnode = _root
		line.input = to_conn
		line.output = from_conn
		for c_line in _self.from_connection_lines:
			c_line.remove_from_scene()
			#TODO undo/redo

		_self.in_connected_from = _config.from.root
		_self.out_from_in_out = _config.from
	elif _config.from.type == 'in':
		line.from_cnode = _root
		line.to_cnode = _config.from.root
		line.input = from_conn
		line.output = to_conn
		# clear other connections
		for c_line in _config.from.from_connection_lines:
			c_line.remove_from_scene()
			#TODO undo/redo

		_config.from.in_connected_from = _root
		_config.from.out_from_in_out = _self

	# signal to update connection line
	_root.connect('on_move', line.update_line)
	_config.from.root.connect('on_move', line.update_line)

	return line

func create_connection_and_instance(_config: Dictionary) -> _ConnectionLine:
	var line: _ConnectionLine = create_connection(_config)
	line.add_to_scene()
	return line

func change_name(_text: String) -> void:
	get_node('%Name').text = _text
	size.x = 0

func get_in_out_name() -> String:
	return get_node('%Name').text

func show_connection(_add_to_list: bool = true) -> void:
	match type:
		'in':
			for line in from_connection_lines:
				line.add_to_scene(_add_to_list)
		'out':
			for line in to_connection_lines:
				line.add_to_scene(_add_to_list)


func hide_connection(_remove_from_list: bool = true) -> void:
	match type:
		'in':
			for line in from_connection_lines.duplicate():
				line.remove_from_scene(_remove_from_list)
		'out':
			for line in to_connection_lines.duplicate():
				line.remove_from_scene(_remove_from_list)


func remove() -> void:
	hide_connection()

	get_parent().remove_child(self)
	root.size = Vector2.ZERO

func move_up_down(_type: String) -> void:
	match _type:
		'up':
			get_parent().move_child(self, max(0, get_index() - 1))
		'down':
			get_parent().move_child(self, get_index() + 1)
	
	await RenderingServer.frame_post_draw
	match type:
		'in':
			for line in from_connection_lines:
				line.update_line()
		'out':
			for line in to_connection_lines:
				line.update_line()


func set_out_prop(_sub_type: String = '', _default_value = null) -> void:
	if type == 'out':
		var prop_container = get_node('%CNameOutput')
		var prop

		match _sub_type:
			'@dropdown':
				var dropdown = load('res://addons/hengo/scenes/props/dropdown.tscn').instantiate()

				dropdown.type = category
				dropdown.custom_data = custom_data

				if not _default_value:
					dropdown.set_default('Node')

				get_child(0).process_mode = Node.PROCESS_MODE_INHERIT

				prop_container.add_child(dropdown)
				prop_container.move_child(dropdown, 0)
				prop = dropdown
		
		if _default_value:
			prop.set_default(str(_default_value))


func set_in_prop(_default_value = null) -> void:
	if type == 'in':
		var prop_container = get_node('%CNameInput')
		var prop

		if prop_container.get_child_count() > 2:
			return

		match connection_type:
			'String', 'NodePath', 'StringName':
				var str = load('res://addons/hengo/scenes/props/string.tscn').instantiate()
				prop_container.add_child(str)
				prop = str
			'int':
				var prop_int = load('res://addons/hengo/scenes/props/int.tscn').instantiate()
				prop_container.add_child(prop_int)
				prop = prop_int
			'float':
				var prop_float = load('res://addons/hengo/scenes/props/float.tscn').instantiate()
				prop_container.add_child(prop_float)
				prop = prop_float
			'Vector2':
				var prop_vec2 = load('res://addons/hengo/scenes/props/vec2.tscn').instantiate()
				prop_container.add_child(prop_vec2)
				prop = prop_vec2
			'@dropdown':
				var dropdown = load('res://addons/hengo/scenes/props/dropdown.tscn').instantiate()

				dropdown.type = category
				dropdown.custom_data = custom_data

				match category:
					'enum_list':
						dropdown.text = ClassDB.class_get_enum_constants(custom_data[0], custom_data[1])[0]
						dropdown.custom_value = '.'.join(custom_data) + '.' + dropdown.text

				prop_container.add_child(dropdown)
				prop = dropdown
			'bool':
				var prop_bool = load('res://addons/hengo/scenes/props/boolean.tscn').instantiate()
				prop_container.add_child(prop_bool)
				prop = prop_bool
			_:
				var l: Label = _Assets.CNodeInputLabel.instantiate()

				if prop_container.get_child_count() < 3:
					if _Global.script_config.type == connection_type:
						l.text = 'self'
					else:
						if _Enums.VARIANT_TYPES.has(connection_type):
							if connection_type == 'Variant':
								l.text = 'null'
							else:
								l.text = connection_type + '()'
						elif ClassDB.can_instantiate(connection_type):
							l.text = connection_type + '.new()'
					
					prop_container.add_child(l)
				
				if root.cnode_type == 'img':
					l.visible = false

		if _default_value:
			prop.set_default(str(_default_value))


func remove_in_prop() -> void:
	if type == 'in':
		var prop_container = get_node('%CNameInput')

		for in_prop in prop_container.get_children().slice(2):
			in_prop.free()
			root.size = Vector2.ZERO


func remove_out_prop() -> void:
	if type == 'out':
		var prop_container = get_node('%CNameOutput')

		if not prop_container.is_queued_for_deletion():
			var out_prop = prop_container.get_child(0)
			prop_container.remove_child(out_prop)
			out_prop.queue_free()

			await get_tree().process_frame
			root.size = Vector2.ZERO
		
	await get_tree().process_frame


func get_in_prop_by_id_or_null() -> PanelContainer:
	if type == 'in':
		var prop_container = get_node('%CNameInput')

		if prop_container.get_child_count() < 2:
			return null

		return prop_container.get_child(2)
	
	return null


func get_out_prop_by_id_or_null() -> PanelContainer:
	if type == 'out':
		var prop_container = get_node('%CNameOutput')

		if prop_container.get_child_count() < 2:
			return null

		return prop_container.get_child(0)
	
	return null


# type behavior
func set_type(_type: String) -> void:
	var icon_path = 'res://addons/hengo/assets/.editor_icons/' + _type + '.svg'
	var connector = get_node('%Connector')
	var circle_icon = load('res://addons/hengo/assets/icons/circle.svg')

	connector.set('modulate', Color('#fff'))

	match _type:
		'String':
			connector.texture = circle_icon
			connector.set('modulate', Color('#8eef97'))
		'float':
			connector.texture = circle_icon
			connector.set('modulate', Color('#FFDD65'))
		'int':
			connector.texture = circle_icon
			connector.set('modulate', Color('#5ABBEF'))
		'bool':
			connector.texture = circle_icon
			connector.set('modulate', Color('#FC7F7F'))
		'Variant':
			connector.texture = circle_icon
			connector.set('modulate', Color('#72788a'))
		_:
			if FileAccess.file_exists(icon_path):
				#TODO make icons a spritesheet
				var icon: Image = Image.load_from_file(icon_path)
				connector.texture = ImageTexture.create_from_image(icon)
			else:
				connector.texture = circle_icon
	
	connection_type = _type

func change_type(_type: String) -> void:
	var remove_conn: bool = connection_type != _type

	if type == 'in':
		remove_in_prop()
		set_in_prop()
	
	set_type(_type)
	
	if remove_conn:
		hide_connection()


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
		'Vector2':
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
			elif ClassDB.is_parent_class(_type, 'Node3D'):
				return Color('#FC7F7F')
			elif ClassDB.is_parent_class(_type, 'AnimationMixer'):
				return Color('#c368ed')

			return Color.WHITE