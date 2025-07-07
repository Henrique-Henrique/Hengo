@tool
class_name HenCnode extends PanelContainer

var flow_to: Dictionary = {}
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
var virtual_ref: HenVirtualCNode


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
	# if virtual_ref:
	# 	print(JSON.stringify(virtual_ref.get_save()))
	_is_mouse_enter = true


	if HenGlobal.can_make_flow_connection and not virtual_ref.from_flow_connections.is_empty():
		HenGlobal.flow_connection_to_data = {
			to_cnode = self,
			to_id = virtual_ref.from_flow_connections[0].id
		}
	
	# animations
	if not selected: hover_animation()


func _on_exit() -> void:
	_is_mouse_enter = false
	HenGlobal.flow_connection_to_data = {}
	if not selected: exit_animation()
	HenGlobal.TOOLTIP.close()


func hover_animation() -> void:
	var tween: Tween = get_tree().create_tween()

	tween.tween_property(%Border, 'modulate', Color(1, 1, 1, .7), .03)
	tween.parallel().tween_method(_scale_and_update_line, scale, Vector2(1.03, 1.03), .03).set_delay(0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)

func exit_animation() -> void:
	var tween: Tween = get_tree().create_tween()

	tween.tween_property(%Border, 'modulate', Color.TRANSPARENT, .03)
	tween.parallel().tween_method(_scale_and_update_line, scale, Vector2.ONE, .03).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)


func _scale_and_update_line(_scale: Vector2) -> void:
	scale = _scale

	if virtual_ref:
		for from_connection: HenVirtualCNode.FromFlowConnection in virtual_ref.from_flow_connections:
			for connetion: HenVirtualCNode.FlowConnectionData in from_connection.from_connections:
				if connetion.line_ref:
					connetion.line_ref.update_line()
				
		for connetion: HenVirtualCNode.FlowConnectionData in virtual_ref.flow_connections:
				if connetion.line_ref:
					connetion.line_ref.update_line()

func _on_gui(_event: InputEvent) -> void:
	if _event is InputEventMouseButton:
		if _event.pressed:
			HenGlobal.DOCS_TOOLTIP.visible = false
			if _event.ctrl_pressed:
				if selected:
					unselect()
				else:
					select()
			elif _event.double_click:
				if virtual_ref:
					if not virtual_ref.route.is_empty():
						HenRouter.change_route(virtual_ref.route)
					elif virtual_ref.ref and virtual_ref.ref.get('route'):
						HenRouter.change_route(virtual_ref.ref.get('route'))
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
				elif _event.button_index == MOUSE_BUTTON_RIGHT:
					# showing state config on doubleclick
					if virtual_ref:
						if virtual_ref.type == HenVirtualCNode.Type.STATE:
							var state_inspector: HenInspector = HenInspector.start([
									HenInspector.InspectorItem.new({
										name = 'name',
										type = &'String',
										value = virtual_ref.name,
										ref = virtual_ref
									}),
									HenInspector.InspectorItem.new({
										name = 'outputs',
										type = &'Array',
										max_size = 5,
										value = virtual_ref.flow_connections,
										item_creation_callback = virtual_ref.create_flow_connection,
										item_delete_callback = virtual_ref._on_delete_flow_state,
										field = {name = 'name', type = 'String'}
									}),
								])
							
							state_inspector.item_changed.connect(_on_state_inspector)

							HenGlobal.GENERAL_POPUP.get_parent().show_content(
								state_inspector,
								'State Config',
								get_global_mouse_position()
							)
					
		else:
			moving = false
			# group moving false
			for i in get_tree().get_nodes_in_group(HenEnums.CNODE_SELECTED_GROUP):
				i.moving = false
	elif _event is InputEventMouseMotion and _is_mouse_enter:
		if virtual_ref.invalid:
			HenGlobal.TOOLTIP.go_to(get_global_mouse_position(), HenEnums.TOOLTIP_TEXT.CNODE_INVALID)
		else:
			match virtual_ref.type:
				HenVirtualCNode.Type.STATE:
					HenGlobal.TOOLTIP.go_to(get_global_mouse_position(), HenEnums.TOOLTIP_TEXT.RIGHT_MOUSE_INSPECT)
				_:
					HenGlobal.TOOLTIP.close()


