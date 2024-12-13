@tool
extends PanelContainer

# imports
const _Global = preload('res://addons/hengo/scripts/global.gd')
const _RouteReference = preload('res://addons/hengo/scripts/route_reference.gd')

const ROUTE_SCENE = preload('res://addons/hengo/scenes/route_reference.tscn')

var hash: int = -1
var type: StringName = ''
var props: Array[Dictionary] = [
	{
		name = 'name',
		type = 'String',
		value = 'func'
	},
	{
		name = 'inputs',
		type = 'in_out',
		value = [
			{
				name = 'minha var',
				type = 'String',
			}
		]
	}
]

func _ready() -> void:
	gui_input.connect(_on_gui)


func _on_gui(_event: InputEvent) -> void:
	if _event is InputEventMouseButton:
		if _event.pressed and _event.button_index == MOUSE_BUTTON_RIGHT:
			_Global.ROUTE_REFERENCE_PROPS.show_props({list = props}, self)


static func instantiate(_config: Dictionary) -> _RouteReference:
	var route_reference = ROUTE_SCENE.instantiate()

	route_reference.hash = _Global.get_new_node_counter() if not _config.has('hash') else _config.hash
	route_reference.get_node('%Name').text = _config.name
	route_reference.position = _config.position if _config.has('position') else Vector2.ZERO
	route_reference.type = _config.type

	return route_reference


static func instantiate_and_add(_config: Dictionary) -> void:
	var route_reference = instantiate(_config)
	_Global.ROUTE_REFERENCE_CONTAINER.add_child(route_reference)
