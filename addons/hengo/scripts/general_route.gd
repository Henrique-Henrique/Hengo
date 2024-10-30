@tool
extends Button


# imports
const _Global = preload('res://addons/hengo/scripts/global.gd')
const _Router = preload('res://addons/hengo/scripts/router.gd')
const _GeneralRoute = preload('res://addons/hengo/scripts/general_route.gd')

var route: Dictionary = {
	name = '',
	type = _Router.ROUTE_TYPE.INPUT,
	id = '',
	state_ref = null
}
var virtual_cnode_list: Array = []
var moving: bool = false

func _ready() -> void:
	gui_input.connect(_on_gui)


func _on_gui(_event: InputEvent) -> void:
	if _event is InputEventMouseButton:
		if _event.pressed and _event.button_index == MOUSE_BUTTON_LEFT:
			moving = true

			# unselecting others states
			for state in _Global.STATE_CONTAINER.get_children():
				state.unselect()

			_Router.change_route(route)
		else:
			moving = false

func _input(_event: InputEvent):
	if _event is InputEventMouseMotion:
		# moving on click
		if moving:
			move(position + _event.relative / _Global.CAM.transform.x.x)
		

func move(_pos: Vector2) -> void:
	position = _pos


func change_name(_name: String) -> void:
	text = _name


# static
static func instantiate_general(_config: Dictionary) -> _GeneralRoute:
	var general_route_scene = load('res://addons/hengo/scenes/general_route.tscn')
	var general_route = general_route_scene.instantiate()

	general_route.route = _config.route
	general_route.text = _config.route.name
	general_route.route.general_ref = general_route

	_Router.route_reference[_config.route.id] = []
	_Router.line_route_reference[_config.route.id] = []
	_Router.comment_reference[_config.route.id] = []

	if _config.has('icon'):
		general_route.icon = load(_config.icon)

	_Global.GENERAL_CONTAINER.add_child(general_route)

	return general_route