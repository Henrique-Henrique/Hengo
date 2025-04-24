@tool
class_name HenMethodPicker extends VBoxContainer

enum Type {
	COMMENT
}

var list_container: VBoxContainer
var start_pos: Vector2 = Vector2.ZERO
var connection_type: StringName = 'all'
var show_native_first: bool = true
var came_from: String = ''
var cnode_config: Dictionary = {}
var api_list = []

const LIST_SIZE: int = 40

enum CLASS_TYPE {
	SELF,
	OTHER
}
enum FILTER_TYPE {
	ALL,
	NATIVE,
	FUNC,
	SIGNAL,
	MACRO
}

var class_type: CLASS_TYPE = CLASS_TYPE.SELF
var select_type: FILTER_TYPE = FILTER_TYPE.ALL
var selected_class: StringName
var name_to_search: String = ''

var first_time: bool = true

@onready var class_border: Panel = %ClassBorder
@onready var tree: Tree = %List


const BG_COLOR = {
	FILTER_TYPE.FUNC: Color('#432F2F'),
	FILTER_TYPE.SIGNAL: Color('#2F4335'),
	FILTER_TYPE.MACRO: Color('#332F43'),
	FILTER_TYPE.NATIVE: Color.BLACK,
}

const FILTER_ICONS = {
	FILTER_TYPE.FUNC: preload('res://addons/hengo/assets/icons/menu/void.svg'),
	FILTER_TYPE.SIGNAL: preload('res://addons/hengo/assets/icons/menu/wifi.svg'),
	FILTER_TYPE.MACRO: preload('res://addons/hengo/assets/icons/menu/text.svg'),
	FILTER_TYPE.NATIVE: preload('res://addons/hengo/assets/icons/menu/text.svg'),
}

# var selected_id: int = 0:
# 	set(new_value):
# 		var item = list_container.get_child(new_value)
# 		var old_item = list_container.get_child(selected_id) if list_container.get_child_count() > selected_id else null

# 		if old_item:
# 			_item_exit(old_item)

# 		if item:
# 			_item_hover(item)

		# selected_id = new_value

