@tool
class_name HenCnode extends PanelContainer

const CNODE_INPUT = preload('res://addons/hengo/scenes/cnode_input.tscn')
const CNODE_OUTPUT = preload('res://addons/hengo/scenes/cnode_output.tscn')
const CNODE = preload('res://addons/hengo/scenes/cnode.tscn')
const CONNECTION_LINE = preload('res://addons/hengo/scenes/connection_line.tscn')
const FLOW_CONNECTION_LINE = preload('res://addons/hengo/scenes/flow_connection_line.tscn')

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
var can_follow: bool = false
var follow_position: Vector2 = Vector2.ZERO

signal on_hovering(_mouse_pos: Vector2)
signal on_double_click
signal on_mouse_enter
signal on_move
signal on_right_click
signal changed_position(_pos: Vector2)
signal request_flow_connection
signal on_select
signal on_unselect


func _ready():
	var title_container := get_node('%TitleContainer') as PanelContainer

	title_container.gui_input.connect(_on_gui)
	title_container.mouse_entered.connect(_on_enter)
	title_container.mouse_exited.connect(_on_exit)
	gui_input.connect(_on_gui)

# private
#

func follow(_position: Vector2) -> void:
	if position.is_equal_approx(_position):
		can_follow = false
		set_process(false)
		return
	
	set_process(true)
	can_follow = true
	follow_position = _position


func _on_enter() -> void:
	_is_mouse_enter = true
	on_mouse_enter.emit()

	# animations
	if not selected: hover_animation()


func _on_exit() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	_is_mouse_enter = false
	global.flow_connection_to_data.clear()
	if not selected: exit_animation()
	global.TOOLTIP.close()


func hover_animation() -> void:
	var tween: Tween = get_tree().create_tween()

	tween.tween_property(%Border, 'modulate', Color(1, 1, 1, .7), .2)


func exit_animation(_time: float = .2) -> void:
	var tween: Tween = get_tree().create_tween()

	tween.tween_property(%Border, 'modulate', Color.TRANSPARENT, _time)


func _on_gui(_event: InputEvent) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if _event is InputEventMouseButton:
		var e: InputEventMouseButton = _event
		if e.pressed:
			global.DOCS_TOOLTIP.visible = false
			if e.ctrl_pressed:
				if selected:
					on_unselect.emit()
				else:
					on_select.emit()
			elif e.double_click:
				on_double_click.emit()
			else:
				if e.button_index == MOUSE_BUTTON_LEFT:
					print(44)

					if selected:
						for vc: HenVirtualCNode in global.SELECTED_VIRTUAL_CNODE:
							vc.set_cnode_moving(true)
					else:
						# cleaning other selects
						for vc: HenVirtualCNode in global.SELECTED_VIRTUAL_CNODE:
							vc.set_cnode_moving(false)
							vc.unselect()
						
						moving = true
						on_select.emit()
				elif e.button_index == MOUSE_BUTTON_RIGHT:
					on_right_click.emit(get_global_mouse_position())
					
		else:
			moving = false
			HenVCActionButtons.get_singleton().show_action(self)

			# group moving false
			for vc: HenVirtualCNode in global.SELECTED_VIRTUAL_CNODE:
				vc.set_cnode_moving(false)
			
	elif _event is InputEventMouseMotion and _is_mouse_enter:
		on_hovering.emit(get_global_mouse_position())


func _input(_event: InputEvent):
	if _event is InputEventMouseMotion:
		var global: HenGlobal = Engine.get_singleton(&'Global')
		# moving on click
		if moving and global.CAM:
			move(position + _event.relative / global.CAM.transform.x.x)


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


func move_simple(_pos: Vector2) -> void:
	position = _pos
	emit_signal('on_move')


func select() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	selected = true
	hover_animation()

	if global.CODE_PREVIEWER.visible:
		var new_id_list: Array = global.SELECTED_VIRTUAL_CNODE.map(func(x: HenVirtualCNode): return x.identity.id)
		if not (global.CODE_PREVIEWER.id_list.is_empty() and new_id_list.is_empty()) and (global.CODE_PREVIEWER.id_list == new_id_list):
			return

		var script_data: HenScriptData = HenSaver.generate_script_data()
		var code: String = (Engine.get_singleton(&'CodeGeneration') as HenCodeGeneration).get_code(script_data, true)
		global.CODE_PREVIEWER.set_code(code)
		global.CODE_PREVIEWER.show_vc_line_reference()


func unselect(_time: float = .2) -> void:
	selected = false
	exit_animation(_time)


