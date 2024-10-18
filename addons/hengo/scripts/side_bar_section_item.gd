@tool
extends PanelContainer

# imports
const _Global = preload('res://addons/hengo/scripts/global.gd')
const _Enums = preload('res://addons/hengo/references/enums.gd')
const _Router = preload('res://addons/hengo/scripts/router.gd')
const _UtilsName = preload('res://addons/hengo/scripts/utils_name.gd')
const _CNode = preload('res://addons/hengo/scripts/cnode.gd')

var type: String
var mouse_inside: bool = false
var data: Dictionary = {} # this data is sent to cnode creation
var instance_reference: Array = []
var res: Array = []
var route = null
var virtual_cnode_list: Array = []
var old_parent = null
var color = '#1e202d'

# used only when item depends on another route
var route_ref = null

# only funcions
var output_cnode = null

# private
#
func _ready() -> void:
	gui_input.connect(_on_gui)
	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)

func _change_func_scene() -> void:
	_Router.change_route(route)

func _on_enter() -> void:
	get('theme_override_styles/panel').set('bg_color', Color.RED)
	mouse_inside = true

func _on_exit() -> void:
	get('theme_override_styles/panel').set('bg_color', color)
	mouse_inside = false

func _on_gui(_event: InputEvent) -> void:
	if _event is InputEventMouseButton:
		if not _event.pressed:
			if _event.button_index == MOUSE_BUTTON_LEFT:
				# dropping prop in canvas
				if _Global.mouse_on_cnode_ui:
					if type == 'function':
						_Global.DROP_PROP_MENU.mount(type, self, data)
						return
					
					_Global.DROP_PROP_MENU.mount(type, self, data)

					_Global.DROP_PROP_MENU.popup()
					_Global.DROP_PROP_MENU.position = get_viewport().get_window().position + Vector2i(get_global_mouse_position())
					return
				
				# opening popup to edit
				if mouse_inside:
					_Global.SIDE_MENU_POPUP.mount(res, {
						ref = self
					})
					await RenderingServer.frame_post_draw
					_Global.SIDE_MENU_POPUP.position = global_position
					_Global.SIDE_MENU_POPUP.position.x -= _Global.SIDE_MENU_POPUP.size.x
					_Global.SIDE_MENU_POPUP.get_parent().show()

# public
#
func start_item(_config: Dictionary = {}) -> void:
	match type:
		'function':
			var bt = Button.new()
			bt.text = 'Edit'
			bt.pressed.connect(_change_func_scene)
			get_node('Container').add_child(bt)

			var _route = {
				id = _UtilsName.get_unique_name(),
				type = _Router.ROUTE_TYPE.FUNC,
				item_ref = self
			}

			_Router.route_reference[_route.id] = []
			_Router.line_route_reference[_route.id] = []
			_Router.comment_reference[_route.id] = []
			route = _route

			var in_data: Dictionary = {
				name = 'input',
				sub_type = 'func_input',
				position = str_to_var(_config.get('input').get('pos')) if _config.has('input') else Vector2(0, 0),
				outputs = res[1].inputs,
				route = _route
			}

			if _config.has('input'):
				in_data.hash = _config.get('input').get('id')

			var input = _CNode.instantiate_cnode(in_data)

			var out_data: Dictionary = {
				name = 'output',
				sub_type = 'func_output',
				position = str_to_var(_config.get('output').get('pos')) if _config.has('output') else Vector2(0, 500),
				inputs = res[2].outputs,
				route = _route
			}

			if _config.has('output'):
				out_data.hash = _config.get('output').get('id')

			var output = _CNode.instantiate_cnode(out_data)

			if _config.has('cnode_refs'):
				_config.cnode_refs[_config.get('input').get('id')] = input
				_config.cnode_refs[_config.get('output').get('id')] = output

			instance_reference.append(input)
			instance_reference.append(output)
			output_cnode = output
		'state_signal':
			var bt = Button.new()
			bt.text = 'Edit'
			bt.pressed.connect(_change_func_scene)
			get_node('Container').add_child(bt)

			var _route = {
				id = _UtilsName.get_unique_name(),
				type = _Router.ROUTE_TYPE.SIGNAL,
				item_ref = self
			}

			_Router.route_reference[_route.id] = []
			_Router.line_route_reference[_route.id] = []
			_Router.comment_reference[_route.id] = []
			route = _route

			var dt = data.signal_data
			var params = ClassDB.class_get_signal(dt.object_name, dt.signal_name).args.map(
				func(arg: Dictionary) -> Dictionary:
					return {
						name = arg.name,
						type = type_string(arg.type)
					}
			) + res[1].outputs

			var signal_data: Dictionary = {
				name = 'On:: ' + dt.signal_name,
				outputs = params,
				position = str_to_var(_config.get('signal').get('pos')) if _config.has('signal') else Vector2(0, 0),
				sub_type = 'signal_virtual',
				route = _route
			}

			if _config.has('signal'):
				signal_data.hash = _config.get('signal').get('id')

			var input = _CNode.instantiate_cnode(signal_data)

			if _config.has('cnode_refs'):
				_config.cnode_refs[_config.get('signal').get('id')] = input

			instance_reference.append(input)

# used in undo/redo
func remove_from_scene() -> void:
	if not old_parent:
		old_parent = get_parent()

	for cnode in instance_reference:
		cnode.remove_from_scene()

	old_parent.remove_child(self)

func add_to_scene() -> void:
	old_parent.add_child(self)

	for cnode in instance_reference:
		cnode.add_to_scene()