var native_list: Array = [
	{
		name = 'State',
		data = {
			name = 'State 1',
			type = HenVirtualCNode.Type.STATE,
			sub_type = HenVirtualCNode.SubType.STATE,
			route = HenRouter.current_route,
		}
	},
	{
		name = 'State Event',
		data = {
			name = 'State Event 1',
			type = HenVirtualCNode.Type.STATE_EVENT,
			sub_type = HenVirtualCNode.SubType.STATE_EVENT,
			route = HenRouter.current_route,
		}
	},
	
	
	{
		name = 'Get',
		data = {
			name = 'Get',
			sub_type = HenVirtualCNode.SubType.GET_PROP,
			outputs = [
				{
					name = '',
					type = 'Variant',
					sub_type = '@dropdown',
					category = 'get_prop',
				}
			],
			route = HenRouter.current_route
		}

	},
	{
		name = 'Set',
		data = {
			name = 'Set',
			sub_type = HenVirtualCNode.SubType.SET_PROP,
			inputs = [
				{
					name = '',
					type = 'Variant',
					sub_type = '@dropdown',
					category = 'set_prop',
					code_value = '__a',
					is_static = true
				},
				{
					name = 'value',
					type = 'Variant',
				},
			],
			route = HenRouter.current_route
		}
	},
	{
		name = 'Expression',
		data = {
			name = 'Expression',
			type = HenVirtualCNode.Type.EXPRESSION,
			sub_type = HenVirtualCNode.SubType.EXPRESSION,
			category = 'native',
			inputs = [
				{
					name = '',
					type = 'Variant',
					sub_type = 'expression',
					is_static = true
				}
			],
			outputs = [
				{
					name = 'result',
					type = 'Variant'
				}
			],
			route = HenRouter.current_route
		}
	},
	{
		name = 'Make Transition',
		data = {
			name = 'make_transition',
			sub_type = HenVirtualCNode.SubType.FUNC,
			category = 'native',
			inputs = [
				{
					name = 'name',
					type = 'StringName',
					sub_type = '@dropdown',
					category = 'state_transition'
				}
			],
			route = HenRouter.current_route
		}
	},
	{
		name = 'Cast To ->',
		data = {
			name = 'Cast To',
			sub_type = HenVirtualCNode.SubType.CAST,
			category = 'native',
			inputs = [
				{
					name = 'from',
					type = 'Variant'
				}
			],
			outputs = [
				{
					name = 'to',
					type = 'Node',
					sub_type = '@dropdown',
					category = 'cast_type'
				}
			],
			route = HenRouter.current_route
		}
	},
	{
		name = 'debug value',
		data = {
			name = '',
			fantasy_name = 'Debug Value',
			sub_type = HenVirtualCNode.SubType.DEBUG_VALUE,
			category = 'native',
			inputs = [
				{
					name = 'content',
					type = 'Variant'
				}
			],
			route = HenRouter.current_route
		}
	},
	{
		name = 'print',
		data = {
			name = 'print',
			sub_type = HenVirtualCNode.SubType.VOID,
			category = 'native',
			inputs = [
				{
					name = 'content',
					type = 'Variant'
				}
			],
			route = HenRouter.current_route
		}
	},
	{
		name = 'Print Text',
		data = {
			name = 'print',
			sub_type = HenVirtualCNode.SubType.VOID,
			category = 'native',
			inputs = [
				{
					name = 'content',
					type = 'String'
				}
			],
			route = HenRouter.current_route
		}
	},
	{
		name = 'IF Condition',
		data = {
			name = 'IF',
			type = HenVirtualCNode.Type.IF,
			sub_type = HenVirtualCNode.SubType.IF,
			route = HenRouter.current_route,
			inputs = [
				{
					name = 'condition',
					type = 'bool'
				},
			],
		}
	},
	{
		name = 'For -> Range',
		data = {
			name = 'For -> Range',
			type = HenVirtualCNode.Type.FOR,
			sub_type = HenVirtualCNode.SubType.FOR,
			inputs = [
				{
					name = 'start',
					type = 'int'
				},
				{
					name = 'end',
					type = 'int'
				},
				{
					name = 'step',
					type = 'int'
				}
			],
			outputs = [
				{
					name = 'index',
					type = 'int'
				}
			],
			route = HenRouter.current_route
		}
	},
	{
		name = 'For -> Item',
		data = {
			name = 'For -> Item',
			type = HenVirtualCNode.Type.FOR,
			sub_type = HenVirtualCNode.SubType.FOR_ARR,
			inputs = [
				{
					name = 'array',
					type = 'Array'
				},
			],
			outputs = [
				{
					name = 'item',
					type = 'Variant'
				}
			],
			route = HenRouter.current_route
		}
	},
	{
		name = 'break',
		data = {
			name = 'break',
			sub_type = HenVirtualCNode.SubType.BREAK,
			category = 'native',
			route = HenRouter.current_route
		}
	},
	{
		name = 'continue',
		data = {
			name = 'continue',
			sub_type = HenVirtualCNode.SubType.CONTINUE,
			category = 'native',
			route = HenRouter.current_route
		}
	},
	{
		name = 'Raw Code',
		data = {
			name = 'Raw Code',
			sub_type = HenVirtualCNode.SubType.RAW_CODE,
			category = 'native',
			inputs = [
				{
					name = '',
					category = 'disabled',
					type = 'String'
				},
			],
			outputs = [
				{
					name = 'code',
					type = 'Variant'
				}
			],
			route = HenRouter.current_route
		}
	},
]


func _ready() -> void:
	tree.item_activated.connect(_on_select)
	(%Search as LineEdit).text_changed.connect(_on_search)
	(%Search as LineEdit).grab_focus()
	(%SelfBt as Button).pressed.connect(_on_class_bt.bind(HenGlobal.script_config.type, %SelfBt, CLASS_TYPE.SELF))
	(%ClassBt as HenDropdown).value_changed.connect(_on_class_bt.bind(%ClassBt, CLASS_TYPE.OTHER))

	# filter buttons
	for chd: Button in (%FilterList as HBoxContainer).get_children():
		chd.pressed.connect(_filter_change.bind(chd.name))

	_on_class_bt(HenGlobal.script_config.type, %SelfBt, CLASS_TYPE.SELF)

	for data: Dictionary in native_list:
		data.type = FILTER_TYPE.NATIVE
		api_list.append(data)

	build_list()


