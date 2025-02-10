@tool
class_name HenCnode extends PanelContainer

enum TYPE {
	DEFAULT,
	IF,
	IMG,
	EXPRESSION,
}

enum SUB_TYPE {
	FUNC,
	VOID,
	VAR,
	LOCAL_VAR,
	DEBUG_VALUE,
	USER_FUNC,
	SET_VAR,
	SET_PROP,
	GET_PROP,
	VIRTUAL,
	FUNC_INPUT,
	CAST,
	IF,
	RAW_CODE,
	SELF_GO_TO_VOID,
	FOR,
	FOR_ARR,
	FOR_ITEM,
	FUNC_OUTPUT,
	CONST,
	SINGLETON,
	GO_TO_VOID,
	IMG,
	EXPRESSION,
	SET_LOCAL_VAR,
	IN_PROP,
	NOT_CONNECTED,
	DEBUG,
	DEBUG_PUSH,
	DEBUG_FLOW_START,
	START_DEBUG_STATE,
	DEBUG_STATE,
	BREAK,
	CONTINUE,
	PASS
}


var flow_to: Dictionary = {}
var type: TYPE
var sub_type: SUB_TYPE
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

# formatter
var can_move_to_format: bool = true

# pool
var is_pool: bool = false

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

	if HenGlobal.can_make_flow_connection:
		HenGlobal.flow_connection_to_data = {
			from_cnode = self
		}

		if not HenGlobal.CONNECTION_GUIDE.is_in_out:
			var pos: Vector2 = HenGlobal.CAM.get_relative_vec2(global_position)
			pos.x += size.x / 2

			HenGlobal.CONNECTION_GUIDE.hover_pos = pos
			HenGlobal.CONNECTION_GUIDE.gradient.colors = [Color('#00f6ff'), Color('#00f6ff')]

			pivot_offset = size / 2
			var tween = create_tween().set_trans(Tween.TRANS_SPRING)
			tween.tween_property(self, 'scale', Vector2(1.05, 1.05), .03)
			tween.tween_property(HenGlobal.flow_cnode_from, 'scale', Vector2(1.05, 1.05), .03)
			
			HenGlobal.flow_cnode_from.modulate = Color('#00f6ff')
			HenGlobal.flow_cnode_from.get_node('%Border').visible = true
			
			modulate = Color('#00f6ff')
			get_node('%Border').visible = true
			get_node('%Border').get('theme_override_styles/panel').set('border_color', Color('#00f6ff'))


func _on_exit() -> void:
	HenGlobal.flow_connection_to_data = {}

	if not HenGlobal.CONNECTION_GUIDE.is_in_out:
		HenGlobal.DOCS_TOOLTIP.visible = false
		HenGlobal.CONNECTION_GUIDE.hover_pos = null
		HenGlobal.CONNECTION_GUIDE.gradient.colors = [Color.GRAY, Color.GRAY]

		var tween2 = create_tween().set_trans(Tween.TRANS_SPRING)
		tween2.tween_property(self, 'scale', Vector2(1, 1), .05)
		
		if HenGlobal.flow_cnode_from:
			tween2.tween_property(HenGlobal.flow_cnode_from, 'scale', Vector2(1, 1), .05)
			HenGlobal.flow_cnode_from.modulate = Color.WHITE
			HenGlobal.flow_cnode_from.get_node('%Border').visible = false

		modulate = Color.WHITE
		get_node('%Border').visible = false

	_is_mouse_enter = false
	
	_preview_timer.timeout.disconnect(_on_tooltip)

	#TODO: reset this timer if hover again on other cnode
	get_tree().create_timer(.2).timeout.connect(func():
		if HenGlobal.DOCS_TOOLTIP.first_show:
			HenGlobal.DOCS_TOOLTIP.first_show = false
		else:
			HenGlobal.DOCS_TOOLTIP.hide_docs()
		)


