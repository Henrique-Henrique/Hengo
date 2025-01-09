@tool
class_name HenGeneralRoute extends Button

var route: Dictionary = {
	name = '',
	type = HenRouter.ROUTE_TYPE.INPUT,
	id = '',
	state_ref = null
}
var virtual_cnode_list: Array = []
var moving: bool = false
var type: StringName = ''
var custom_data: Dictionary = {}
var id: int = -1

func _ready() -> void:
	gui_input.connect(_on_gui)


func _on_gui(_event: InputEvent) -> void:
	if _event is InputEventMouseButton:
		if _event.pressed and _event.button_index == MOUSE_BUTTON_LEFT:
			moving = true

			# unselecting others states
			for state in HenGlobal.STATE_CONTAINER.get_children():
				state.unselect()

			HenRouter.change_route(route)
		else:
			moving = false

func _input(_event: InputEvent):
	if _event is InputEventMouseMotion:
		# moving on click
		if moving:
			move(position + _event.relative / HenGlobal.CAM.transform.x.x)
		

func move(_pos: Vector2) -> void:
	position = _pos


func change_name(_name: String) -> void:
	text = _name


func get_general_name() -> String:
	return text


# static
static func instantiate_general(_config: Dictionary) -> HenGeneralRoute:
	var general_route_scene = load('res://addons/hengo/scenes/general_route.tscn')
	var general_route = general_route_scene.instantiate()

	general_route.id = HenGlobal.get_new_node_counter() if not _config.has('id') else _config.id

	general_route.route = _config.route
	general_route.text = _config.route.name
	general_route.route.general_ref = general_route

	HenRouter.route_reference[_config.route.id] = []
	HenRouter.line_route_reference[_config.route.id] = []
	HenRouter.comment_reference[_config.route.id] = []

	if _config.has('icon'):
		general_route.icon = load(_config.icon)

	if _config.has('type'):
		general_route.type = _config.type


	if _config.has('pos'):
		general_route.position = str_to_var(_config.pos)


	if _config.has('color'):
		general_route.get_theme_stylebox('normal').bg_color = Color(_config.color)

	if _config.has('custom_data'):
		general_route.custom_data = _config.custom_data

	HenGlobal.GENERAL_CONTAINER.add_child(general_route)

	return general_route