func change_name(_name: String) -> void:
	get_node('%Title').text = _name


func get_fantasy_name() -> String:
	return get_node('%Title').text


func add_input(__input: Dictionary, _instantiate_prop: bool = true) -> HenCnodeInOut:
	var in_container = get_node('%InputContainer')
	var input: HenCnodeInOut = CNODE_INPUT.instantiate()

	input.set_type(__input.get('type') if __input.has('type') else 'Variant')
	(input.get_node('%Name') as Label).text = __input.name
	input.root = self

	in_container.add_child(input)

	return input


func add_output(_output: Dictionary) -> void:
	var out_container = get_node('%OutputContainer')
	var output: HenCnodeInOut = CNODE_OUTPUT.instantiate()

	output.set_type(_output.get('type') if _output.has('type') else 'Variant')
	(output.get_node('%Name') as Label).text = _output.name
	output.root = self

	out_container.add_child(output)


func disable_error() -> void:
	get_node('%ErrorBorder').visible = false


func get_border() -> Panel:
	return get_node('%Border')


func reset_signals(_vc: HenVirtualCNode = null):
	for signal_name: StringName in [
		'on_hovering',
		'on_double_click',
		'on_right_click',
		'changed_position',
		'on_mouse_enter',
		'request_flow_connection',
		'on_select',
		'on_unselect'
	]:
		for connection: Dictionary in get_signal_connection_list(signal_name):
			@warning_ignore('unsafe_method_access')
			connection.signal.disconnect(connection.callable)

	if _vc:
		on_hovering.connect(_vc.on_cnode_hovering)
		on_double_click.connect(_vc.on_cnode_double_click)
		on_right_click.connect(_vc.on_cnode_right_click)
		changed_position.connect(_vc.on_cnode_changed_position)
		on_mouse_enter.connect(_vc.on_cnode_mouse_enter)
		request_flow_connection.connect(_vc.request_flow_connector_connection)
		on_select.connect(_vc.select)
		on_unselect.connect(_vc.unselect)


func request_flow_connetor_connection(_id: int, _mouse_pos: Vector2) -> void:
	request_flow_connection.emit(_id, _mouse_pos)


static func instantiate_and_add_pool() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	global.can_instantiate_pool = true

	for loop_idx in range(3):
		if not global or global.is_queued_for_deletion() or not global.is_inside_tree():
			return

		if not global.can_instantiate_pool:
			return
		
		var start: float = Time.get_ticks_usec()

		for vc_idx in range(30): # pool size
			var instance: HenCnode = CNODE.instantiate()

			for input_idx in range(5): # input pool size
				instance.add_input({name = "", type = "Variant"}, false)

			for output_idx in range(5): # output pool size
				instance.add_output({name = "", type = "Variant"})
			
			instance.position = Vector2(50000, 50000)
			instance.is_pool = true
			instance.visible = false

			if not global or global.is_queued_for_deletion() or not global.is_inside_tree():
				return

			if not global.can_instantiate_pool:
				return
			
			global.cnode_pool.append(instance)
			global.CNODE_CONTAINER.add_child(instance)

			await RenderingServer.frame_post_draw
			

		for connection_line_idx in range(30): # connection line pool size
			if not global or global.is_queued_for_deletion() or not global.is_inside_tree():
				return

			if not global.can_instantiate_pool:
				return
			
			var line: HenConnectionLine = CONNECTION_LINE.instantiate()
			line.visible = false
			line.position = Vector2(50000, 50000)
			global.connection_line_pool.append(line)
			global.CAM.get_node('Lines').add_child(line)
		

		for flow_connection_line_idx in range(30): # flow connection line pool size
			if not global or global.is_queued_for_deletion() or not global.is_inside_tree():
				return

			if not global.can_instantiate_pool:
				return
			
			var line: HenFlowConnectionLine = FLOW_CONNECTION_LINE.instantiate()
			line.visible = false
			line.position = Vector2(50000, 50000)
			global.flow_connection_line_pool.append(line)
			global.CAM.get_node('Lines').add_child(line)


		var end: float = Time.get_ticks_usec()
		print('time => ', (end - start) / 1000., 'ms')

		await global.CNODE_CONTAINER.get_tree().create_timer(1).timeout


func _physics_process(_delta: float) -> void:
	if can_follow:
		position = position.lerp(follow_position, _delta * 48)
		on_move.emit()
		if position.is_equal_approx(follow_position):
			can_follow = false
			set_process(false)