func _on_tooltip() -> Variant:
	if _is_mouse_enter:
		if HenGlobal.DOCS_TOOLTIP.visible:
			HenGlobal.DOCS_TOOLTIP.position.x = self.global_position.x
			HenGlobal.DOCS_TOOLTIP.pivot_offset = Vector2(
				0,
				HenGlobal.DOCS_TOOLTIP.size.y
			)
			HenGlobal.DOCS_TOOLTIP.position.y = self.global_position.y - HenGlobal.DOCS_TOOLTIP.size.y
		else:
			if category == 'native':
				match raw_name:
					'print':
						return null
					'make_transition':
						HenGlobal.DOCS_TOOLTIP.set_custom_doc("Executes a transition to change the node current state. Use this functionality to shift from one active state to another", 'Make a Transition')
			else:
				match sub_type:
					SUB_TYPE.FUNC, HenCnode.SUB_TYPE.VOID:
						var first_input = get_node('%InputContainer').get_child(0)
						var current_class: String = first_input.connection_type

						if not HenEnums.VARIANT_TYPES.has(current_class):
							# getting where member is located in class reference
							while not ClassDB.class_has_method(current_class, get_cnode_name(), true):
								current_class = ClassDB.get_parent_class(current_class)

								# last class do verify
								if current_class == 'Object':
									break
						
						HenGlobal.DOCS_TOOLTIP.start_docs(current_class, get_cnode_name())
					TYPE.IF:
						HenGlobal.DOCS_TOOLTIP.set_custom_doc("Evaluates a condition and provides three possible outputs: the left output is triggered if the condition is true, the middle output is followed if no condition is met, and the right output is used if the condition is false", 'IF Condition')

			await get_tree().process_frame
			HenGlobal.DOCS_TOOLTIP.position.x = self.global_position.x
			HenGlobal.DOCS_TOOLTIP.pivot_offset = Vector2(
				0,
				HenGlobal.DOCS_TOOLTIP.size.y
			)

			HenGlobal.DOCS_TOOLTIP.position.y = self.global_position.y - HenGlobal.DOCS_TOOLTIP.size.y
			HenGlobal.DOCS_TOOLTIP.scale = Vector2.ZERO
			HenGlobal.DOCS_TOOLTIP.modulate = Color.TRANSPARENT
			HenGlobal.DOCS_TOOLTIP.visible = true

			var tween = create_tween().set_trans(Tween.TRANS_CUBIC)
			tween.set_parallel(true)
			tween.tween_property(HenGlobal.DOCS_TOOLTIP, 'scale', Vector2.ONE, .1)
			tween.tween_property(HenGlobal.DOCS_TOOLTIP, 'modulate', Color.WHITE, .3)
	
	return null


func _on_gui(_event: InputEvent) -> void:
	if _event is InputEventMouseButton:
		if _event.pressed:
			HenGlobal.DOCS_TOOLTIP.visible = false
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
						for i in get_tree().get_nodes_in_group(HenEnums.CNODE_SELECTED_GROUP):
							i.moving = true
					else:
						moving = true
						# cleaning other selects
						for i in get_tree().get_nodes_in_group(HenEnums.CNODE_SELECTED_GROUP):
							i.moving = false
							i.unselect()
						
						select()

						# generate gd_preview
						var code: String = parse_token_and_value()
						HenGlobal.GD_PREVIEWER.text = '# Hengo Code Preview\n# CNode -> ' + get_fantasy_name() + '\n' + code
		else:
			moving = false
			# group moving false
			for i in get_tree().get_nodes_in_group(HenEnums.CNODE_SELECTED_GROUP):
				i.moving = false


func _input(_event: InputEvent):
	if _event is InputEventMouseMotion:
		# moving on click
		if moving and not comment_ref:
			if HenGlobal.CAM:
				move(position + _event.relative / HenGlobal.CAM.transform.x.x)


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
	add_to_group(HenEnums.CNODE_SELECTED_GROUP)
	get_node('%SelectBorder').visible = true
	selected = true


