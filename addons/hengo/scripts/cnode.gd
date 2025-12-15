@tool
class_name HenCnode extends PanelContainer

const CNODE_INPUT = preload('res://addons/hengo/scenes/cnode_input.tscn')
const CNODE_OUTPUT = preload('res://addons/hengo/scenes/cnode_output.tscn')
const CNODE = preload('res://addons/hengo/scenes/cnode.tscn')
const CONNECTION_LINE = preload('res://addons/hengo/scenes/connection_line.tscn')
const FLOW_CONNECTION_LINE = preload('res://addons/hengo/scenes/flow_connection_line.tscn')

const ICON_FUNCTION = preload("res://addons/hengo/assets/new_icons/square-function.svg")
const ICON_VARIABLE = preload("res://addons/hengo/assets/new_icons/variable.svg")
const ICON_IF = preload("res://addons/hengo/assets/new_icons/git-branch.svg")
const ICON_LOOP = preload("res://addons/hengo/assets/new_icons/repeat.svg")
const ICON_STATE = preload("res://addons/hengo/assets/new_icons/activity.svg")
const ICON_SIGNAL = preload("res://addons/hengo/assets/new_icons/signal.svg")
const ICON_DEBUG = preload("res://addons/hengo/assets/new_icons/bug.svg")
const ICON_VOID = preload("res://addons/hengo/assets/new_icons/circle-slash.svg")
const ICON_INVALID = preload("res://addons/hengo/assets/new_icons/triangle.svg")
const ICON_CODE = preload("res://addons/hengo/assets/new_icons/code.svg")
const ICON_IMAGE = preload("res://addons/hengo/assets/new_icons/image.svg")
const ICON_CALCULATOR = preload("res://addons/hengo/assets/new_icons/calculator.svg")
const ICON_LINK_OFF = preload("res://addons/hengo/assets/new_icons/link-2-off.svg")
const ICON_INPUT = preload("res://addons/hengo/assets/new_icons/file-input.svg")
const ICON_OUTPUT = preload("res://addons/hengo/assets/new_icons/file-output.svg")
const ICON_BOX = preload("res://addons/hengo/assets/new_icons/box.svg")
const ICON_LAYERS = preload("res://addons/hengo/assets/new_icons/layers.svg")
const ICON_PLAY = preload("res://addons/hengo/assets/new_icons/play.svg")

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

	# if global.CODE_PREVIEWER.visible:
	# 	var new_id_list: Array = global.SELECTED_VIRTUAL_CNODE.map(func(x: HenVirtualCNode): return x.identity.id)
	# 	if not (global.CODE_PREVIEWER.id_list.is_empty() and new_id_list.is_empty()) and (global.CODE_PREVIEWER.id_list == new_id_list):
	# 		return

		# var script_data: HenScriptData = HenSaver.generate_script_data()
		# var code: String = (Engine.get_singleton(&'CodeGeneration') as HenCodeGeneration).get_code(script_data, true)
		# global.CODE_PREVIEWER.set_code(code)
		# global.CODE_PREVIEWER.show_vc_line_reference()


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


