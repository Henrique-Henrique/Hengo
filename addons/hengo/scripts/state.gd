@tool
extends PanelContainer

# imports
const _Global = preload('res://addons/hengo/scripts/global.gd')
const _Router = preload('res://addons/hengo/scripts/router.gd')
const _Enums = preload('res://addons/hengo/references/enums.gd')
const _Assets = preload('res://addons/hengo/scripts/assets.gd')
const _CNode = preload('res://addons/hengo/scripts/cnode.gd')
const _State = preload('res://addons/hengo/scripts/state.gd')
const _UtilsName = preload('res://addons/hengo/scripts/utils_name.gd')
const _StateTransition = preload('res://addons/hengo/scripts/state_transition.gd')

static var _name_counter: int = 1

var route: Dictionary = {
	name = '',
	type = _Router.ROUTE_TYPE.STATE,
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

signal on_move

# private
#
func _ready() -> void:
	var title: Button = get_node('%Title') as Button

	title.gui_input.connect(_on_gui)
	title.mouse_entered.connect(_on_enter)
	title.mouse_exited.connect(_on_exit)


func _on_enter():
	if _Global.can_make_state_connection:
		_Global.state_connection_to_date = {
			state_from = self,
		}

		get_node('%HoverBorder').visible = true
		_Global.STATE_CONNECTION_GUIDE.hover_pos = _Global.CAM.get_relative_vec2(global_position)
		_Global.STATE_CONNECTION_GUIDE.default_color = Color('#00b678')
		
		if _Global.current_state_transition:
			_Global.current_state_transition.hover(true)


func _on_exit():
	_Global.state_connection_to_date = {}
	get_node('%HoverBorder').visible = false
	_Global.STATE_CONNECTION_GUIDE.hover_pos = null
	_Global.STATE_CONNECTION_GUIDE.default_color = Color.WHITE

	if _Global.current_state_transition:
		_Global.current_state_transition.hover(false)


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
					_Router.change_route(route)

					if selected:
						for i in get_tree().get_nodes_in_group(_Enums.STATE_SELECTED_GROUP):
							i.moving = true
					else:
						moving = true
						# cleaning other selects
						for i in get_tree().get_nodes_in_group(_Enums.STATE_SELECTED_GROUP):
							i.moving = false
							i.unselect()
						select()
				elif _event.button_index == MOUSE_BUTTON_RIGHT:
					var menu = load('res://addons/hengo/scenes/state_prop_menu.tscn').instantiate()
					var pos = global_position

					pos.x += size.x + 4
					menu.start_prop(self)
					_Global.GENERAL_POPUP.get_parent().show_content(menu, 'State Prop', pos)
		else:
			moving = false
			# group moving false
			for i in get_tree().get_nodes_in_group(_Enums.STATE_SELECTED_GROUP):
				i.moving = false

func _input(_event: InputEvent):
	if _event is InputEventMouseMotion:
		# moving on click
		if moving:
			move(position + _event.relative / _Global.CAM.transform.x.x)

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

func move(_pos: Vector2) -> void:
	position = _pos
	emit_signal('on_move')

func select() -> void:
	add_to_group(_Enums.STATE_SELECTED_GROUP)
	get_node('%SelectBorder').visible = true
	selected = true

func unselect() -> void:
	remove_from_group(_Enums.STATE_SELECTED_GROUP)
	get_node('%SelectBorder').visible = false
	selected = false


# using on undo / redo
func add_to_scene() -> void:
	_Global.STATE_CONTAINER.add_child(self)

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

		_Global.STATE_CONTAINER.remove_child(self)


func add_event(_config: Dictionary) -> PanelContainer:
	var event_container := get_node('%EventContainer')
	var event := _Assets.EventScene.instantiate()

	event.get_child(0).text = _config.name

	match _config.type:
		'start':
			_Global.start_state = self

	event.set_meta('config', _config)

	if event_container.get_child_count() <= 0:
		var event_struct := _Assets.EventStructScene.instantiate()
		event_container.add_child(event_struct)
	
	var event_list := event_container.get_child(0).get_node('%EventList')
	event_list.add_child(event)

	return event

func remove_event(_event: PanelContainer) -> void:
	var event_container := get_node('%EventContainer')
	var parent = _event.get_parent()

	parent.remove_child(_event)
	_event.queue_free()

	if parent.get_child_count() <= 0:
		parent.get_parent().queue_free()

func add_transition(_name: String) -> _StateTransition:
	var transition = load('res://addons/hengo/scenes/state_transition.tscn').instantiate()
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
	if is_instance_valid(_Global.old_state_debug):
		_Global.old_state_debug.hide_debug()
	
	get_node('%DebugBorder').visible = true
	
	_Global.old_state_debug = self


func hide_debug() -> void:
	get_node('%DebugBorder').visible = false


# static
#
static func instantiate_state(_config: Dictionary = {}) -> _State:
	var state_scene = load('res://addons/hengo/scenes/state.tscn')
	var state = state_scene.instantiate()

	state.hash = _Global.get_new_node_counter() if not _config.has('hash') else _config.hash

	var type: StringName = 'new'

	if not _config.is_empty():
		type = 'load'

	if _config.has('name'):
		state.get_node('%Title').text = _config.name
	else:
		_name_counter += 1
		state.get_node('%Title').text = 'State Name ' + str(_name_counter)

	if _config.has('pos'):
		state.position = str_to_var(_config.pos)

	state.route.id = _UtilsName.get_unique_name()
	state.route.state_ref = state
	state.route.name = state.get_node('%Title').text

	_Router.route_reference[state.route.id] = []
	_Router.line_route_reference[state.route.id] = []
	_Router.comment_reference[state.route.id] = []

	if type == 'new':
		# adding initial cnodes (update and ready)
		_CNode.instantiate_and_add({
			name = 'enter',
			sub_type = 'virtual',
			route = state.route,
			position = Vector2.ZERO
		})
		_CNode.instantiate_and_add({
			name = 'update',
			sub_type = 'virtual',
			outputs = [ {
				name = 'delta',
				type = 'float'
			}],
			route = state.route,
			position = Vector2(400, 0)
		})

		# state.add_transition('FINISHED')

		print(state.route)

		_Router.change_route(state.route)

		state.position = Vector2.ZERO
	
	state.size = Vector2.ZERO

	_Enums.DROPDOWN_STATES.append(state.route)


	print('INSTANCD ', _Global.STATE_CONTAINER.get_child_count())

	return state


static func instantiate_and_add_to_scene(_config: Dictionary = {}) -> _State:
	var state = _State.instantiate_state(_config)

	state.add_to_scene()

	return state