func _filter_change(_name: StringName) -> void:
	match _name:
		&'All':
			select_type = FILTER_TYPE.ALL
		&'Native':
			select_type = FILTER_TYPE.NATIVE
		&'Func':
			select_type = FILTER_TYPE.FUNC
		&'Signal':
			select_type = FILTER_TYPE.SIGNAL
		&'Macro':
			select_type = FILTER_TYPE.MACRO
	
	build_list()


func _on_search(_text: String) -> void:
	name_to_search = _text
	build_list()


func _on_class_bt(_class: StringName, _button: Button, _type: CLASS_TYPE) -> void:
	selected_class = _class
	_select_class(_button)

	match _type:
		CLASS_TYPE.SELF:
			for dict in ClassDB.class_get_method_list(selected_class):
				api_list.append(_get_class_obj(dict, selected_class))
			
								
			# functions
			for func_data: HenSideBar.FuncData in HenGlobal.SIDE_BAR_LIST.func_list:
				var dt: Dictionary = {
					name = func_data.name,
					type = FILTER_TYPE.FUNC,
					data = func_data.get_cnode_data()
				}

				api_list.append(dt)


			# signals
			for signal_data: HenSideBar.SignalData in HenGlobal.SIDE_BAR_LIST.signal_list:
				var connect_dt: Dictionary = {
					name = signal_data.name,
					type = FILTER_TYPE.SIGNAL,
					data = signal_data.get_connect_cnode_data()
				}

				var disconnect_dt: Dictionary = {
					name = signal_data.name,
					type = FILTER_TYPE.SIGNAL,
					data = signal_data.get_diconnect_cnode_data()
				}

				api_list.append(connect_dt)
				api_list.append(disconnect_dt)
			
			# macro
			for macro_data: HenSideBar.MacroData in HenGlobal.SIDE_BAR_LIST.macro_list:
				var dt: Dictionary = {
					name = macro_data.name,
					type = FILTER_TYPE.MACRO,
					data = macro_data.get_cnode_data()
				}

				api_list.append(dt)


