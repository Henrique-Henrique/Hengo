@tool
class_name HenState extends PanelContainer

static var _name_counter: int = 1

var route: Dictionary = {
	name = '',
	type = HenRouter.ROUTE_TYPE.STATE,
	id = '',
	state_ref = null
}

var virtual_cnode_list: Array = []
var to_lines: Array = []
var from_lines: Array = []

# behavior
var moving: bool = false
var selected: bool = false
var hash: int

var virtual_ref: HenVirtualState

signal on_move

# private
#
func _ready() -> void:
	var title: Button = get_node('%Title') as Button

	title.gui_input.connect(_on_gui)
	title.mouse_entered.connect(_on_enter)
	title.mouse_exited.connect(_on_exit)


func _on_enter():
	if virtual_ref:
		print(virtual_ref.events)
		# print(virtual_ref.from_transitions, '  |  ', virtual_ref.transitions)

	if HenGlobal.can_make_state_connection:
		HenGlobal.state_connection_to_date = {
			state_from = self,
		}


		get_node('%HoverBorder').visible = true
		HenGlobal.STATE_CONNECTION_GUIDE.hover_pos = HenGlobal.CAM.get_relative_vec2(global_position)
		HenGlobal.STATE_CONNECTION_GUIDE.default_color = Color('#00b678')
		
		if HenGlobal.current_state_transition:
			HenGlobal.current_state_transition.hover(true)


func _on_exit():
	HenGlobal.state_connection_to_date = {}
	get_node('%HoverBorder').visible = false
	HenGlobal.STATE_CONNECTION_GUIDE.hover_pos = null
	HenGlobal.STATE_CONNECTION_GUIDE.default_color = Color.WHITE

	if HenGlobal.current_state_transition:
		HenGlobal.current_state_transition.hover(false)


func _on_gui(_event: InputEvent) -> void:
	if _event is InputEventMouseButton:
		if _event.pressed:
			if _event.ctrl_pressed:
				if selected:
					unselect()
				else:
					select()
			else:
				if _event.button_index == MOUSE_BUTTON_LEFT:
					if _event.double_click:
						print(route)
						HenRouter.change_route(route)

					if selected:
						for i in get_tree().get_nodes_in_group(HenEnums.STATE_SELECTED_GROUP):
							i.moving = true
					else:
						moving = true
						# cleaning other selects
						for i in get_tree().get_nodes_in_group(HenEnums.STATE_SELECTED_GROUP):
							i.moving = false
							i.unselect()

						select()
		else:
			moving = false
			# group moving false
			for i in get_tree().get_nodes_in_group(HenEnums.STATE_SELECTED_GROUP):
				i.moving = false

func _input(_event: InputEvent):
	if _event is InputEventMouseMotion:
		# moving on click
		if moving:
			move(position + _event.relative / HenGlobal.CAM.transform.x.x)

func _notification(what):
	match what:
		NOTIFICATION_PREDELETE:
			# TODO delete all cnodes references
			print('STATE DELETED')

# public
#
func get_state_name() -> String:
	return get_node('%Title').text

func set_state_name(_name: String) -> void:
	get_node('%Title').text = _name
	route.name = _name

func move(_pos: Vector2) -> void:
	position = _pos

	if virtual_ref:
		virtual_ref.position = _pos

	emit_signal('on_move')

func select() -> void:
	add_to_group(HenEnums.STATE_SELECTED_GROUP)
	get_node('%SelectBorder').visible = true
	selected = true

func unselect() -> void:
	remove_from_group(HenEnums.STATE_SELECTED_GROUP)
	get_node('%SelectBorder').visible = false
	selected = false


# using on undo / redo
func add_to_scene() -> void:
	HenGlobal.STATE_CONTAINER.add_child(self)

	for line in from_lines:
		line.add_to_scene(false)
	
	for line in to_lines:
		line.add_to_scene(false)


func remove_from_scene() -> void:
	if is_inside_tree():
		for line in from_lines:
			line.remove_from_scene(false)
		
		for line in to_lines:
			line.remove_from_scene(false)

		HenGlobal.STATE_CONTAINER.remove_child(self)


func add_event(_config: Dictionary) -> PanelContainer:
	var event_container = get_node('%EventContainer')
	var event = HenAssets.EventScene.instantiate()

	event.get_child(0).text = _config.name


	event.set_meta('config', _config)

	if event_container.get_child_count() <= 0:
		var event_struct = HenAssets.EventStructScene.instantiate()
		event_container.add_child(event_struct)
	
	var event_list = event_container.get_child(0).get_node('%EventList')
	event_list.add_child(event)

	return event


func remove_event(_event: PanelContainer) -> void:
	var event_container := get_node('%EventContainer')
	var parent = _event.get_parent()

	parent.remove_child(_event)
	_event.queue_free()

	if parent.get_child_count() <= 0:
		parent.get_parent().queue_free()


func add_transition(_name: String) -> HenStateTransition:
	var transition = preload('res://addons/hengo/scenes/state_transition.tscn').instantiate()
	transition.set_transition_name(_name)
	transition.root = self
	get_node('%TransitionContainer').add_child(transition)
	size = Vector2.ZERO

	return transition


func get_all_transition_data() -> Array:
	return get_node('%TransitionContainer').get_children().map(func(x): return {
		name = x.get_transition_name()
	})


func show_debug() -> void:
	if is_instance_valid(HenGlobal.old_state_debug):
		HenGlobal.old_state_debug.hide_debug()
	
	get_node('%DebugBorder').visible = true
	
	HenGlobal.old_state_debug = self


func hide_debug() -> void:
	get_node('%DebugBorder').visible = false


# static
#
static func instantiate_state(_config: Dictionary = {}) -> HenState:
	var state_scene = preload('res://addons/hengo/scenes/state.tscn')
	var state = state_scene.instantiate()
	var type: StringName = 'new'

	if not _config.is_empty():
		if _config.has('type'):
			type = _config.type
		else:
			type = 'load'

	state.hash = HenGlobal.get_new_node_counter() if not _config.has('hash') else _config.hash

	if _config.has('name'):
		state.get_node('%Title').text = _config.name
	else:
		_name_counter += 1
		state.get_node('%Title').text = 'State ' + str(_name_counter)

	if _config.has('pos'):
		state.position = str_to_var(_config.pos)
	elif _config.has('position'):
		state.position = _config.position
	else:
		state.position = Vector2.ZERO

	state.route.id = HenUtilsName.get_unique_name()
	state.route.state_ref = state
	state.route.name = state.get_node('%Title').text

	HenRouter.route_reference[state.route.id] = []
	HenRouter.line_route_reference[state.route.id] = []
	HenRouter.comment_reference[state.route.id] = []

	if type == 'new':
		# adding initial cnodes (update and ready)
		HenCnode.instantiate_and_add({
			name = 'enter',
			sub_type = HenCnode.SUB_TYPE.VIRTUAL,
			route = state.route,
			position = Vector2.ZERO
		})
		HenCnode.instantiate_and_add({
			name = 'update',
			sub_type = HenCnode.SUB_TYPE.VIRTUAL,
			outputs = [ {
				name = 'delta',
				type = 'float'
			}],
			route = state.route,
			position = Vector2(400, 0)
		})

		HenRouter.change_route(state.route)
	
	state.size = Vector2.ZERO

	HenEnums.DROPDOWN_STATES.append(state.route)

	return state


static func instantiate_and_add_to_scene(_config: Dictionary = {}) -> HenState:
	var state = HenState.instantiate_state(_config)

	state.add_to_scene()

	return state