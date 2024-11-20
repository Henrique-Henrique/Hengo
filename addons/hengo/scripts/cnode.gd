@tool
extends PanelContainer

# imports
const _Global = preload('res://addons/hengo/scripts/global.gd')
const _CNode = preload('res://addons/hengo/scripts/cnode.gd')
const _Enums = preload('res://addons/hengo/references/enums.gd')
const _Assets = preload('res://addons/hengo/scripts/assets.gd')
const _Router = preload('res://addons/hengo/scripts/router.gd')
const _CodeGeneration = preload('res://addons/hengo/scripts/code_generation.gd')
const _SaveLoad = preload('res://addons/hengo/scripts/save_load.gd')
const _ConnectionLine = preload('res://addons/hengo/scripts/connection_line.gd')

var flow_to: Dictionary = {}
var type
var cnode_type
var route_ref: Dictionary
var data: Dictionary = {}
var category: String
var raw_name: String
var hash: int
var connectors: Dictionary = {}
var from_lines: Array = []
var deleted: bool = false

var comment_ref

# behavior
var moving: bool = false
var selected: bool = false

# only on state signal
var old_state_event_connected: PanelContainer

# tooltip
var _is_mouse_enter: bool = false
var _preview_timer: SceneTreeTimer

signal on_move


func _ready():
	var title_container := get_node('%TitleContainer') as PanelContainer

	title_container.gui_input.connect(_on_gui)
	title_container.mouse_entered.connect(_on_enter)
	title_container.mouse_exited.connect(_on_exit)
	gui_input.connect(_on_gui)

# private
#


func _on_enter() -> void:
	_is_mouse_enter = true

	_preview_timer = get_tree().create_timer(.5)
	_preview_timer.timeout.connect(_on_tooltip)

	if _Global.can_make_flow_connection:
		_Global.flow_connection_to_data = {
			from_cnode = self
		}

		if not _Global.CONNECTION_GUIDE.is_in_out:
			var pos: Vector2 = _Global.CAM.get_relative_vec2(global_position)
			pos.x += size.x / 2

			_Global.CONNECTION_GUIDE.hover_pos = pos
			_Global.CONNECTION_GUIDE.gradient.colors = [Color('#00f6ff'), Color('#00f6ff')]

			pivot_offset = size / 2
			var tween = create_tween().set_trans(Tween.TRANS_SPRING)
			tween.tween_property(self, 'scale', Vector2(1.05, 1.05), .03)
			tween.tween_property(_Global.flow_cnode_from, 'scale', Vector2(1.05, 1.05), .03)
			
			_Global.flow_cnode_from.modulate = Color('#00f6ff')
			_Global.flow_cnode_from.get_node('%Border').visible = true
			
			modulate = Color('#00f6ff')
			get_node('%Border').visible = true
			get_node('%Border').get('theme_override_styles/panel').set('border_color', Color('#00f6ff'))


func _on_exit() -> void:
	_Global.flow_connection_to_data = {}

	if not _Global.CONNECTION_GUIDE.is_in_out:
		_Global.CODE_TOOLTIP.visible = false
		_Global.CONNECTION_GUIDE.hover_pos = null
		_Global.CONNECTION_GUIDE.gradient.colors = [Color.GRAY, Color.GRAY]

		var tween2 = create_tween().set_trans(Tween.TRANS_SPRING)
		tween2.tween_property(self, 'scale', Vector2(1, 1), .05)
		
		if _Global.flow_cnode_from:
			tween2.tween_property(_Global.flow_cnode_from, 'scale', Vector2(1, 1), .05)
			_Global.flow_cnode_from.modulate = Color.WHITE
			_Global.flow_cnode_from.get_node('%Border').visible = false

		modulate = Color.WHITE
		get_node('%Border').visible = false

	var tween = create_tween().set_trans(Tween.TRANS_EXPO)
	tween.tween_property(_Global.CODE_TOOLTIP, 'modulate', Color.TRANSPARENT, .3)

	_is_mouse_enter = false

	_preview_timer.timeout.disconnect(_on_tooltip)

	await tween.finished