func _select_class(_button: Button) -> void:
	class_border.visible = true

	await RenderingServer.frame_pre_draw

	if not first_time:
		var tween: Tween = get_tree().create_tween()
		tween.tween_property(class_border, 'global_position', _button.global_position, .2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		class_border.global_position = _button.global_position
		first_time = false
	
	class_border.size = _button.size

func build_list() -> void:
	tree.clear()

	var root: TreeItem = tree.create_item()
	var item_count: int = 0


	if class_type == CLASS_TYPE.SELF:
		match select_type:
			FILTER_TYPE.ALL:
				for data: Dictionary in api_list:
					if not name_to_search or (data.name as String).contains(name_to_search):
						var item: TreeItem = root.create_child()
						item.set_text(0, data.name)
						item.set_metadata(0, data.data)
					
						if data.has('type'):
							if FILTER_ICONS.has(data.type):
								item.set_icon(0, FILTER_ICONS[data.type])
								item.set_custom_bg_color(0, BG_COLOR[data.type])
						elif data.has('icon_type'):
							if data.icon_type == 'void':
								item.set_icon(0, FILTER_ICONS[FILTER_TYPE.FUNC])
								item.set_custom_bg_color(0, Color(1, 1, 1, .03))
							else:
								item.set_icon(0, HenAssets.get_icon_texture(data.icon_type))

						item_count += 1
			FILTER_TYPE.NATIVE:
				for data: Dictionary in native_list:
					if not name_to_search or (data.name as String).contains(name_to_search):
						var item: TreeItem = root.create_child()
						item.set_text(0, data.name)
						item.set_metadata(0, data.data)
						item.set_icon(0, FILTER_ICONS[select_type])
						item.set_custom_bg_color(0, BG_COLOR[data.type])
					
						item_count += 1
			FILTER_TYPE.FUNC, FILTER_TYPE.SIGNAL, FILTER_TYPE.MACRO:
				for data: Dictionary in api_list:
					if not data.has('type'): continue
					if data.type != select_type: continue

					if not name_to_search or (data.name as String).contains(name_to_search):
						var item: TreeItem = root.create_child()
						item.set_text(0, data.name)
						item.set_metadata(0, data.data)
						item.set_icon(0, FILTER_ICONS[select_type])
						item.set_custom_bg_color(0, BG_COLOR[data.type])
					
						item_count += 1

	if root.get_child_count() > 0:
		var item_size: Vector2 = tree.get_item_area_rect(root.get_child(0)).size
		tree.custom_minimum_size.y = item_size.y * item_count

		var rect: Rect2 = HenGlobal.CAM.get_viewport_rect()
		if tree.custom_minimum_size.y > rect.size.y:
			tree.custom_minimum_size.y = rect.size.y * .4


func _on_select() -> void:
	var data: Dictionary = tree.get_selected().get_metadata(0)

	data.position = HenGlobal.CAM.get_relative_vec2(start_pos)

	var vc_return: HenVirtualCNode.VCNodeReturn = HenVirtualCNode.instantiate(data)

	HenGlobal.history.create_action('Add cNode')
	HenGlobal.history.add_do_method(vc_return.add)
	HenGlobal.history.add_do_reference(vc_return)
	HenGlobal.history.add_undo_method(vc_return.remove)

	# make connection
	if cnode_config.has('from_in_out'):
		vc_return.v_cnode.create_connection(
			0,
			cnode_config.in_out_idx,
			cnode_config.from,
		).add()

	HenGlobal.history.commit_action()
	HenGlobal.GENERAL_POPUP.get_parent().hide_popup()

# func _ready() -> void:
# 	list_container = get_node('%List')

# 	var error: int = start_api(connection_type)

# 	# disabling coming from inputs (for now)
# 	if error != OK or came_from == 'in':
# 		await get_tree().process_frame
# 		HenGlobal.CAM.can_scroll = true
# 		HenGlobal.GENERAL_POPUP.get_parent().hide()


# 	_show_list(native_list if show_native_first else api_list.slice(0, LIST_SIZE), false)

# 	var search_bar = (get_node('%Search') as LineEdit)

# 	search_bar.text_changed.connect(_search)
# 	search_bar.gui_input.connect(_on_search_gui_input)
# 	search_bar.grab_focus()


# func _on_search_gui_input(_event: InputEvent) -> void:
# 	if _event is InputEventKey:
# 		if _event.pressed:
# 			if _event.keycode == KEY_DOWN:
# 				selected_id = wrapi(selected_id + 1, 0, list_container.get_child_count())
# 			elif _event.keycode == KEY_UP:
# 				selected_id = wrapi(selected_id - 1, 0, list_container.get_child_count())
# 			elif _event.keycode == KEY_ENTER:
# 				_select()


# func _select() -> void:
# 	HenGlobal.CAM.can_scroll = true
# 	if list_container.get_child_count() > 0:
# 		var item = list_container.get_child(selected_id)
# 		var item_data = item.get_meta('data')

# 		if item_data.has('data_type'):
# 			match item_data.data_type as Type:
# 				Type.COMMENT:
# 					var comment = preload('res://addons/hengo/scenes/utils/comment.tscn').instantiate()
# 					comment.route_ref = HenRouter.current_route
# 					comment.position = HenGlobal.CAM.get_relative_vec2(start_pos)
# 					HenRouter.comment_reference[HenRouter.current_route.id].append(comment)
# 					HenGlobal.COMMENT_CONTAINER.add_child(comment)
# 					HenGlobal.GENERAL_POPUP.get_parent().hide()
# 					return
				
# 		var data = item_data['data']

# 		# intercepting method creation
# 		# method picker middleware
# 		# TODO: make this apresentable

# 		if data.has('inputs'):
# 			for input in data.inputs:
# 				if input.has('type'):
# 					if input.type == 'Callable':
# 						input.sub_type = '@dropdown'
# 						input.category = 'callable'

# 		if data.name.contains('is_action'):
# 			for input in data.inputs:
# 				if input.name == 'action':
# 					input.sub_type = '@dropdown'
# 					input.category = 'action'

# 		elif data.name == 'connect' or data.name == 'disconnect':
# 			for input in data.inputs:
# 				if input.name == 'signal':
# 					input.sub_type = '@dropdown'
# 					input.category = 'signal'
# 					input.data = data.inputs[0].type


# 		data['position'] = HenGlobal.CAM.get_relative_vec2(start_pos)

# 		var vc_return: HenVirtualCNode.VCNodeReturn = HenVirtualCNode.instantiate(data)

# 		HenGlobal.history.create_action('Add cNode')
# 		HenGlobal.history.add_do_method(vc_return.add)
# 		HenGlobal.history.add_do_reference(vc_return)
# 		HenGlobal.history.add_undo_method(vc_return.remove)

# 		# make connection
# 		if cnode_config.has('from_in_out'):
# 			vc_return.v_cnode.create_connection(
# 				0,
# 				cnode_config.in_out_idx,
# 				cnode_config.from,
# 			).add()

# 		HenGlobal.history.commit_action()
# 		HenGlobal.GENERAL_POPUP.get_parent().hide()


# func _show_list(_list: Array, _slice: bool = true) -> void:
# 	# cleaning list first
# 	for item in list_container.get_children():
# 		item.queue_free()

# 	for dict: Dictionary in _list.slice(0, LIST_SIZE) if _slice else _list:
# 		var item = preload('res://addons/hengo/scenes/method_picker_item.tscn').instantiate()
# 		item.set_meta('data', dict)
# 		item.mouse_entered.connect(_on_item_hover.bind(item))
# 		item.mouse_exited.connect(_on_item_exit.bind(item))
# 		item.gui_input.connect(_on_item_gui_input)
# 		item.get_node('%Name').text = dict.name
# 		item.get_node('%Type').text = dict.type if dict.has('type') else ''

# 		list_container.add_child(item)
	
# 	await RenderingServer.frame_post_draw
# 	HenGlobal.GENERAL_POPUP.size = Vector2.ZERO

# 	if list_container.get_child_count() > 0:
# 		_item_hover(list_container.get_child(0))


# func _on_item_gui_input(_event: InputEvent) -> void:
# 	if _event is InputEventMouseButton:
# 		if _event.pressed:
# 			if _event.button_index == MOUSE_BUTTON_LEFT:
# 				_select()


# func _on_item_hover(_item) -> void:
# 	_item_hover(_item)
# 	selected_id = _item.get_index()


# func _on_item_exit(_item) -> void:
# 	_item_exit(_item)
# 	selected_id = _item.get_index()


# func _item_hover(_item) -> void:
# 	_item.get('theme_override_styles/panel').set('bg_color', Color.DARK_CYAN)


# func _item_exit(_item) -> void:
# 	_item.get('theme_override_styles/panel').set('bg_color', Color(0, 0, 0, .3))


# func _search(_text: String) -> void:
# 	if _text.is_empty():
# 		_show_list(native_list, false)
# 		return

# 	var arr: Array = []

# 	for dict: Dictionary in api_list:
# 		if (dict.name as String).replacen(' -> ', '').to_snake_case().replacen('_', '').contains(_text.to_snake_case().replacen('_', '')):
# 			arr.append(dict)

# 	_show_list(arr)


func _get_sub_type(_type: Variant.Type, _usage: int) -> HenVirtualCNode.SubType:
	match _type:
		TYPE_NIL:
			if _usage == 131078: # is the code for nil returning variant, so... a func
				return HenVirtualCNode.SubType.FUNC
			else:
				return HenVirtualCNode.SubType.VOID
		_:
			return HenVirtualCNode.SubType.FUNC


func _get_typeny_arg(_arg: Dictionary) -> StringName:
	match _arg.type:
		TYPE_OBJECT:
			return _arg.class_name
		TYPE_NIL:
			if _arg.usage == 131078:
				return 'Variant'

	return type_string(_arg.type)


func _get_class_obj(_dict: Dictionary, _class_name: StringName) -> Dictionary:
	var _obj_type: StringName = _get_typeny_arg(_dict.return )


	var obj: Dictionary = {
		name = _dict.name,
		icon_type = _obj_type if _obj_type != StringName('Nil') else StringName('void'),
		data = {
			name = _dict.name,
			sub_type = _get_sub_type(_dict.return.type, _dict.return.usage) if _dict.flags != METHOD_FLAG_VIRTUAL else HenVirtualCNode.SubType.OVERRIDE_VIRTUAL,
			route = HenRouter.current_route
		},
	}

	if _dict.flags == METHOD_FLAG_VIRTUAL:
		obj.data.outputs = (_dict.args as Array).map(
			func(arg) -> Dictionary:
				match arg.usage:
					65542:
						return {
							name = arg.name,
							sub_type = '@dropdown',
							category = 'enum_list',
							data = arg.class_name.split('.'),
						}
					_:
						return {
						name = arg.name,
						type = _get_typeny_arg(arg)
					}
				)
	else:
		obj.data.inputs = [ {
			name = _class_name,
			type = _class_name,
			is_ref = true
		}] + (_dict.args as Array).map(
			func(arg) -> Dictionary:
				match arg.usage:
					65542:
						return {
							name = arg.name,
							sub_type = '@dropdown',
							category = 'enum_list',
							data = arg.class_name.split('.'),
						}
					_:
						return {
						name = arg.name,
						type = _get_typeny_arg(arg)
					}
				)


	# it's a void or return a variant
	if _dict.return.type != TYPE_NIL or (_dict.return.type == TYPE_NIL and _dict.return.usage == 131078):
		obj['data']['outputs'] = [ {
			name = _dict.return.name,
			type = _get_typeny_arg(_dict.return )
		}]

	return obj


# func start_api(_class_name: StringName = 'all') -> int:
# 	api_list = []

# 	# getting other scripts data
# 	for script_data: Dictionary in HenGlobal.SCRIPTS_INFO.values():
# 		if script_data.has('state_event_list'):
# 			api_list.append({
# 				name = script_data.name + ' Event Trigger',
# 				data = {
# 					name = script_data.name + ' Event Trigger',
# 					name_to_code = 'trigger_event',
# 					sub_type = HenVirtualCNode.SubType.VOID,
# 					inputs = [
# 						{
# 							name = script_data.type,
# 							type = 'Variant',
# 							is_ref = true
# 						},
# 						{
# 							name = 'event',
# 							type = 'StringName',
# 							sub_type = '@dropdown',
# 							category = 'state_event_list',
# 							data = script_data.name
# 						}
# 					],
# 					route = HenRouter.current_route
# 				}
# 			})


# 	match _class_name:
# 		'all':
# 			for cl_name: StringName in ClassDB.get_class_list():
# 				for dict in ClassDB.class_get_method_list(_class_name):
# 					api_list.append(_get_class_obj(dict, cl_name, _class_name))
# 		_:
# 			if HenEnums.VARIANT_TYPES.has(_class_name):
# 				if HenEnums.NATIVE_API_LIST.has(_class_name):
# 					api_list = HenEnums.NATIVE_API_LIST[_class_name].map(func(obj: Dictionary) -> Dictionary:
# 						var dt: Dictionary = obj

# 						dt.data.route = HenRouter.current_route
# 						dt.type = _class_name

# 						return dt
# 						)
# 				else:
# 					api_list = []
				
# 				if HenEnums.NATIVE_PROPS_LIST.has(_class_name):
# 					for prop in HenEnums.NATIVE_PROPS_LIST.get(_class_name):
# 							api_list.append({
# 								name = 'Get Prop -> ' + prop.name,
# 								data = {
# 									name = prop.name,
# 									fantasy_name = 'Get Prop -> ' + prop.name,
# 									sub_type = HenVirtualCNode.SubType.GET_PROP,
# 									inputs = [
# 										{
# 											name = _class_name,
# 											type = _class_name,
# 											is_ref = true
# 										}
# 									],
# 									outputs = [
# 										{
# 											name = prop.name,
# 											type = prop.type,
# 										}
# 									],
# 									route = HenRouter.current_route
# 								}
# 							})

# 							api_list.append({
# 								name = 'Set Prop -> ' + prop.name,
# 								data = {
# 									name = prop.name,
# 									fantasy_name = 'Set Prop -> ' + prop.name,
# 									sub_type = HenVirtualCNode.SubType.SET_PROP,
# 									inputs = [
# 										{
# 											name = _class_name,
# 											type = _class_name,
# 											is_ref = true
# 										},
# 										{
# 											name = prop.name,
# 											type = prop.type,
# 										}
# 									],
# 									route = HenRouter.current_route
# 								}
# 							})


# 			else:
# 				if came_from == 'in':
# 					api_list = []

# 				else:
# 					for dict: Dictionary in ClassDB.class_get_method_list(_class_name):
# 						api_list.append(_get_class_obj(dict, _class_name, _class_name))
					

# 					# singleton
# 					for singleton_config in HenEnums.SINGLETON_API_LIST:
# 						var dt: Dictionary = singleton_config
# 						dt.data.route = HenRouter.current_route
# 						api_list.append(dt)
					
# 					# testi
# 					api_list.append({
# 						name = 'Set Test',
# 						data = {
# 							name = 'Set',
# 							sub_type = HenVirtualCNode.SubType.SET_PROP,
# 							inputs = [
# 								{
# 									name = _class_name,
# 									type = _class_name,
# 									is_ref = true
# 								},
# 								{
# 									name = '',
# 									type = 'Variant',
# 									sub_type = '@dropdown',
# 									category = 'set_prop',
# 									data = _class_name,
# 									is_static = true
# 								},
# 								{
# 									name = 'value',
# 									type = 'Variant',
# 								},
# 							],
# 							route = HenRouter.current_route
# 						}
# 					})
# 					api_list.append({
# 						name = 'Get Test',
# 						data = {
# 							name = 'Get',
# 							sub_type = HenVirtualCNode.SubType.GET_PROP,
# 							inputs = [
# 								{
# 									name = _class_name,
# 									type = _class_name,
# 									is_ref = true
# 								}
# 							],
# 							outputs = [
# 								{
# 									name = '',
# 									type = 'Variant',
# 									sub_type = '@dropdown',
# 									category = 'get_prop',
# 									data = _class_name
# 								}
# 							],
# 							route = HenRouter.current_route
# 						}
# 					})


# 					for prop in ClassDB.class_get_property_list(_class_name):
# 						var set_data: Dictionary = {
# 							name = 'Set Prop -> ' + prop.name,
# 							data = {
# 								name = prop.name,
# 								fantasy_name = 'Set Prop -> ' + prop.name,
# 								sub_type = HenVirtualCNode.SubType.SET_PROP,
# 								inputs = [
# 									{
# 										name = _class_name,
# 										type = _class_name,
# 										is_ref = true
# 									},
# 									{
# 										name = prop.name,
# 										type = type_string(prop.type),
# 										is_ref = true
# 									}
# 								],
# 								route = HenRouter.current_route
# 							}
# 						}

# 						var get_data: Dictionary = {
# 							name = 'Get Prop -> ' + prop.name,
# 							data = {
# 								name = prop.name,
# 								fantasy_name = 'Get Prop -> ' + prop.name,
# 								sub_type = HenVirtualCNode.SubType.GET_PROP,
# 								inputs = [
# 									{
# 										name = _class_name,
# 										type = _class_name,
# 										is_ref = true
# 									}
# 								],
# 								outputs = [
# 									{
# 										name = prop.name,
# 										type = type_string(prop.type),
# 									}
# 								],
# 								route = HenRouter.current_route
# 							}
# 						}

# 						if HenEnums.NATIVE_PROPS_LIST.has(type_string(prop.type)):
# 							set_data.data.inputs += HenEnums.NATIVE_PROPS_LIST.get(type_string(prop.type))
# 							get_data.data.outputs += HenEnums.NATIVE_PROPS_LIST.get(type_string(prop.type))

# 						api_list.append(set_data)
# 						api_list.append(get_data)

					
# 					# functions
# 					for func_data: HenSideBar.FuncData in HenGlobal.SIDE_BAR_LIST.func_list:
# 						var dt: Dictionary = {
# 							name = 'Func -> ' + func_data.name,
# 							data = func_data.get_cnode_data()
# 						}

# 						api_list.append(dt)


# 					# signals
# 					for signal_data: HenSideBar.SignalData in HenGlobal.SIDE_BAR_LIST.signal_list:
# 						var connect_dt: Dictionary = {
# 							name = 'Signal -> ' + signal_data.name,
# 							data = signal_data.get_connect_cnode_data()
# 						}

# 						var disconnect_dt: Dictionary = {
# 							name = 'Dis Signal -> ' + signal_data.name,
# 							data = signal_data.get_diconnect_cnode_data()
# 						}

# 						api_list.append(connect_dt)
# 						api_list.append(disconnect_dt)
					
# 					# macro
# 					for macro_data: HenSideBar.MacroData in HenGlobal.SIDE_BAR_LIST.macro_list:
# 						var dt: Dictionary = {
# 							name = 'Macro -> ' + macro_data.name,
# 							data = macro_data.get_cnode_data()
# 						}

# 						api_list.append(dt)

# 	return OK


func start(_type: StringName, _pos: Vector2, _show_native: bool = true, _came_from: String = 'out', _cnode_config: Dictionary = {}) -> void:
	connection_type = _type
	start_pos = _pos
	show_native_first = _show_native
	came_from = _came_from
	cnode_config = _cnode_config