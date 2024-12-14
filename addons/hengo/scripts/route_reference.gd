@tool
extends PanelContainer

# imports
const _Global = preload('res://addons/hengo/scripts/global.gd')
const _RouteReference = preload('res://addons/hengo/scripts/route_reference.gd')
const _Router = preload('res://addons/hengo/scripts/router.gd')
const _CNode = preload('res://addons/hengo/scripts/cnode.gd')

const ROUTE_SCENE = preload('res://addons/hengo/scenes/route_reference.tscn')

var hash: int = -1
var route: Dictionary = {
	name = '',
	type = _Router.ROUTE_TYPE.FUNC,
	id = ''
}
# only funcions
var output_cnode = null
var virtual_cnode_list: Array = []
var moving: bool = false
var type: StringName = ''
var props: Array = [
	{
		name = 'name',
		type = 'String',
		value = 'func_name'
	},
	{
		name = 'inputs',
		type = 'in_out',
		value = []
	},
	{
		name = 'outputs',
		type = 'in_out',
		value = []
	}
]

func _ready() -> void:
	gui_input.connect(_on_gui)


func _on_gui(_event: InputEvent) -> void:
	if _event is InputEventMouseButton:
		if _event.pressed:
			if _event.button_index == MOUSE_BUTTON_LEFT:
				moving = true

				# unselecting others states
				for state in _Global.STATE_CONTAINER.get_children():
					state.unselect()

				_Router.change_route(route)
			elif _event.button_index == MOUSE_BUTTON_RIGHT:
				_Global.ROUTE_REFERENCE_PROPS.show_props({list = props}, self)
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
	get_node('%Name').text = _name


static func instantiate(_config: Dictionary) -> _RouteReference:
	var route_reference = ROUTE_SCENE.instantiate()

	route_reference.hash = _Global.get_new_node_counter() if not _config.has('hash') else _config.hash

	route_reference.route = _config.route
	route_reference.route.item_ref = route_reference

	_Router.route_reference[_config.route.id] = []
	_Router.line_route_reference[_config.route.id] = []
	_Router.comment_reference[_config.route.id] = []

	route_reference.get_node('%Name').text = _config.name
	route_reference.position = _config.position if _config.has('position') else Vector2.ZERO
	route_reference.type = _config.type


	if _config.has('pos'):
		route_reference.position = str_to_var(_config.pos)

	if _config.has('props'):
		route_reference.props = _config.props
	else:
		# initializing inputs and outputs
		match _config.type:
			'func':
				var in_data: Dictionary = {
					name = 'input',
					sub_type = 'func_input',
					position = str_to_var(_config.get('input').get('pos')) if _config.has('input') else Vector2(0, 0),
					route = _config.route
				}

				# if _config.has('input'):
				# 	in_data.hash = _config.get('input').get('id')

				var out_data: Dictionary = {
					name = 'output',
					sub_type = 'func_output',
					position = str_to_var(_config.get('output').get('pos')) if _config.has('output') else Vector2(0, 500),
					route = _config.route
				}

				var input = _CNode.instantiate_cnode(in_data)
				var output = _CNode.instantiate_cnode(out_data)

				_Global.GROUP.add_to_group('f_' + str(route_reference.hash), input)
				_Global.GROUP.add_to_group('f_' + str(route_reference.hash), output)

				route_reference.output_cnode = output

	match _config.type:
		'func':
			route_reference.change_name(
				route_reference.props[0].value
			)
			
	return route_reference


static func instantiate_and_add(_config: Dictionary) -> _RouteReference:
	var route_reference = instantiate(_config)
	_Global.ROUTE_REFERENCE_CONTAINER.add_child(route_reference)

	return route_reference
