@tool
extends PanelContainer

# imports
const _Global = preload('res://addons/hengo/scripts/global.gd')
const _RouteReference = preload('res://addons/hengo/scripts/route_reference.gd')
const _Router = preload('res://addons/hengo/scripts/router.gd')
const _CNode = preload('res://addons/hengo/scripts/cnode.gd')
const _Enums = preload('res://addons/hengo/references/enums.gd')

const ROUTE_SCENE = preload('res://addons/hengo/scenes/route_reference.tscn')
const REF_TEXT = ''

var hash: int = -1
var ref_count: int = 0
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
var props: Array

func _ready() -> void:
	gui_input.connect(_on_gui)
	get_node('%References').pressed.connect(_on_reference_press)


func _on_reference_press() -> void:
	var container = VBoxContainer.new()

	var icon_text = load('res://addons/hengo/assets/icons/arrow-up-right.svg')

	for cnode in _Global.GROUP.get_nodes_from_group('f_' + str(hash)):
		if cnode.deleted:
			continue

		
		match cnode.type:
			'func_input', 'func_output':
				continue

		var bt = Button.new()
		bt.pressed.connect(ref_pressed.bind(cnode))
		bt.text = cnode.route_ref.name
		bt.icon = icon_text
		container.add_child(bt)
	
	_Global.GENERAL_POPUP.get_parent().show_content(container, 'Go to Reference', global_position)


func ref_pressed(_cnode) -> void:
	_Router.change_route(_cnode.route_ref)
	_cnode.select()
	_Global.GENERAL_POPUP.get_parent().hide_popup()
	_Global.CNODE_CAM.go_to_center(_cnode.position + _cnode.size / 2)


func _on_gui(_event: InputEvent) -> void:
	if _event is InputEventMouseButton:
		if _event.pressed:
			if _event.button_index == MOUSE_BUTTON_LEFT:
				moving = true
				select()

				if _event.double_click:
					# unselecting others states
					for state in _Global.STATE_CONTAINER.get_children():
						state.unselect()

					_Router.change_route(route)
			elif _event.button_index == MOUSE_BUTTON_RIGHT:
				_Global.ROUTE_REFERENCE_PROPS.show_props({list = props}, self)
		else:
			moving = false
			unselect()

func _input(_event: InputEvent):
	if _event is InputEventMouseMotion:
		# moving on click
		if moving:
			move(position + _event.relative / _Global.CAM.transform.x.x)


func move(_pos: Vector2) -> void:
	position = _pos


func change_name(_name: String) -> void:
	get_node('%Name').text = _name
	route.name = _name
	size = Vector2.ZERO


func change_ref_count(_factor: int = 1) -> void:
	set_ref_count(ref_count + (1 * _factor))


func set_ref_count(_count: int) -> void:
	ref_count = _count
	get_node('%References').text = str(ref_count) + REF_TEXT


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
				route_reference.props = [
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

				var in_data: Dictionary = {
					name = 'input',
					sub_type = 'func_input',
					position = str_to_var(_config.get('input').get('pos')) if _config.has('input') else Vector2(0, 0),
					route = _config.route
				}

				var out_data: Dictionary = {
					name = 'output',
					sub_type = 'func_output',
					position = str_to_var(_config.get('output').get('pos')) if _config.has('output') else Vector2(0, 500),
					route = _config.route
				}

				# virtual function nodes
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


func select() -> void:
	get_node('%SelectBorder').visible = true


func unselect() -> void:
	get_node('%SelectBorder').visible = false


static func instantiate_and_add(_config: Dictionary) -> _RouteReference:
	var route_reference = instantiate(_config)
	_Global.ROUTE_REFERENCE_CONTAINER.add_child(route_reference)

	return route_reference


static func get_route_ref_by_id_or_null(_id: int) -> _RouteReference:
	var route_id_list = _Global.ROUTE_REFERENCE_CONTAINER.get_children().filter(func(x): return x.hash == _id)

	if not route_id_list.is_empty(): return route_id_list[0]
	return null