func unselect() -> void:
	remove_from_group(HenEnums.CNODE_SELECTED_GROUP)
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

	HenGlobal.CNODE_CONTAINER.add_child(self)

	for input in in_container.get_children():
		input.show_connection(false)

	for output in out_container.get_children():
		output.show_connection(false)

	for line in from_lines:
		line.add_to_scene(false)

	for conn_key in flow_to.keys():
		for line in get_connector(conn_key).connections_lines:
			line.add_to_scene(false)


	if not (HenRouter.route_reference[route_ref.id] as Array).has(self):
		HenRouter.route_reference[route_ref.id].append(self)
	

	var groups: Array = HenGlobal.GROUP.get_group_list(self).filter(func(x): return x.begins_with('f_'))

	if not groups.is_empty():
		var group = groups[0]
		var id = int((group as String).split('f_')[1])
		var route_ref_node = HenRouteReference.get_route_ref_by_id_or_null(id)
	
		route_ref_node.change_ref_count()

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

		HenRouter.route_reference[route_ref.id].erase(self)
		HenGlobal.CNODE_CONTAINER.remove_child(self)
	

	var groups: Array = HenGlobal.GROUP.get_group_list(self).filter(func(x): return x.begins_with('f_'))

	if not groups.is_empty():
		var group = groups[0]
		var id = int((group as String).split('f_')[1])
		var route_ref_node = HenRouteReference.get_route_ref_by_id_or_null(id)
	
		route_ref_node.change_ref_count(-1)

	deleted = true


func add_input(_input: Dictionary) -> void:
	var in_container = get_node('%InputContainer')
	var input: HenCnodeInOut = HenAssets.CNodeInputScene.instantiate()

	if _input.has('ref'):
		input.is_ref = true

	if _input.has('category'):
		input.category = _input.category
 
		match _input.category:
			# make connector invisible
			# useful when input don't want a connection
			'state_transition', 'hengo_events', 'disabled':
				input.get_node('%CNameInput').get_child(0).visible = false

	if _input.has('sub_type'):
		input.sub_type = _input.sub_type

	if _input.has('data'):
		input.custom_data = _input.get('data')

	if _input.has('group'):
		HenGlobal.GROUP.add_to_group(_input.get('group'), input)


	input.set_type(_input.get('type') if _input.has('type') else 'Variant')
	input.get_node('%Name').text = _input.name
	input.root = self

	if _input.has('is_prop'):
		input.add_prop_ref(_input.get('in_prop'), int(_input.get('prop_idx')) if _input.has('prop_idx') else -1)
	else:
		input.set_in_prop(_input.get('in_prop') if _input.has('in_prop') else null)

	in_container.add_child(input)


func add_output(_output: Dictionary) -> void:
	var out_container = get_node('%OutputContainer')

	var output := HenAssets.CNodeOutputScene.instantiate()

	if _output.has('category'):
		output.category = _output.category

	if _output.has('sub_type'):
		output.sub_type = _output.sub_type

	if _output.has('data'):
		output.custom_data = _output.get('data')

	if _output.has('group_idx'):
		var idx = _output.get('group_idx')
		HenGlobal.GROUP.add_to_group('p' + str(idx), output)
		output.custom_data = idx

	if _output.has('group'):
		HenGlobal.GROUP.add_to_group(_output.get('group'), output)

	output.set_type(_output.get('type') if _output.has('type') else 'Variant')
	output.get_node('%Name').text = _output.name
	output.root = self

	output.set_out_prop(_output.sub_type if _output.has('sub_type') else '', _output.get('out_prop') if _output.has('out_prop') else null)
	out_container.add_child(output)

func check_error() -> void:
	var in_container = get_node('%InputContainer')
	var out_container = get_node('%OutputContainer')
	var errors: Array[Dictionary] = []

	match sub_type:
		HenCnode.SUB_TYPE.GO_TO_VOID:
			var input = in_container.get_child(1)

			# checking if other script has changed state name
			if not HenLoader.script_has_state(input.custom_data, input.get_in_prop_by_id_or_null().get_value()):
				errors.append({
					input_instance_id = input.get_instance_id(),
					msg = input.get_in_out_name() + ": the input type isn't derived from the current object; please set its value explicitly"
				})
		HenCnode.SUB_TYPE.CAST:
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
		HenGlobal.ERROR_BT.set_error_on_id(get_instance_id(), errors)
	else:
		disable_error()


func disable_error() -> void:
	get_node('%ErrorBorder').visible = false