func _on_tooltip() -> void:
	if _is_mouse_enter:
		print('ss')
		var code: String = _CodeGeneration.parse_token_and_value(self).strip_edges().replace('\t', '    ')
		var text_edit: TextEdit = _Global.CODE_TOOLTIP.get_child(0)
		var label: Label = _Global.CODE_TOOLTIP.get_child(1)

		label.text = ''
		label.size = Vector2.ZERO
		text_edit.text = ''
		text_edit.size = Vector2.ZERO
		_Global.CODE_TOOLTIP.size = Vector2.ZERO
		label.text = code

		text_edit.text = code

		await get_tree().process_frame
		_Global.CODE_TOOLTIP.position.x = self.global_position.x
		_Global.CODE_TOOLTIP.pivot_offset = Vector2(
			0,
			_Global.CODE_TOOLTIP.size.y
		)

		_Global.CODE_TOOLTIP.position.y = self.global_position.y - _Global.CODE_TOOLTIP.size.y
		_Global.CODE_TOOLTIP.scale = Vector2.ZERO
		_Global.CODE_TOOLTIP.modulate = Color.TRANSPARENT
		_Global.CODE_TOOLTIP.visible = true

		var tween = create_tween().set_trans(Tween.TRANS_CUBIC)
		tween.set_parallel(true)
		tween.tween_property(_Global.CODE_TOOLTIP, 'scale', Vector2.ONE, .1)
		tween.tween_property(_Global.CODE_TOOLTIP, 'modulate', Color.WHITE, .3)


func _on_gui(_event: InputEvent) -> void:
	if _event is InputEventMouseButton:
		if _event.pressed:
			_Global.CODE_TOOLTIP.visible = false
			# this is for tooltip
			_is_mouse_enter = false
			if _event.ctrl_pressed:
				if selected:
					unselect()
				else:
					select()
			else:
				if _event.button_index == MOUSE_BUTTON_LEFT:
					if selected:
						for i in get_tree().get_nodes_in_group(_Enums.CNODE_SELECTED_GROUP):
							i.moving = true
					else:
						moving = true
						# cleaning other selects
						for i in get_tree().get_nodes_in_group(_Enums.CNODE_SELECTED_GROUP):
							i.moving = false
							i.unselect()
						select()
		else:
			moving = false
			# group moving false
			for i in get_tree().get_nodes_in_group(_Enums.CNODE_SELECTED_GROUP):
				i.moving = false


func _input(_event: InputEvent):
	if _event is InputEventMouseMotion:
		# moving on click
		if moving and not comment_ref:
			if _Global.CAM:
				move(position + _event.relative / _Global.CAM.transform.x.x)


# used when pick state on state signal
func _on_dropdown_state_pick(_value: Dictionary) -> void:
	var state = _value.state_ref

	# TODO check if is the same state as old, if is the same, dont do anything
	if old_state_event_connected:
		state.remove_event(old_state_event_connected)
		old_state_event_connected = null

	var event = state.add_event({
		name = 'Connect',
		type = 'state_signal'
	})
	old_state_event_connected = event

# public
#
func move(_pos: Vector2) -> void:
	position = _pos
	emit_signal('on_move')
	# print(position, ' : ', global_position)

func select() -> void:
	add_to_group(_Enums.CNODE_SELECTED_GROUP)
	get_node('%SelectBorder').visible = true
	selected = true


func unselect() -> void:
	remove_from_group(_Enums.CNODE_SELECTED_GROUP)
	get_node('%SelectBorder').visible = false
	selected = false

func change_name(_name: String) -> void:
	get_node('%Title').text = _name


func change_name_and_raw(_name: String) -> void:
	get_node('%Title').text = _name
	raw_name = _name


func get_cnode_name() -> String:
	return raw_name

func get_fantasy_name() -> String:
	return get_node('%Title').text

# using on undo / redo
func add_to_scene() -> void:
	var in_container = get_node('%InputContainer')
	var out_container = get_node('%OutputContainer')

	_Global.CNODE_CONTAINER.add_child(self)

	for input in in_container.get_children():
		input.show_connection(false)

	for output in out_container.get_children():
		output.show_connection(false)

	for line in from_lines:
		line.add_to_scene(false)

	for conn_key in flow_to.keys():
		for line in get_connector(conn_key).connections_lines:
			line.add_to_scene(false)


	if not (_Router.route_reference[route_ref.id] as Array).has(self):
		_Router.route_reference[route_ref.id].append(self)
	
	deleted = false


func remove_from_scene() -> void:
	if is_inside_tree():
		var in_container = get_node('%InputContainer')
		var out_container = get_node('%OutputContainer')

		for input in in_container.get_children():
			input.hide_connection(false)

		for output in out_container.get_children():
			output.hide_connection(false)

		for line in from_lines.duplicate():
			line.remove_from_scene(false)

		for conn_key in flow_to.keys():
			for line in get_connector(conn_key).connections_lines:
				line.remove_from_scene(false)

		_Router.route_reference[route_ref.id].erase(self)
		_Global.CNODE_CONTAINER.remove_child(self)
	
	deleted = true


