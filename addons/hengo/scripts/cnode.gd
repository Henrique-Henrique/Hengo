@tool
class_name HenCnode extends PanelContainer

const CNODE_INPUT = preload('res://addons/hengo/scenes/cnode_input.tscn')
const CNODE_OUTPUT = preload('res://addons/hengo/scenes/cnode_output.tscn')
const CNODE_SCENE_PATH: String = 'res://addons/hengo/scenes/cnode.tscn'
const CONNECTION_LINE = preload('res://addons/hengo/scenes/connection_line.tscn')
const FLOW_CONNECTION_LINE = preload('res://addons/hengo/scenes/flow_connection_line.tscn')


var flow_to: Dictionary = {}
var data: Dictionary = {}
var category: String
var id: StringName

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
signal on_mouse_exit

static var _cnode_scene_cache: PackedScene


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
	on_mouse_exit.emit()


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
	var idx: int = 0
	for child in get_node('%CenterContainer').get_children():
		if child.get_child_count() == 0: continue
		var child_row = child.get_child(0)
		if child_row.has_node('Input'):
			idx += 1

	var row: HBoxContainer = _get_row(idx)
	if not row: return null

	var input: HenCnodeInOut = CNODE_INPUT.instantiate()

	input.set_type(__input.get('type') if __input.has('type') else 'Variant')
	(input.get_node('%Name') as Label).text = __input.name
	input.root = self
	input.name = 'Input'

	row.add_child(input)
	row.move_child(input, 0)

	return input


func add_output(_output: Dictionary) -> void:
	var idx: int = 0
	for child in get_node('%CenterContainer').get_children():
		if child.get_child_count() == 0: continue
		var child_row = child.get_child(0)
		if child_row.has_node('Output'):
			idx += 1

	var row: HBoxContainer = _get_row(idx)
	if not row: return

	var output: HenCnodeInOut = CNODE_OUTPUT.instantiate()

	output.set_type(_output.get('type') if _output.has('type') else 'Variant')
	(output.get_node('%Name') as Label).text = _output.name
	output.root = self
	output.name = 'Output'

	row.add_child(output)


func _get_row(_idx: int) -> HBoxContainer:
	var container = get_node('%CenterContainer')
	if _idx < container.get_child_count():
		var child = container.get_child(_idx)
		if child.get_child_count() > 0:
			return child.get_child(0)
		# fallthrough if existing child is broken (though unlikely with fresh pool)
	
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	panel.add_theme_stylebox_override('panel', style)
	container.add_child(panel)

	var row = HBoxContainer.new()
	row.add_theme_constant_override('separation', 0)
	panel.add_child(row)
	
	return row


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
		'on_mouse_exit',
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


func request_flow_connetor_connection(_id: StringName, _mouse_pos: Vector2) -> void:
	request_flow_connection.emit(_id, _mouse_pos)


func update_title_color(_sub_type: int) -> void:
	var title_icon: TextureRect = get_node('%TitleIcon')
	var title: Label = get_node('%Title')

	var color: Color = HenUtils.get_color_for_subtype(_sub_type)

	# self_modulate = color
	title.add_theme_color_override('font_color', color)
	title_icon.modulate = color
	title_icon.texture = HenUtils.get_icon_for_subtype(_sub_type)


static func instantiate_and_add_pool() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var cnode_scene: PackedScene = _get_cnode_scene()

	if not cnode_scene:
		return

	global.can_instantiate_pool = true

	var total_pool_size: int = 100
	var budget_per_frame_usec: int = 8000
	
	var start_time: float = Time.get_ticks_usec()
	
	for i in range(total_pool_size):
		if not global or global.is_queued_for_deletion() or not global.is_inside_tree() or not global.can_instantiate_pool:
			return

		var instance: HenCnode = cnode_scene.instantiate()

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
			if not global or global.is_queued_for_deletion() or not global.is_inside_tree():
				return
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
			if not global or global.is_queued_for_deletion() or not global.is_inside_tree():
				return
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


static func _get_cnode_scene() -> PackedScene:
	if _cnode_scene_cache:
		return _cnode_scene_cache

	_cnode_scene_cache = load(CNODE_SCENE_PATH) as PackedScene
	return _cnode_scene_cache


func _physics_process(_delta: float) -> void:
	if can_follow:
		position = position.lerp(follow_position, _delta * 48)
		on_move.emit()
		if position.is_equal_approx(follow_position):
			can_follow = false
			set_process(false)