func get_connection_lines_in_flow() -> Dictionary:
	match type:
		TYPE.IF:
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
	var input_container = get_node('%InputContainer')
	var lines: Array = []

	for input: HenCnodeInOut in input_container.get_children():
		lines += input.from_connection_lines

		if input.from_connection_lines.size() > 0:
			lines += input.from_connection_lines[0].from_cnode.get_input_connection_lines()
		
	return lines


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
static func instantiate_cnode(_config: Dictionary) -> HenCnode:
	var instance: HenCnode = HenAssets.CNodeScene.instantiate()

	if not _config.is_empty():
		instance.hash = HenGlobal.get_new_node_counter() if not _config.has('hash') else _config.hash
		instance.raw_name = _config.name
		instance.change_name(_config.get('fantasy_name') if _config.has('fantasy_name') else _config.name)

		var title_container = instance.get_node('%TitleContainer')

		if not _config.has('type'):
			if _config.has('sub_type'):
				match _config.sub_type as SUB_TYPE:
					SUB_TYPE.VAR, SUB_TYPE.LOCAL_VAR:
						_config.type = ''
					SUB_TYPE.DEBUG_VALUE:
						var debug_value_scene = load('res://addons/hengo/scenes/props/debug_value.tscn').instantiate()
						var container: VBoxContainer = instance.get_node('%Container')
						
						container.add_child(debug_value_scene)
						container.move_child(debug_value_scene, 1)

						title_container.get_node('%TitleIcon').texture = load('res://addons/hengo/assets/icons/cnode/debug.svg')
						# title_container.get('theme_override_styles/panel').set('bg_color', Color('#8a7346'))

						_config.type = TYPE.DEFAULT
					SUB_TYPE.FUNC, SUB_TYPE.USER_FUNC:
						# color
						# match _config.name:
							# 'make_transition':
								# title_container.get('theme_override_styles/panel').set('bg_color', Color('#000'))
							# _:
								# title_container.get('theme_override_styles/panel').set('bg_color', Color('#464A73'))
						
						title_container.get_node('%TitleIcon').texture = load('res://addons/hengo/assets/icons/cnode/func.svg')
						_config.type = TYPE.DEFAULT
					SUB_TYPE.VOID:
						title_container.get_node('%TitleIcon').texture = load('res://addons/hengo/assets/icons/cnode/void.svg')
						# title_container.get('theme_override_styles/panel').set('bg_color', EditorInterface.get_editor_settings().get_setting('interface/theme/base_color').darkened(.4))
						_config.type = TYPE.DEFAULT
					SUB_TYPE.SET_VAR, SUB_TYPE.SET_PROP, SUB_TYPE.GET_PROP:
						# color
						# title_container.get('theme_override_styles/panel').set('bg_color', Color('#4A7346'))
						title_container.get_node('%TitleIcon').texture = load('res://addons/hengo/assets/icons/cnode/set_var.svg')
						_config.type = TYPE.DEFAULT
					SUB_TYPE.VIRTUAL, SUB_TYPE.FUNC_INPUT:
						# color
						# title_container.get('theme_override_styles/panel').set('bg_color', Color('#734646'))
						title_container.get_node('%TitleIcon').texture = load('res://addons/hengo/assets/icons/cnode/virtual.svg')
						_config.type = TYPE.DEFAULT
					SUB_TYPE.CAST, SUB_TYPE.RAW_CODE:
						match _config.sub_type as SUB_TYPE:
							SUB_TYPE.RAW_CODE:
								title_container.get_node('%TitleIcon').texture = load('res://addons/hengo/assets/icons/cnode/raw.svg')
							SUB_TYPE.CAST:
								title_container.get_node('%TitleIcon').texture = load('res://addons/hengo/assets/icons/cnode/cast.svg')

						# title_container.get('theme_override_styles/panel').set('bg_color', Color('#000'))
						_config.type = TYPE.DEFAULT
					SUB_TYPE.SELF_GO_TO_VOID:
						title_container.get_node('%TitleIcon').texture = load('res://addons/hengo/assets/icons/cnode/go_to.svg')
						# title_container.get('theme_override_styles/panel').set('bg_color', Color('#000'))
						_config.type = TYPE.DEFAULT
					SUB_TYPE.FOR, SUB_TYPE.FOR_ARR:
						title_container.get_node('%TitleIcon').texture = load('res://addons/hengo/assets/icons/cnode/for.svg')
						# title_container.get('theme_override_styles/panel').set('bg_color', Color('#8c5c37'))
						_config.type = TYPE.DEFAULT
					_:
						_config.type = TYPE.DEFAULT

		instance.type = _config.type
		
		# hash of user function coming from group singleton
		var func_id: String = ''

		if _config.has('group'):
			HenGlobal.GROUP.add_to_group(_config.group, instance)
			
			if _config.group.begins_with('f_'):
				func_id = _config.group.split('f_')[1]

		# this tell hengo how to generate code
		if _config.has('category'):
			instance.category = _config.get('category')

		if _config.has('inputs'):
			var idx: int = 0

			for input_config in _config.get('inputs'):
				if not func_id.is_empty():
					# adding user function inputs group
					match _config.sub_type as SUB_TYPE:
						HenCnode.SUB_TYPE.FUNC_OUTPUT:
							input_config.group = 'fo_' + func_id + '_' + str(idx)
						_:
							input_config.group = 'fi_' + func_id + '_' + str(idx)
				
				instance.add_input(input_config)
				idx += 1

		if _config.has('outputs'):
			var idx: int = 0

			for output_config in _config.get('outputs'):
				if not func_id.is_empty():
					# adding user function ouputs group
					match _config.sub_type as SUB_TYPE:
						HenCnode.SUB_TYPE.FUNC_INPUT:
							output_config.group = 'fi_' + func_id + '_' + str(idx)
						_:
							output_config.group = 'fo_' + func_id + '_' + str(idx)
				
				instance.add_output(output_config)
				idx += 1

		# custom data
		if _config.has('data'):
			instance.data = _config.data
		

		# instance flow connections
		match _config.type as TYPE:
			TYPE.DEFAULT:
				var default_flow := HenAssets.CNodeFlowScene.instantiate()
				var connector = default_flow.get_child(0)
				connector.root = instance
				instance.get_node('%Container').add_child(default_flow)
				instance.connectors.cnode = connector
			TYPE.IF:
				var if_flow := HenAssets.CNodeIfFlowScene.instantiate()
				for i in if_flow.get_node('%FlowContainer').get_children():
					i.root = instance
					instance.connectors[i.type] = i
				
				# var input = HenAssets.CNodeInputScene.instantiate()
				# var container = title_container.get_child(0)
				# container.add_child(input)
				# container.move_child(input, 0)
				# container.process_mode = Node.PROCESS_MODE_INHERIT
				# input.root = instance
				# input.set_type('bool')
				instance.get_node('%Container').add_child(if_flow)

				# color
				title_container.get('theme_override_styles/panel').set('bg_color', Color('#674883'))
				title_container.get_node('%TitleIcon').visible = false
				(title_container.get_node('%Title') as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

			TYPE.IMG:
				var center_img = HenAssets.CNodeCenterImage.instantiate()
				var img = center_img.get_node('%Img')
				var center_container = instance.get_node('%CenterContainer')

				img.texture = load('res://addons/hengo/assets/icons/' + _config.category + '.svg')

				center_container.set('theme_override_constants/separation', 5)
				center_container.add_child(center_img)
				center_container.move_child(center_img, 1)

				instance.get_node('%OutputContainer').alignment = BoxContainer.ALIGNMENT_CENTER
				title_container.visible = false
			TYPE.EXPRESSION:
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
			var _sub_type = _config.get('sub_type')
			instance.sub_type = _sub_type

			match _sub_type as SUB_TYPE:
				# adding virtual cnodes references
				HenCnode.SUB_TYPE.VIRTUAL:
					match _config.route.type as HenRouter.ROUTE_TYPE:
						HenRouter.ROUTE_TYPE.STATE:
							var ref = _config.route.state_ref
							ref.virtual_cnode_list.append(instance)
						HenRouter.ROUTE_TYPE.INPUT:
							var ref = _config.route.general_ref
							ref.virtual_cnode_list.append(instance)
				# virtual node of signal and func
				HenCnode.SUB_TYPE.FUNC_INPUT:
					var ref = _config.route.item_ref
					ref.virtual_cnode_list.append(instance)
				HenCnode.SUB_TYPE.FUNC_OUTPUT:
					_config.route.item_ref.output_cnode = instance
				HenCnode.SUB_TYPE.VAR, HenCnode.SUB_TYPE.LOCAL_VAR:
					instance.get_node('%TitleContainer').visible = false
				HenCnode.SUB_TYPE.CONST:
					title_container.get_node('%TitleIcon').texture = load('res://addons/hengo/assets/icons/cnode/enum.svg')
					title_container.get('theme_override_styles/panel').set('bg_color', Color('#2f6063'))
				HenCnode.SUB_TYPE.SINGLETON:
					title_container.get_node('%TitleIcon').texture = load('res://addons/hengo/assets/icons/cnode/singleton.svg')
					title_container.get('theme_override_styles/panel').set('bg_color', Color('#691818'))

		HenRouter.route_reference[_config.route.id].append(instance)

	
	instance.route_ref = _config.route

	if _config.has('pos'):
		instance.position = str_to_var(_config.pos)
	elif _config.has('position'):
		instance.position = _config.position
	else:
		instance.position = Vector2.ZERO

	instance.size = Vector2.ZERO

	
	# # adding virtual cnode to list
	# var v_cnode: HenVirtualCNode = HenVirtualCNode.new()

	# v_cnode.name = instance.get_cnode_name()
	# v_cnode.id = instance.hash
	# v_cnode.position = instance.position

	# if not HenGlobal.vc_list.has(_config.route.id):
	# 	HenGlobal.vc_list[_config.route.id] = []
	
	# HenGlobal.vc_list[_config.route.id].append(v_cnode)
	# # ---- end virtual ---

	return instance


static func instantiate_and_add(_config: Dictionary) -> HenCnode:
	var cnode := instantiate_cnode(_config)
	cnode.add_to_scene()

	if _config.has('position'):
		cnode.position = _config.get('position')

	return cnode


static func instantiate_and_add_pool() -> void:
	for i in range(10): # pool size
		var instance: HenCnode = HenAssets.CNodeScene.instantiate()
		instance.position = Vector2(50000, 50000)
		instance.is_pool = true
		instance.visible = false
		HenGlobal.cnode_pool.append(instance)
		HenGlobal.CNODE_CONTAINER.add_child(instance)


func get_input_token_list(_get_name: bool = false) -> Array:
	var input_container = get_node('%InputContainer')
	var inputs = []

	for input in input_container.get_children():
		inputs.append(input.get_token(_get_name))
	
	return inputs


# getting cnode outputs
func get_output_token_list() -> Array:
	var outputs = []

	for output: HenCnodeInOut in get_node('%OutputContainer').get_children():
		outputs.append({
			name = output.get_node('%Name').text,
			type = output.connection_type
		})
	
	return outputs


func get_token(_id: int = 0) -> Dictionary:
	var use_self: bool = route_ref.type != HenRouter.ROUTE_TYPE.STATE

	var token: Dictionary = {
		type = sub_type,
		use_self = use_self,
	}

	if category:
		token.category = category

	match sub_type:
		HenCnode.SUB_TYPE.VOID, HenCnode.SUB_TYPE.GO_TO_VOID, HenCnode.SUB_TYPE.SELF_GO_TO_VOID:
			token.merge({
				name = get_cnode_name().to_snake_case(),
				params = get_input_token_list()
			})
		HenCnode.SUB_TYPE.FUNC, HenCnode.SUB_TYPE.USER_FUNC:
			token.merge({
				name = get_cnode_name().to_snake_case(),
				params = get_input_token_list(),
				id = _id if get_node('%OutputContainer').get_child_count() > 1 else -1,
			})
		HenCnode.SUB_TYPE.VAR, HenCnode.SUB_TYPE.LOCAL_VAR:
			token.merge({
				name = get_node('%OutputContainer').get_child(0).get_in_out_name().to_snake_case(),
			})
		HenCnode.SUB_TYPE.DEBUG_VALUE:
			token.merge({
				value = get_input_token_list()[0],
				# id = HenCodeGeneration.get_debug_counter(_node)
			})
		HenCnode.SUB_TYPE.SET_VAR, HenCnode.SUB_TYPE.SET_LOCAL_VAR:
			token.merge({
				name = get_node('%InputContainer').get_child(0).get_in_out_name().to_snake_case(),
				value = get_input_token_list()[0],
			})
		HenCnode.SUB_TYPE.VIRTUAL, HenCnode.SUB_TYPE.FUNC_INPUT:
			token.merge({
				param = get_node('%OutputContainer').get_child(_id).get_node('%Name').text,
				id = _id
			})
		HenCnode.SUB_TYPE.FOR, HenCnode.SUB_TYPE.FOR_ARR:
			return {
				type = HenCnode.SUB_TYPE.FOR_ITEM,
				hash = get_instance_id()
			}
		HenCnode.SUB_TYPE.CAST:
			return {
				type = sub_type,
				to = get_node('%OutputContainer').get_child(0).connection_type,
				from = (get_node('%InputContainer').get_child(0) as HenCnodeInOut).get_token()
			}
		HenCnode.SUB_TYPE.IMG:
			token.merge({
				name = (get_node('%Title').text as String).to_snake_case(),
				params = get_input_token_list()
			})
		HenCnode.SUB_TYPE.RAW_CODE:
			token.merge({
				code = get_input_token_list()[0],
			})
		HenCnode.SUB_TYPE.CONST:
			token.merge({
				name = get_cnode_name(),
				value = get_node('%OutputContainer').get_child(0).get_node('%CNameOutput').get_child(0).get_value()
			})
		HenCnode.SUB_TYPE.SINGLETON:
			token.merge({
				name = get_cnode_name(),
				params = get_input_token_list(),
				id = _id if get_node('%OutputContainer').get_child_count() > 1 else -1,
			})
		HenCnode.SUB_TYPE.GET_PROP:
			token.merge({
				from = get_input_token_list(),
				name = get_node('%OutputContainer').get_child(0).get_in_out_name() if _id <= 0 else get_node('%OutputContainer').get_child(0).get_in_out_name() + '.' + get_node('%OutputContainer').get_child(_id).get_in_out_name(),
			})
		HenCnode.SUB_TYPE.SET_PROP:
			token.merge({
				params = get_input_token_list(true),
				name = get_node('%InputContainer').get_child(1).get_in_out_name()
			})
		HenCnode.SUB_TYPE.EXPRESSION:
			print(get_node('%Container').get_child(1).get_child(0))
			token.merge({
				params = get_input_token_list(true),
				exp = get_node('%Container').get_child(1).get_child(0).raw_text
			})

	return token


func get_flow_token_list(_token_list: Array = []) -> Array:
	# if cnode is deleted
	if deleted:
		return _token_list

	match sub_type:
		HenCnode.SUB_TYPE.IF:
			_token_list.append(get_if_token())
		HenCnode.SUB_TYPE.FOR, HenCnode.SUB_TYPE.FOR_ARR:
			_token_list.append(get_for_token())
		_:
			_token_list.append(get_token())

			if not flow_to.is_empty():
				flow_to.cnode.get_flow_token_list(_token_list)

	return _token_list


func get_if_token() -> Dictionary:
	var true_flow: Array = []
	var false_flow: Array = []

	if flow_to.has('true_flow'):
		true_flow = flow_to.true_flow.get_flow_token_list()
		# debug
		true_flow.append(HenCodeGeneration.get_debug_token(self, 'true_flow'))
		
	if flow_to.has('false_flow'):
		false_flow = flow_to.false_flow.get_flow_token_list()
		false_flow.append(HenCodeGeneration.get_debug_token(self, 'false_flow'))

	return {
		type = HenCnode.SUB_TYPE.IF,
		true_flow = true_flow,
		false_flow = false_flow,
		condition = (get_node('%InputContainer').get_child(0) as HenCnodeInOut).get_token()
	}


func get_for_token() -> Dictionary:
	return {
		type = sub_type,
		hash = get_instance_id(),
		params = get_input_token_list(),
		flow = flow_to.cnode.get_flow_token_list() if flow_to.has('cnode') else []
	}


func parse_token_and_value(_id: int = 0) -> String:
	var code: String

	match sub_type:
		HenCnode.SUB_TYPE.IF:
			code = HenCodeGeneration.parse_token_by_type(
				get_if_token()
			)
		HenCnode.SUB_TYPE.FOR, HenCnode.SUB_TYPE.FOR_ARR:
			code = HenCodeGeneration.parse_token_by_type(
				get_for_token()
			)
		HenCnode.SUB_TYPE.VIRTUAL:
			code = '# virtual cnode'
		_:
			code = HenCodeGeneration.parse_token_by_type(
				get_token(_id)
			)

	return '\n'.join((code.split('\n') as Array).filter(func(x): return not x.contains(HenGlobal.DEBUG_TOKEN))) # removes debug lines