func add_input(_input: Dictionary) -> void:
	var in_container = get_node('%InputContainer')
	var input := _Assets.CNodeInputScene.instantiate()
	var values = {}

	# checking if has resource to define data (used to reflect side menu changes)
	if _input.has('res'):
		var res = _input.get('res')
		values = {
			name = res.name,
			type = res.type
		}
		# adding intput reference to variable resource
		res.in_out_ref.append(input)
	else:
		values = _input

	if _input.has('ref'):
		input.is_ref = true

	if _input.has('category'):
		input.category = _input.category

		match _input.category:
			# make connector invisible
			# useful when input don't want a connection
			'state_transition', 'hengo_events', 'disabled':
				input.get_node('%CNameInput').get_child(0).visible = false

	if _input.has('data'):
		input.custom_data = _input.get('data')

	var type = values.get('type') if values.has('type') else 'Variant'
	input.set_type(type)

	input.get_node('%Name').text = values.name
	input.root = self
	
	input.set_in_prop(_input.get('in_prop') if _input.has('in_prop') else null)
	in_container.add_child(input)


func add_output(_output: Dictionary) -> void:
	var out_container = get_node('%OutputContainer')

	var output := _Assets.CNodeOutputScene.instantiate()
	var values = {}

	# checking if has resource to define data (used to reflect side menu changes)
	if _output.has('res'):
		var res = _output.get('res')
		values = {
			name = res.name,
			type = res.type
		}

		# adding output reference to variable resource
		res.in_out_ref.append(output)
	else:
		values = _output

	if _output.has('category'):
		output.category = _output.category

	if _output.has('sub_type'):
		output.sub_type = _output.sub_type

	if _output.has('data'):
		output.custom_data = _output.get('data')

	var type = values.get('type') if values.has('type') else 'Variant'
	output.set_type(type)

	output.get_node('%Name').text = values.name
	output.root = self

	output.set_out_prop(_output.sub_type if _output.has('sub_type') else '', _output.get('out_prop') if _output.has('out_prop') else null)
	out_container.add_child(output)

func check_error() -> void:
	var in_container = get_node('%InputContainer')
	var out_container = get_node('%OutputContainer')
	var errors: Array[Dictionary] = []

	match type:
		'go_to_void':
			var input = in_container.get_child(1)

			# checking if other script has changed state name
			if not _SaveLoad.script_has_state(input.custom_data, input.get_in_prop_by_id_or_null().get_value()):
				errors.append({
					input_instance_id = input.get_instance_id(),
					msg = input.get_in_out_name() + ": the input type isn't derived from the current object; please set its value explicitly"
				})

		'signal_connection':
			var input = in_container.get_child(0)

			# checking if it's connected
			# signal connection need a ref
			if input.in_connected_from:
				disable_error()
				return

			errors.append({
				input_instance_id = input.get_instance_id(),
				msg = input.get_in_out_name() + ": the input type isn't derived from the current object; please set its value explicitly"
			})
		'cast':
			var output = out_container.get_child(0)
			
			# if not connected pass
			if output.to_connection_lines.is_empty():
				disable_error()
				return

			var input = in_container.get_child(0)

			# checking if it's connected
			# signal connection need a ref
			if input.in_connected_from:
				disable_error()
				return

			errors.append({
				input_instance_id = input.get_instance_id(),
				msg = input.get_in_out_name() + ": the input type isn't derived from the current object; please set its value explicitly"
			})

	if errors.size() > 0:
		get_node('%ErrorBorder').visible = true
		_Global.ERROR_BT.set_error_on_id(get_instance_id(), errors)
	else:
		disable_error()


func disable_error() -> void:
	get_node('%ErrorBorder').visible = false


func get_connection_lines_in_flow() -> Dictionary:
	match type:
		'if':
			var flow_dict: Dictionary = {
				base_conn = get_input_connection_lines()
			}

			for conn in connectors.values():
				var connector = get_connector(conn.type)

				if connector:
					var result: Array = get_connector_lines(connector)
					flow_dict[conn.type] = result
			
			return flow_dict
		_:
			var connector = get_connector()
			var result: Array = get_connector_lines(connector)

			return {cnode = result}


func get_connector_lines(_connector) -> Array:
	var flow_lines: Array = []
	var conn_lines: Array = []

	# next cnode
	if _connector.connections_lines.size() > 0:
		var cnode = _connector.connections_lines[0].to_cnode
		
		flow_lines += _connector.connections_lines

		if cnode.connectors.keys().size() == 1:
			var result: Array = cnode.get_connector_lines(cnode.get_connector())

			if not result.is_empty():
				flow_lines += result[0]
				conn_lines += cnode.get_input_connection_lines() + result[1]

	return [flow_lines, conn_lines]