func update_title_color(_sub_type: int) -> void:
	var title_color: TextureRect = get_node('%TitleColor')
	var title_icon: TextureRect = get_node('%TitleIcon')
	title_color.modulate = Color('#343434')

	match _sub_type:
		HenVirtualCNode.SubType.FUNC, \
		HenVirtualCNode.SubType.USER_FUNC, \
		HenVirtualCNode.SubType.FUNC_FROM, \
		HenVirtualCNode.SubType.MACRO:
			title_color.modulate = Color("#54a0ff")
			title_icon.texture = ICON_FUNCTION

		HenVirtualCNode.SubType.VIRTUAL, \
		HenVirtualCNode.SubType.OVERRIDE_VIRTUAL:
			title_color.modulate = Color("#ff9ff3")
			title_icon.texture = ICON_LAYERS

		HenVirtualCNode.SubType.FUNC_INPUT, \
		HenVirtualCNode.SubType.MACRO_INPUT:
			title_color.modulate = Color("#ff9ff3")
			title_icon.texture = ICON_INPUT

		HenVirtualCNode.SubType.FUNC_OUTPUT, \
		HenVirtualCNode.SubType.MACRO_OUTPUT:
			title_color.modulate = Color("#ff9ff3")
			title_icon.texture = ICON_OUTPUT

		HenVirtualCNode.SubType.VAR, \
		HenVirtualCNode.SubType.LOCAL_VAR, \
		HenVirtualCNode.SubType.SET_VAR, \
		HenVirtualCNode.SubType.SET_LOCAL_VAR, \
		HenVirtualCNode.SubType.VAR_FROM, \
		HenVirtualCNode.SubType.SET_VAR_FROM, \
		HenVirtualCNode.SubType.CONST, \
		HenVirtualCNode.SubType.GET_FROM_PROP, \
		HenVirtualCNode.SubType.IN_PROP:
			title_color.modulate = Color("#1dd1a1")
			title_icon.texture = ICON_VARIABLE

		HenVirtualCNode.SubType.IF:
			title_color.modulate = Color("#ff6b6b")
			title_icon.texture = ICON_IF

		HenVirtualCNode.SubType.FOR, \
		HenVirtualCNode.SubType.FOR_ARR, \
		HenVirtualCNode.SubType.FOR_ITEM:
			title_color.modulate = Color("#ff6b6b")
			title_icon.texture = ICON_LOOP

		HenVirtualCNode.SubType.BREAK, \
		HenVirtualCNode.SubType.CONTINUE, \
		HenVirtualCNode.SubType.PASS, \
		HenVirtualCNode.SubType.GO_TO_VOID, \
		HenVirtualCNode.SubType.SELF_GO_TO_VOID:
			title_color.modulate = Color("#ff6b6b")
			title_icon.texture = ICON_PLAY

		HenVirtualCNode.SubType.STATE, \
		HenVirtualCNode.SubType.STATE_START, \
		HenVirtualCNode.SubType.STATE_EVENT:
			title_color.modulate = Color("#a29bfe")
			title_icon.texture = ICON_STATE

		HenVirtualCNode.SubType.SIGNAL_ENTER, \
		HenVirtualCNode.SubType.SIGNAL_CONNECTION, \
		HenVirtualCNode.SubType.SIGNAL_DISCONNECTION:
			title_color.modulate = Color("#ff6b6b")
			title_icon.texture = ICON_SIGNAL

		HenVirtualCNode.SubType.DEBUG, \
		HenVirtualCNode.SubType.DEBUG_VALUE, \
		HenVirtualCNode.SubType.DEBUG_PUSH, \
		HenVirtualCNode.SubType.DEBUG_FLOW_START, \
		HenVirtualCNode.SubType.START_DEBUG_STATE, \
		HenVirtualCNode.SubType.DEBUG_STATE:
			title_color.modulate = Color("#c8d6e5")
			title_icon.texture = ICON_DEBUG

		HenVirtualCNode.SubType.VOID:
			title_color.modulate = Color("#576574")
			title_icon.texture = ICON_VOID
		
		HenVirtualCNode.SubType.INVALID:
			title_color.modulate = Color("#e17055")
			title_icon.texture = ICON_INVALID
		
		HenVirtualCNode.SubType.RAW_CODE:
			title_color.modulate = Color("#8395a7")
			title_icon.texture = ICON_CODE

		HenVirtualCNode.SubType.IMG:
			title_color.modulate = Color("#8395a7")
			title_icon.texture = ICON_IMAGE

		HenVirtualCNode.SubType.EXPRESSION:
			title_color.modulate = Color("#8395a7")
			title_icon.texture = ICON_CALCULATOR

		HenVirtualCNode.SubType.NOT_CONNECTED:
			title_color.modulate = Color("#8395a7")
			title_icon.texture = ICON_LINK_OFF

		HenVirtualCNode.SubType.CAST:
			title_color.modulate = Color("#8395a7")
			title_icon.texture = ICON_BOX


static func instantiate_and_add_pool() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	global.can_instantiate_pool = true

	var total_pool_size: int = 100
	var budget_per_frame_usec: int = 8000
	
	var start_time: float = Time.get_ticks_usec()
	
	for i in range(total_pool_size):
		if not global or global.is_queued_for_deletion() or not global.is_inside_tree() or not global.can_instantiate_pool:
			return

		var instance: HenCnode = CNODE.instantiate()

		for input_idx in range(5):
			instance.add_input({name = "", type = "Variant"}, false)

		for output_idx in range(5):
			instance.add_output({name = "", type = "Variant"})
		
		instance.position = Vector2(50000, 50000)
		instance.is_pool = true
		instance.visible = false
		
		global.cnode_pool.append(instance)
		global.CNODE_CONTAINER.add_child(instance)

		if (Time.get_ticks_usec() - start_time) > budget_per_frame_usec:
			await global.CNODE_CONTAINER.get_tree().process_frame
			if not global or global.is_queued_for_deletion() or not global.is_inside_tree(): return
			start_time = Time.get_ticks_usec()

	for i in range(total_pool_size):
		if not global or global.is_queued_for_deletion() or not global.is_inside_tree() or not global.can_instantiate_pool:
			return

		var line: HenConnectionLine = CONNECTION_LINE.instantiate()
		line.visible = false
		line.position = Vector2(50000, 50000)
		global.connection_line_pool.append(line)
		global.CAM.get_node('Lines').add_child(line)
		
		if (Time.get_ticks_usec() - start_time) > budget_per_frame_usec:
			await global.CNODE_CONTAINER.get_tree().process_frame
			if not global or global.is_queued_for_deletion() or not global.is_inside_tree(): return
			start_time = Time.get_ticks_usec()

	for i in range(total_pool_size):
		if not global or global.is_queued_for_deletion() or not global.is_inside_tree() or not global.can_instantiate_pool:
			return

		var line: HenFlowConnectionLine = FLOW_CONNECTION_LINE.instantiate()
		line.visible = false
		line.position = Vector2(50000, 50000)
		global.flow_connection_line_pool.append(line)
		global.CAM.get_node('Lines').add_child(line)

		if (Time.get_ticks_usec() - start_time) > budget_per_frame_usec:
			await global.CNODE_CONTAINER.get_tree().process_frame
			if not global or global.is_queued_for_deletion() or not global.is_inside_tree(): return
			start_time = Time.get_ticks_usec()

	print('Pool instantiation finished.')


func _physics_process(_delta: float) -> void:
	if can_follow:
		position = position.lerp(follow_position, _delta * 48)
		on_move.emit()
		if position.is_equal_approx(follow_position):
			can_follow = false
			set_process(false)