func _on_state_inspector(_name: String, _value: Variant, _ref: Object) -> void:
	if virtual_ref: virtual_ref.update()


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

	if virtual_ref:
		virtual_ref.position = position

	emit_signal('on_move')


func select() -> void:
	selected = true
	hover_animation()
	add_to_group(HenEnums.CNODE_SELECTED_GROUP)

	if virtual_ref:
		var script_data: HenScriptData = HenSaver.generate_script_data()
		var code: String = HenCodeGeneration.get_code(script_data, true)
		
		HenGlobal.CODE_PREVIEWER.set_code(code)
		HenGlobal.CODE_PREVIEWER.show_vc_line_reference()


func unselect() -> void:
	selected = false
	exit_animation()
	remove_from_group(HenEnums.CNODE_SELECTED_GROUP)

func change_name(_name: String) -> void:
	get_node('%Title').text = _name


func change_name_and_raw(_name: String) -> void:
	get_node('%Title').text = _name
	raw_name = _name


func get_cnode_name() -> String:
	return raw_name

func get_fantasy_name() -> String:
	return get_node('%Title').text


func add_input(__input: Dictionary, _instantiate_prop: bool = true) -> HenCnodeInOut:
	var in_container = get_node('%InputContainer')
	var input: HenCnodeInOut = HenAssets.CNodeInputScene.instantiate()

	input.set_type(__input.get('type') if __input.has('type') else 'Variant')
	(input.get_node('%Name') as Label).text = __input.name
	input.root = self

	in_container.add_child(input)

	return input


func add_output(_output: Dictionary) -> void:
	var out_container = get_node('%OutputContainer')
	var output: HenCnodeInOut = HenAssets.CNodeOutputScene.instantiate()

	output.set_type(_output.get('type') if _output.has('type') else 'Variant')
	(output.get_node('%Name') as Label).text = _output.name
	output.root = self

	out_container.add_child(output)


func disable_error() -> void:
	get_node('%ErrorBorder').visible = false


func get_connection_lines_in_flow() -> Dictionary:
	return {}


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

static func instantiate_and_add_pool() -> void:
	HenGlobal.can_instantiate_pool = true

	for loop_idx in range(3):
		if not HenGlobal.can_instantiate_pool:
			return
		
		var start: float = Time.get_ticks_usec()

		for vc_idx in range(30): # pool size
			var instance: HenCnode = HenAssets.CNodeScene.instantiate()

			for input_idx in range(5): # input pool size
				instance.add_input({name = "", type = "Variant"}, false)

			for output_idx in range(5): # output pool size
				instance.add_output({name = "", type = "Variant"})
			
			instance.position = Vector2(50000, 50000)
			instance.is_pool = true
			instance.visible = false
			# instance.set_flow_connection(TYPE.DEFAULT)

			if not HenGlobal.can_instantiate_pool:
				return
			
			HenGlobal.cnode_pool.append(instance)
			HenGlobal.CNODE_CONTAINER.add_child(instance)

			await RenderingServer.frame_post_draw
			

		for connection_line_idx in range(30): # connection line pool size
			var line: HenConnectionLine = HenAssets.ConnectionLineScene.instantiate()
			line.visible = false
			line.position = Vector2(50000, 50000)
			HenGlobal.connection_line_pool.append(line)
			HenGlobal.CAM.get_node('Lines').add_child(line)
		

		for flow_connection_line_idx in range(30): # flow connection line pool size
			var line: HenFlowConnectionLine = HenAssets.FlowConnectionLineScene.instantiate()
			line.visible = false
			line.position = Vector2(50000, 50000)
			HenGlobal.flow_connection_line_pool.append(line)
			HenGlobal.CAM.get_node('Lines').add_child(line)


		var end: float = Time.get_ticks_usec()
		print('time => ', (end - start) / 1000., 'ms')

		await HenGlobal.CNODE_CONTAINER.get_tree().create_timer(1).timeout