func get_input_connection_lines() -> Array:
	match type:
		'if':
			var input = get_node('%TitleContainer').get_child(0).get_child(0)

			if input.from_connection_lines.size() > 0:
				return input.from_connection_lines + input.from_connection_lines[0].from_cnode.get_input_connection_lines()
		_:
			var input_container = get_node('%InputContainer')
			var lines: Array = []

			for input in input_container.get_children():
				lines += input.from_connection_lines

				if input.from_connection_lines.size() > 0:
					lines += input.from_connection_lines[0].from_cnode.get_input_connection_lines()
				
			return lines
	return []


func get_connector(_type: String = 'cnode') -> Variant:
	if connectors.has(_type): return connectors[_type]

	return null


func get_border() -> Panel:
	return get_node('%Border')


func show_debug_value(_value) -> void:
	var container: VBoxContainer = get_node('%Container')
	container.get_child(1).show_value(_value)

# static
#
static func instantiate_cnode(_config: Dictionary) -> _CNode:
	var instance: _CNode = _Assets.CNodeScene.instantiate()

	if not _config.is_empty():
		instance.hash = _Global.get_new_node_counter() if not _config.has('hash') else _config.hash
		instance.raw_name = _config.name
		instance.change_name(_config.get('fantasy_name') if _config.has('fantasy_name') else _config.name)

		var title_container = instance.get_node('%TitleContainer')

		if not _config.has('type'):
			if _config.has('sub_type'):
				match _config.sub_type:
					'var', 'local_var':
						_config.type = ''
					'debug_value':
						var debug_value_scene = load('res://addons/hengo/scenes/props/debug_value.tscn').instantiate()
						var container: VBoxContainer = instance.get_node('%Container')
						
						container.add_child(debug_value_scene)
						container.move_child(debug_value_scene, 1)

						title_container.get_node('%TitleIcon').texture = load('res://addons/hengo/assets/icons/cnode/debug.svg')
						title_container.get('theme_override_styles/panel').set('bg_color', Color('#8a7346'))

						_config.type = 'default'
					'func', 'user_func':
						# color
						
						match _config.name:
							'make_transition':
								title_container.get('theme_override_styles/panel').set('bg_color', Color('#000'))
							_:
								title_container.get('theme_override_styles/panel').set('bg_color', Color('#464A73'))
						
						title_container.get_node('%TitleIcon').texture = load('res://addons/hengo/assets/icons/cnode/func.svg')
						_config.type = 'default'
					'void':
						title_container.get_node('%TitleIcon').texture = load('res://addons/hengo/assets/icons/cnode/void.svg')
						_config.type = 'default'
					'signal_connection', 'signal_disconnection', 'signal_emit':
						# color
						title_container.get('theme_override_styles/panel').set('bg_color', Color('#764A75'))
						title_container.get_node('%TitleIcon').texture = load('res://addons/hengo/assets/icons/cnode/signal.svg')
						_config.type = 'default'
					'set_var', 'set_prop', 'get_prop':
						# color
						title_container.get('theme_override_styles/panel').set('bg_color', Color('#4A7346'))
						title_container.get_node('%TitleIcon').texture = load('res://addons/hengo/assets/icons/cnode/set_var.svg')
						_config.type = 'default'
					'virtual', 'func_input', 'signal_virtual':
						# color
						title_container.get('theme_override_styles/panel').set('bg_color', Color('#734646'))
						title_container.get_node('%TitleIcon').texture = load('res://addons/hengo/assets/icons/cnode/virtual.svg')
						_config.type = 'default'
					'cast', 'raw_code':
						match _config.sub_type:
							'raw_code':
								title_container.get_node('%TitleIcon').texture = load('res://addons/hengo/assets/icons/cnode/raw.svg')
							'cast':
								title_container.get_node('%TitleIcon').texture = load('res://addons/hengo/assets/icons/cnode/cast.svg')

						title_container.get('theme_override_styles/panel').set('bg_color', Color('#000'))
						_config.type = 'default'
					'self_go_to_void':
						title_container.get_node('%TitleIcon').texture = load('res://addons/hengo/assets/icons/cnode/go_to.svg')
						title_container.get('theme_override_styles/panel').set('bg_color', Color('#000'))
						_config.type = 'default'
					'for', 'for_arr':
						title_container.get_node('%TitleIcon').texture = load('res://addons/hengo/assets/icons/cnode/for.svg')
						title_container.get('theme_override_styles/panel').set('bg_color', Color('#8c5c37'))
						_config.type = 'default'
					_:
						_config.type = 'default'

		instance.cnode_type = _config.type

		# this tell hengo how to generate code
		if _config.has('category'):
			instance.category = _config.get('category')

		if _config.has('inputs'):
			for i in _config.get('inputs'):
				instance.add_input(i)

		if _config.has('outputs'):
			for i in _config.get('outputs'):
				instance.add_output(i)

		# custom data
		if _config.has('data'):
			instance.data = _config.data

		# instance flow connections
		match (_config.type):
			'default':
				var default_flow := _Assets.CNodeFlowScene.instantiate()
				var connector = default_flow.get_child(0)
				connector.root = instance
				instance.get_node('%Container').add_child(default_flow)
				instance.connectors.cnode = connector
			'if':
				var if_flow := _Assets.CNodeIfFlowScene.instantiate()
				for i in if_flow.get_node('%FlowContainer').get_children():
					i.root = instance
					instance.connectors[i.type] = i
				
				var input = _Assets.CNodeInputScene.instantiate()
				var container = title_container.get_child(0)
				container.add_child(input)
				container.move_child(input, 0)
				container.process_mode = Node.PROCESS_MODE_INHERIT
				input.root = instance
				input.set_type('bool')
				instance.get_node('%Container').add_child(if_flow)

				# color
				title_container.get('theme_override_styles/panel').set('bg_color', Color('#674883'))
				title_container.get_node('%TitleIcon').texture = load('res://addons/hengo/assets/icons/cnode/if.svg')

			'img':
				var center_img = _Assets.CNodeCenterImage.instantiate()
				var img = center_img.get_node('%Img')
				var center_container = instance.get_node('%CenterContainer')

				img.texture = load('res://addons/hengo/assets/icons/' + _config.category + '.svg')

				center_container.set('theme_override_constants/separation', 5)
				center_container.add_child(center_img)
				center_container.move_child(center_img, 1)

				instance.get_node('%OutputContainer').alignment = BoxContainer.ALIGNMENT_CENTER
				title_container.visible = false
			'expression':
				title_container.get_node('%TitleIcon').texture = load('res://addons/hengo/assets/icons/cnode/math.svg')
				title_container.get('theme_override_styles/panel').set('bg_color', Color('#000'))

				var container = instance.get_node('%Container')
				var bt_container = load('res://addons/hengo/scenes/utils/expression_bt.tscn').instantiate()
				
				var bt = bt_container.get_child(0)
				bt.ref = instance
				
				if _config.has('exp'):
					bt.set_exp(_config.exp)
				
				container.add_child(bt_container)
				container.move_child(bt_container, 1)

		if _config.has('sub_type'):
			var sub_type = _config.get('sub_type')
			instance.type = sub_type

			match sub_type:
				# adding virtual cnodes references
				'virtual':
					match _config.route.type:
						_Router.ROUTE_TYPE.STATE:
							var ref = _config.route.state_ref
							ref.virtual_cnode_list.append(instance)
						_Router.ROUTE_TYPE.INPUT:
							var ref = _config.route.general_ref
							ref.virtual_cnode_list.append(instance)
				# virtual node of signal and func
				'signal_virtual', 'func_input':
					var ref = _config.route.item_ref
					ref.virtual_cnode_list.append(instance)
				'var', 'local_var':
					instance.get_node('%TitleContainer').visible = false
				'const':
					title_container.get_node('%TitleIcon').texture = load('res://addons/hengo/assets/icons/cnode/enum.svg')
					title_container.get('theme_override_styles/panel').set('bg_color', Color('#2f6063'))
				'singleton':
					title_container.get_node('%TitleIcon').texture = load('res://addons/hengo/assets/icons/cnode/singleton.svg')
					title_container.get('theme_override_styles/panel').set('bg_color', Color('#691818'))

		_Router.route_reference[_config.route.id].append(instance)
	
	instance.route_ref = _config.route

	if _config.has('pos'):
		instance.position = str_to_var(_config.pos)
	elif _config.has('position'):
		instance.position = _config.position
	else:
		instance.position = Vector2.ZERO

	instance.size = Vector2.ZERO

	return instance


static func instantiate_and_add(_config: Dictionary) -> _CNode:
	var cnode := instantiate_cnode(_config)
	cnode.add_to_scene()

	if _config.has('position'):
		cnode.position = _config.get('position')

	return cnode