@tool
class_name HenCnode extends PanelContainer

var flow_to: Dictionary = {}
var data: Dictionary = {}
var category: String
var id: int

# behavior
var moving: bool = false
var selected: bool = false

# only on state signal
var old_state_event_connected: PanelContainer

# tooltip
var _is_mouse_enter: bool = false

# formatter
var can_move_to_format: bool = true

# pool
var is_pool: bool = false


signal on_hovering(_mouse_pos: Vector2)
signal on_double_click
signal on_mouse_enter
signal on_move
signal on_right_click
signal changed_position(_pos: Vector2)


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
	on_mouse_enter.emit()

	# animations
	if not selected: hover_animation()


func _on_exit() -> void:
	_is_mouse_enter = false
	HenGlobal.flow_connection_to_data = {}
	if not selected: exit_animation()
	HenGlobal.TOOLTIP.close()


func hover_animation() -> void:
	var tween: Tween = get_tree().create_tween()

	tween.tween_property(%Border, 'modulate', Color(1, 1, 1, .7), .2)


func exit_animation() -> void:
	var tween: Tween = get_tree().create_tween()

	tween.tween_property(%Border, 'modulate', Color.TRANSPARENT, .2)


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
				on_double_click.emit()
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
					on_right_click.emit(get_global_mouse_position())
					
		else:
			moving = false
			HenVCActionButtons.get_singleton().show_action(self)

			# group moving false
			for i in get_tree().get_nodes_in_group(HenEnums.CNODE_SELECTED_GROUP):
				i.moving = false
			
	elif _event is InputEventMouseMotion and _is_mouse_enter:
		on_hovering.emit(get_global_mouse_position())


func _input(_event: InputEvent):
	if _event is InputEventMouseMotion:
		# moving on click
		if moving:
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
	changed_position.emit(position)
	HenVCActionButtons.get_singleton().hide_action()
	emit_signal('on_move')


func select() -> void:
	selected = true
	hover_animation()
	add_to_group(HenEnums.CNODE_SELECTED_GROUP)
	
	if HenGlobal.CODE_PREVIEWER.visible:
		var new_id_list: Array = get_tree().get_nodes_in_group(HenEnums.CNODE_SELECTED_GROUP).map(func(x: HenCnode): return x.id)

		if not (HenGlobal.CODE_PREVIEWER.id_list.is_empty() and new_id_list.is_empty()) and (HenGlobal.CODE_PREVIEWER.id_list == new_id_list):
			return

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


func get_border() -> Panel:
	return get_node('%Border')


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